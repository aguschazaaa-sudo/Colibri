## 1. Schema & configuración

- [x] 1.1 Agregar nuevo índice compuesto en `firebase/firestore.indexes.json`: colección `message_queue`, campos `status ASC, isUrgent DESC, priority ASC, scheduledFor ASC, createdAt ASC`
- [x] 1.2 Extender interface `MessagingConfig` en `messaging_utils.ts` con:
  - `maxDispatchRatePerSecond?: number` (default `40`)
  - `tierExhaustedPauseMs?: number` (default `30 * 60 * 1000`)
  - `pausedUntil?: FirebaseFirestore.Timestamp` (opcional, escrito por sender)
- [x] 1.3 Actualizar `getMessagingConfig()` para leer los nuevos campos con sus defaults
- [x] 1.4 Agregar JSDoc a los nuevos campos (dartdoc-equivalente en TS) explicando su propósito y valores por defecto
- [x] 1.5 Marcar `dailyConversationLimit` y `urgentReservePercentage` como `@deprecated` en la interface (se mantienen por compat pero ya no se consumen)

## 2. Orquestador — eliminar gate por cap

- [x] 2.1 En `messageOrchestrator.ts` eliminar el bloque de cálculo de `totalAvailable`, `urgentReserved`, `normalAvailable` y el early-return `"daily limit reached"`
- [x] 2.2 Eliminar los decrementos `totalAvailable--` / `normalAvailable--` y los checks por-mensaje en el loop de dispatch
- [x] 2.3 Mantener la llamada a `incrementCounter(msg.isUrgent)` (counter observable sigue vivo)
- [x] 2.4 Mantener el check de `expiresAt` antes del dispatch

## 3. Orquestador — circuit breaker

- [x] 3.1 Al inicio del handler (después del check de ventana horaria), leer `config.pausedUntil`
- [x] 3.2 Si `config.pausedUntil && config.pausedUntil.toMillis() > Date.now()` → loguear `"dispatch paused due to tier exhaustion"` con el timestamp y `return null`
- [x] 3.3 Mantener el paso de `urgency elevation pass` (corre antes del gate de pausa — elevar urgencia no cuesta API calls)

## 4. Orquestador — ordering y batch size

- [x] 4.1 Cambiar el `orderBy` de la query principal a: `orderBy("isUrgent", "desc") → orderBy("priority", "asc") → orderBy("scheduledFor", "asc") → orderBy("createdAt", "asc")`
- [x] 4.2 Cambiar `.limit(50)` a `.limit(500)`
- [x] 4.3 Agregar `.runWith({ maxInstances: 1, timeoutSeconds: 540 })` (preservando `maxInstances: 1`)

## 5. Orquestador — pacing 80 MPS

- [x] 5.1 Calcular `minDelayMs = Math.ceil(1000 / config.maxDispatchRatePerSecond)` al inicio del handler
- [x] 5.2 Dentro del loop de dispatch, después de cada `incrementCounter` agregar `await new Promise(r => setTimeout(r, minDelayMs))`
- [x] 5.3 Si `maxDispatchRatePerSecond <= 0` o no es finito, skipear el delay (fallback seguro)

## 6. Sender — detección de tier exhaustion y rollback

- [x] 6.1 En `sendWhatsAppReminder.ts` agregar helper privado `isMetaTierExhaustion(err)` que retorna `true` cuando `err.code === 63038 || err.code === 63032`
- [x] 6.2 En el `catch` principal, antes del bloque genérico de `failed`, agregar branch:
  ```
  if (isMetaTierExhaustion(error)) {
    await rollbackTierExhausted({...});
    return null;
  }
  ```
- [x] 6.3 Implementar `rollbackTierExhausted`:
  - `snap.ref.delete()` — borra comm doc en `providers/{providerId}/communications/{commId}`
  - Borrar mirror en `providers/{providerId}/patients/{patientId}/communications/{commId}` si existe
  - Update `message_queue/{queueItemId}`: `status: "queued"`, `processedAt: FieldValue.delete()`. NO incrementar `attempts`
  - Escribir `metadata/messaging`: `pausedUntil = Timestamp.fromMillis(Date.now() + tierExhaustedPauseMs)` via `set({merge: true})`
  - Loguear `"[sendWhatsAppReminder] tier exhausted, rolled back"` con `commId, queueItemId` — sin PII
- [x] 6.4 Leer `tierExhaustedPauseMs` del config (usar `getMessagingConfig()` o valor default si no está)
- [x] 6.5 Asegurar que el `rollbackTierExhausted` no falla si el queue item ya no existe (defensive — hacer el update dentro de try/catch y loguear warn si no encuentra el doc)

## 7. Tests — orquestador

- [x] 7.1 Eliminar tests que validan el gate por `dailyConversationLimit` (el comportamiento ya no existe)
- [x] 7.2 Test: orquestador despacha 500 mensajes en un solo ciclo sin capar por 250
- [x] 7.3 Test: urgentes se dispatchan antes que normales dentro del mismo ciclo (10 urgentes + 10 normales mezclados → los 10 urgentes se procesan primero)
- [x] 7.4 Test: con `pausedUntil > now`, el orquestador no despacha pero sí corre la urgency elevation pass
- [x] 7.5 Test: con `pausedUntil < now` (expirado), el orquestador despacha normalmente
- [x] 7.6 Test: con `pausedUntil` ausente, el orquestador despacha normalmente
- [x] 7.7 Test: pacing — con `maxDispatchRatePerSecond: 10` y 5 mensajes, el tiempo total del loop es >= 400ms (espera entre dispatches)
- [x] 7.8 Test: counter sigue incrementándose en cada dispatch (observabilidad preservada)

## 8. Tests — sender

- [x] 8.1 Test: error con `code: 63038` → comm doc borrado, queue item a `queued`, `processedAt` limpio, `attempts` sin cambios, `pausedUntil` seteado
- [x] 8.2 Test: error con `code: 63032` → mismo comportamiento que 8.1
- [x] 8.3 Test: error 429 no-Meta → retry path existente (1s, 4s) — no se activa el rollback de tier
- [x] 8.4 Test: error 500 → retry path existente
- [x] 8.5 Test: rollback idempotente — llamar rollback dos veces no rompe (simular retry del trigger)
- [x] 8.6 Test: rollback con queue item ya borrado → no lanza excepción, loguea warn
- [x] 8.7 Test: `pausedUntil` escrito con merge no sobrescribe otros campos de `metadata/messaging`

## 9. Integración

- [x] 9.1 Test integración: escenario completo — orquestador dispatcha 3 mensajes, el primero falla por 63038, el sender escribe `pausedUntil`, siguiente ciclo del orquestador salta (pausado), el ciclo posterior a `pausedUntil` expira y vuelve a dispatchar los mismos 3 (el primero incluido)
- [x] 9.2 Confirmar que el queue item del mensaje fallado quedó `queued` y se redispatcha con el mismo `idempotencyKey` sin crear duplicado

## 10. Deploy checklist

- [ ] 10.1 Invocar 🛡️ Security Guardian en la PR antes del commit (OWASP, multi-tenancy, PII, Firebase rules) — MANUAL/PENDING
- [ ] 10.2 Validar el nuevo índice con `firebase_validate_security_rules` y deploy de índices primero: `firebase deploy --only firestore:indexes` — MANUAL/PENDING
- [ ] 10.3 Esperar en consola Firebase a que el índice pase a `ENABLED` — MANUAL/PENDING
- [ ] 10.4 Deploy combinado: `firebase deploy --only functions:messageOrchestrator,functions:sendWhatsAppReminder` — MANUAL/PENDING
- [ ] 10.5 Monitorear logs del primer ciclo post-deploy: confirmar batch de 500, ausencia de log "daily limit reached" — MANUAL/PENDING
- [ ] 10.6 Confirmar en Firestore que `metadata/messaging_counters` sigue incrementándose (counter observable vivo) — MANUAL/PENDING

## 11. Cleanup (opcional, fuera del scope crítico)

- [ ] 11.1 Actualizar `firebase/functions/src/utils/README.md` con la nueva semántica y los campos nuevos
- [ ] 11.2 Actualizar admin UI si expone `dailyConversationLimit` / `urgentReservePercentage`: marcar como "deprecado, no se aplica desde v{X}"
- [ ] 11.3 (Futuro) Remover `dailyConversationLimit` y `urgentReservePercentage` del schema y del admin panel — fuera de esta change
