## Why

El `messageOrchestrator` hoy gatea los envíos en un `dailyConversationLimit` hardcodeado a 250 que corresponde al tier inicial de Meta. Meta sube el tier del WABA (a 1.000, 10.000, etc.) sin darnos una señal clara ni confiable, y el número no se expone en la API de Twilio salvo reactivamente vía Monitor Alerts. Resultado: estamos auto-limitándonos por debajo de la capacidad real contratada con Twilio/Meta.

Además, el sistema no considera el **límite de throughput de Twilio/Meta de 80 mensajes por segundo** sobre la cuenta. Con el cap actual de 250/día y `maxInstances: 10` del sender nunca se llega, pero al destapar el caudal la arquitectura debe ser defensiva frente a ese piso.

La estrategia: **ignorar el cap a priori y reaccionar al error real de Meta**. Cuando Twilio responde con el código de tier agotado (`63038` / `63032` / 429 con `MetaRateLimit`), el mensaje no persiste el fallo — ni en `communications` ni en `message_queue` — para que el siguiente ciclo del orquestador reintente. Todo envío exitoso sigue la ruta normal.

## What Changes

- **Eliminar el gating por `dailyConversationLimit`** en el orquestador. El contador se mantiene como métrica observable pero no gatea despachos.
- **Eliminar el gating por `urgentReservePercentage`** — sin cap global la reserva es innecesaria. La prioridad de urgentes pasa a ser estricta por orden de cola.
- **Ordenar la cola priorizando urgentes**: query `orderBy isUrgent DESC, priority ASC, scheduledFor ASC, createdAt ASC`. Los urgentes consumen capacidad antes que los normales en el mismo ciclo.
- **Detectar tier exhaustion de Meta** en `sendWhatsAppReminder` via códigos `63038` y `63032` (y 429 con metadata de Meta rate limit).
- **Rollback limpio ante tier exhaustion**: el sender borra el documento de `communications` (en provider y mirror del paciente), revierte el queue item a `status: "queued"` con `processedAt` limpio y sin incrementar `attempts`. El mensaje vuelve a la cola natural; no se marca `failed`.
- **Circuit breaker de 30 min**: al detectar el error, el sender escribe `metadata/messaging.pausedUntil = now + 30 min`. El orquestador lee ese campo y saltea el paso de despacho mientras esté vigente, evitando seguir consumiendo API calls a Twilio con mensajes condenados al mismo error.
- **Pacing defensivo de 80 MPS** en el orquestador: cap configurable `maxDispatchRatePerSecond` (default `40`, mitad del límite real) aplicado via pequeño delay entre creaciones de `communications` dentro de un mismo run. Protege ante futuros bumps de `maxInstances` del sender.
- **Aumentar batch size** del orquestador de 50 a 500 por run, para aprovechar tier exhaustion cuando Meta sube el cupo y que la cola no se represe.
- Mantener la ventana horaria (`sendWindowStart` / `sendWindowEnd`) sin cambios.

## Capabilities

### New Capabilities

- `whatsapp-meta-tier-detection`: Detección del error de tier agotado de Meta vía códigos de error de Twilio, rollback limpio del mensaje y circuit breaker a nivel sistema para pausar envíos temporalmente.
- `whatsapp-dispatch-pacing`: Pacing defensivo del orquestador a una tasa máxima de creaciones de `communications` por segundo para respetar el límite de 80 MPS de Meta/Twilio.

### Modified Capabilities

- `message-overflow-escalation`: El orquestador ya no gatea el despacho por `dailyConversationLimit` ni por `urgentReservePercentage`. El ordenamiento de la cola pasa a priorizar estrictamente `isUrgent DESC` antes que `scheduledFor ASC`.

## Impact

- **`firebase/functions/src/cron/messageOrchestrator.ts`**:
  - Eliminar cálculos y checks de `totalAvailable` / `normalAvailable` / `urgentReserved`.
  - Cambiar ordering de la query principal: `isUrgent DESC, priority ASC, scheduledFor ASC, createdAt ASC`.
  - Aumentar `limit(50)` a `limit(500)`.
  - Leer `metadata/messaging.pausedUntil`; si `now < pausedUntil`, saltear el paso de despacho y loguear.
  - Agregar pacer: respetar `maxDispatchRatePerSecond` con delay entre despachos (`setTimeout`).
- **`firebase/functions/src/workers/sendWhatsAppReminder.ts`**:
  - En el `catch`, detectar Meta tier exhaustion: `err.code === 63038 || err.code === 63032`, o `err.status === 429` con body Meta rate limit.
  - Rama especial: borrar `communications` doc (y mirror del paciente), revertir queue item a `queued` (limpiar `processedAt`, no tocar `attempts`), setear `metadata/messaging.pausedUntil`. No loguear PII.
- **`firebase/functions/src/utils/messaging_utils.ts`**:
  - Nuevo campo `MessagingConfig.maxDispatchRatePerSecond` (default `40`).
  - Nuevo campo `MessagingConfig.tierExhaustedPauseMs` (default `30 * 60 * 1000`).
  - `dailyConversationLimit` y `urgentReservePercentage` quedan deprecados — permanecen en la interfaz para no romper docs existentes pero ya no se consumen.
- **`metadata/messaging`**: nuevo campo opcional `pausedUntil` (Timestamp), escrito por el sender y leído por el orquestador. Sin migración necesaria — ausencia significa "no pausado".
- **`firebase/functions/src/__tests__/messageOrchestrator.test.ts`**: actualizar todos los tests que asumen el cap de 250 y la reserva urgente; agregar tests de ordering estricto por urgencia, pacing y circuit breaker.
- **`firebase/functions/src/__tests__/sendWhatsAppReminder.test.ts`** (o equivalente): agregar tests del rollback ante 63038 / 63032.
- **Sin cambios en schema de Firestore** para `message_queue` ni `communications`. Sin cambios en clientes Flutter.
