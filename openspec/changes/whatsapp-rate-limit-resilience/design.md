## Context

El pipeline de envío de WhatsApp tiene tres actores:

1. **`messageOrchestrator`** (cron cada 10 min, `maxInstances: 1`): lee `message_queue` con `status == "queued"` y `scheduledFor <= now`, crea documentos en `providers/{id}/communications/{commId}` para despachar.
2. **`sendWhatsAppReminder`** (Firestore trigger onCreate en `communications`, `maxInstances: 10`): llama a Twilio Content API, con reintentos en errores transitorios (429/5xx/network).
3. **Twilio** envía a Meta. Meta aplica dos límites independientes:
   - **Tier de conversaciones por 24h** (tier marketing): 250 → 1.000 → 10.000 → 100.000 → ∞. Meta lo sube automáticamente cuando la calidad del sender es alta, pero no expone el tier vigente en la API de Twilio salvo reactivamente via **Monitor Alerts** (`63032`, `63038`).
   - **Throughput absoluto**: 80 mensajes por segundo sobre la cuenta Twilio. Independiente del tier.

El sistema actual conserva un `dailyConversationLimit: 250` como `metadata/messaging` y lo usa para gatear despachos. Problemas:

- **Auto-sabotaje**: si Meta ya nos subió al tier 1.000 hace 3 meses, igual seguimos capados a 250.
- **Sin señal de cuándo actualizar**: la única señal confiable es el error en vuelo (cuando ya estamos saturando).
- **Reserva para urgentes ineficiente**: con cap artificial bajo, la reserva del 15% (37 mensajes) desperdicia cupos normales que podrían aprovecharse.

La intención del rediseño: **dejar que Meta nos diga cuál es el límite** via el error de tier exhaustion, y usar ese error como señal para pausar brevemente el pipeline hasta el próximo ciclo.

## Goals / Non-Goals

**Goals:**
- Aprovechar la capacidad real del tier vigente sin requerir intervención manual cuando Meta sube el cupo.
- Conservar idempotencia: un mensaje que falla por tier exhaustion vuelve a `queued` sin perder su contexto ni incrementar `attempts`.
- Evitar hammering de Twilio cuando estamos saturados: circuit breaker con pausa corta (30 min por defecto) y próximo ciclo natural.
- Respetar defensivamente el límite de 80 MPS aunque la arquitectura actual esté lejos de alcanzarlo, para que futuros bumps de concurrencia no lo violen.
- Priorizar estrictamente urgentes sobre normales dentro del mismo ciclo del orquestador.

**Non-Goals:**
- No sondeamos Twilio Monitor Alerts en tiempo real — es reactivo por diseño (capturamos el error en vuelo y reaccionamos).
- No reintentamos con backoff dentro del mismo sender. El reintento natural es el próximo ciclo del orquestador (10 min).
- No cambiamos el schema de `message_queue` ni `communications`.
- No tocamos clientes Flutter.
- No tocamos la ventana horaria de envíos (`sendWindowStart` / `sendWindowEnd`).

## Decisions

### Decisión 1: Eliminar el gate por `dailyConversationLimit`

**Alternativa rechazada:** Subir el cap a un número alto (ej: 100.000). **Rationale:** sigue siendo un número mágico que hay que mantener sincronizado con el tier real de Meta. Además no protege contra el límite real de 80 MPS de throughput.

**Alternativa rechazada:** Sondear Twilio Monitor Alerts periódicamente y ajustar `dailyConversationLimit` dinámicamente. **Rationale:** es complejo, las Alerts tienen latencia y el tier no se expone como número limpio — hay que parsearlo de mensajes de error. La señal reactiva en vuelo (ver Decisión 2) es más simple y funcionalmente equivalente.

**Decisión:** eliminar el check `if (totalAvailable <= 0)` y toda la matemática asociada. El orquestador despacha todo lo que tiene `scheduledFor <= now` hasta el batch limit o el rate limit de pacing.

El campo `dailyConversationLimit` en `metadata/messaging` se conserva como deprecated (no se lee) para evitar roturas en docs existentes y en el admin UI que lo muestra. Puede eliminarse en una limpieza futura.

### Decisión 2: Detección de tier exhaustion via error de Twilio

**Códigos objetivo:** `63038` (Account has reached its daily message limit) y `63032` (generic tier exhaustion — Meta rate limit). Documentados en Twilio WhatsApp error codes. Ambos son captura via `err.code` en el catch del sender.

**Alternativa rechazada:** considerar también `429` genérico como tier exhaustion. **Rationale:** `429` también aplica a otras condiciones de rate-limit (p. ej. el propio 80 MPS de Twilio), y mezclarlos complica el retry flow. Para `429` que no sea Meta-specific, seguimos con la política de retry transitorio existente (1s, 4s). Si `429` contiene metadata específica de Meta (detectable via `err.moreInfo` o body), podemos tratarlo como tier exhaustion en una iteración futura.

**Alternativa rechazada:** consultar Twilio Monitor Alerts API después de cada fallo para confirmar. **Rationale:** latencia agregada y costo en API calls; el código del error ya es suficiente signal.

**Decisión:** catch bloque especial antes del catch genérico:
```typescript
if (err.code === 63038 || err.code === 63032) {
  await rollbackTierExhausted(snap, queueItemId, providerId, patientId, commId);
  return null;
}
```

### Decisión 3: Rollback — borrar `communications` y revertir queue item

**Alternativa rechazada:** marcar `communications` como `aborted` con `reason: "tier_exhausted"` y reencolarlo separadamente. **Rationale:** doble bookkeeping. El comm doc es una transcripción del envío, no un registro de intento de envío; si el intento falla al nivel de tier (no a nivel paciente), la transcripción no tiene sentido.

**Decisión de rollback:**
1. `snap.ref.delete()` — borra el doc en `providers/{id}/communications/{commId}`.
2. Delete mirror en `providers/{id}/patients/{patientId}/communications/{commId}`.
3. Update queue item: `status: "queued"`, `processedAt: FieldValue.delete()`. No incrementar `attempts`.
4. Set `metadata/messaging.pausedUntil = now + pauseDurationMs` (default 30 min).

**Por qué no incrementar `attempts`:** el contador existe para detectar mensajes que fallan repetidamente por causa propia (paciente, template, etc.). Tier exhaustion no es culpa del mensaje y no debe contar. Si lo incrementamos, mensajes viejos pueden quedar marcados como "ruidosos" injustamente.

**Idempotencia:** la operación de rollback es safe incluso si se ejecuta dos veces (ej: el sender falla y el trigger se reintenta): el `delete` es no-op si ya no existe, y el update a `"queued"` es idempotente.

### Decisión 4: Circuit breaker via `pausedUntil` en `metadata/messaging`

**Problema:** si el sender detecta tier exhaustion y revierte a `queued`, el siguiente ciclo del orquestador (10 min después) despachará los mismos 500 mensajes y quemará API calls a Twilio con el mismo resultado durante esa hora en que Meta no se despierte.

**Solución:** escribir un timestamp de pausa en `metadata/messaging.pausedUntil`. El orquestador lo lee antes del paso de despacho:

```typescript
const paused = config.pausedUntil && config.pausedUntil.toMillis() > Date.now();
if (paused) {
  functions.logger.info("dispatch paused due to tier exhaustion", { pausedUntil });
  return null;
}
```

**Duración de la pausa (30 min default):** suficiente para que Meta abra capacidad. El tier se resetea por hora móvil de 24h, pero en la práctica el throttle afloja mucho antes. 30 min es un compromiso entre "no perder ventana de envío" y "no seguir martillando". Configurable via `metadata/messaging.tierExhaustedPauseMs`.

**Quién limpia `pausedUntil`:** nadie — el campo caduca por timestamp comparison. Se sobrescribe naturalmente en el próximo tier exhaustion. Para limpieza operacional el admin puede borrarlo manualmente.

**Race condition entre múltiples senders concurrentes:** con `maxInstances: 10` del sender, varios pueden fallar al mismo tiempo y todos intentar escribir `pausedUntil`. Usamos `set` con merge: el último escritor gana pero todos escriben aproximadamente el mismo valor (now + 30 min). Diferencia de segundos es irrelevante.

### Decisión 5: Ordering estricto por urgencia

**Problema:** sin cap global, la reserva por porcentaje de urgentes no tiene sentido. Pero necesitamos garantizar que en un ciclo con 500 mensajes listos — 30 urgentes y 470 normales — los urgentes se despachan primero (son más sensibles al tiempo).

**Solución:** cambiar `orderBy` de la query principal:

```typescript
.orderBy("isUrgent", "desc")   // urgentes primero
.orderBy("priority", "asc")    // dentro de iso-urgencia, prioridad más baja primero
.orderBy("scheduledFor", "asc")
.orderBy("createdAt", "asc")
```

**Costo en Firestore:** esta ordering requiere un índice compuesto nuevo sobre `(status, isUrgent DESC, priority ASC, scheduledFor ASC, createdAt ASC)`. Agregar a `firestore.indexes.json`.

**Alternativa rechazada:** hacer dos queries — una con `isUrgent == true` y otra con `isUrgent == false` — y dispatcharlas secuencialmente. **Rationale:** dos roundtrips, misma cantidad de docs a materializar, no gana nada frente a una sola query ordenada.

### Decisión 6: Pacing en el orquestador (80 MPS defensivo)

**Problema:** con batch de 500 y maxInstances 10 del sender, si los 500 docs de communications se crean en 200 ms, los 10 instances del sender podrían disparar hasta 10 llamadas concurrentes a Twilio. Actualmente esto da ~10–20 MPS. Pero si mañana subimos `sendWhatsAppReminder` a `maxInstances: 50`, podemos superar los 80 MPS.

**Solución:** pacer en el orquestador — cap configurable a creaciones de `communications` por segundo. Implementación: `setTimeout` entre despachos.

```typescript
const minDelayMs = 1000 / config.maxDispatchRatePerSecond; // ej: 25ms para 40 MPS
for (const doc of snap.docs) {
  await dispatch(doc);
  await sleep(minDelayMs);
}
```

**Default `maxDispatchRatePerSecond: 40`:** mitad del límite de 80 MPS, margen amplio para la concurrencia del sender trigger y para burst natural de Firestore (onCreate no dispara exactamente síncrono).

**Impacto en batch grande:** 500 mensajes a 40 MPS = 12.5 segundos de dispatch sin contar el tiempo de Twilio. Cabe holgadamente en el run de la función (timeout default 9 min, ver más abajo).

**Timeout de la función:** el orquestador tiene timeout default de 60s en Firebase Functions v1. 500 mensajes a 40 MPS con latencia adicional excede 60s. **Cambiar `timeoutSeconds: 540`** (9 min, el máximo).

**Alternativa rechazada:** pacing del lado del sender usando un token bucket en Firestore (`metadata/messaging_rate_bucket`). **Rationale:** lecturas/escrituras extra por cada envío. El orquestador como único gate es suficiente dado que es la única fuente de creaciones.

### Decisión 7: Batch size 500 + limit(500)

**Alternativa rechazada:** `limit(unbounded)`. **Rationale:** explotaría el límite de memoria de la función y/o el timeout.

**Decisión:** `limit(500)`. Con 500 a 40 MPS = 12.5s. Si hay > 500 mensajes queued (ej: post-pausa de 30 min con carga acumulada), los restantes se procesan en el próximo ciclo (10 min). Tolerable.

Con `maxInstances: 1` del orquestador, no hay riesgo de dos runs superpuestos robándose mensajes.

### Decisión 8: Deprecar `dailyConversationLimit` y `urgentReservePercentage`

Ambos quedan en la interfaz `MessagingConfig` por compatibilidad con docs existentes y con el admin panel (si lo muestra). El orquestador los ignora. Una migración cleanup posterior puede removerlos del schema y del panel admin.

### Decisión 9: Counter observable pero no gatea

El contador `metadata/messaging_counters/current/current` seguía incrementándose en `incrementCounter`. Esto se mantiene para observabilidad — permite graficar cuántas conversaciones enviamos por día. Pero el orquestador no lo lee para decidir despachos.

**Alternativa considerada:** remover el counter completamente. **Rationale para mantenerlo:** es información útil de producto y el costo es marginal (una escritura por despacho con `FieldValue.increment`).

## Risks / Trade-offs

| Riesgo | Mitigación |
|--------|-----------|
| Si Meta nos baja de tier (por quality issues), el primer ciclo post-bajada va a quemar ~30 min de API calls a Twilio antes de que el circuit breaker se enganche y el próximo ciclo entre. | El circuit breaker se activa con el primer error del ciclo, no al final. El sender escribe `pausedUntil` apenas detecta el primer `63038`. Los siguientes mensajes del mismo ciclo igualmente fallarán — el desperdicio es los primeros N mensajes del ciclo hasta que el orquestador lea `pausedUntil` en el siguiente run. Aceptable. |
| Si el sender trigger falla antes de escribir `pausedUntil` (ej: crash del runtime), no hay circuit breaker y el siguiente orquestador insiste. | Firebase Functions tiene retry automático en triggers Firestore. Si el sender fue llamado pero nunca completó, el trigger retry lo reejecuta. Eventualmente escribe `pausedUntil`. |
| El pacing agrega latencia al dispatch (12.5s para 500 mensajes a 40 MPS). | Irrelevante en el contexto — la ventana de envío es horaria, no por minuto. Un delay de 12s no afecta la experiencia del paciente. |
| El nuevo índice compuesto `(status, isUrgent DESC, priority ASC, scheduledFor ASC, createdAt ASC)` puede tardar en construirse en producción si `message_queue` tiene muchos docs. | Deploy del índice ANTES del cambio de código del orquestador. Firebase permite queries por el índice viejo hasta que el nuevo termine de construirse. Si el query nuevo falla por índice ausente durante el build, Firestore retorna error claro — el orquestador loguea y skipea el ciclo. |
| Tests existentes asumen el cap de 250 y la reserva de urgentes — van a fallar en CI tras el cambio. | Actualizar la suite en la misma PR. Ver tasks.md sección 7. |

## Migration Plan

1. **Deploy del índice compuesto** en `firestore.indexes.json` (`firebase deploy --only firestore:indexes`). Esperar a que el índice quede `ENABLED` en la consola de Firebase (puede tomar minutos).
2. **Deploy de `messaging_utils.ts`**: agrega los campos nuevos de config con defaults. Ningún cambio observable — la config `metadata/messaging` sigue funcionando igual.
3. **Deploy combinado de `messageOrchestrator.ts` y `sendWhatsAppReminder.ts`**: el orden matters — si el sender queda viejo (marca failed en tier exhaustion) mientras el orquestador ya no gatea por 250, podemos perder mensajes en errores. Deploy atómico via `firebase deploy --only functions:messageOrchestrator,functions:sendWhatsAppReminder`.
4. **Validación post-deploy**:
   - Ver logs del primer ciclo del orquestador: confirmar que el batch es de 500 y que `dailyConversationLimit` no aparece en los logs de gate.
   - Forzar un escenario de tier exhaustion en staging (con un Twilio Test Account que lo simula) y verificar rollback + `pausedUntil`.
5. **Rollback**: re-deploy del código anterior. Los docs en `message_queue` y `communications` no cambian estructuralmente. El campo `pausedUntil` en `metadata/messaging` queda como basura inofensiva; el código viejo lo ignora. El índice compuesto nuevo puede quedar — no molesta.

## Open Questions

- ¿Usamos `metadata/messaging.pausedUntil` o un doc separado `metadata/messaging_circuit_breaker`? **Decisión provisional:** mismo doc para simplicidad. Si crece la cantidad de flags operacionales en el futuro, extraer.
- ¿Exponemos `pausedUntil` al admin panel como indicador visible ("Meta nos tiró el freno — próximo intento en X min")? **No bloqueante para esta PR; se puede agregar en una iteración de UI posterior.**
- ¿Queremos un backoff exponencial del pause (30 min → 60 min → 2h si hay tier exhaustions consecutivas)? **No en esta iteración.** Observar comportamiento real en producción antes de complicar.
- ¿Qué hacer con mensajes que expiran durante una pausa larga? El orquestador hoy los marca `expired` antes del dispatch. Si estamos pausados, igualmente van a expirar en la cola sin dispatcharse. **Comportamiento aceptado** — un paciente no va a recibir un recordatorio 2 días tarde; preferible que no le llegue.
