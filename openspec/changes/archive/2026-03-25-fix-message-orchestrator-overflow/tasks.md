## 1. Limpiar messageOrchestrator

- [x] 1.1 Eliminar la función `runEscalationPass()` y su llamada en `messageOrchestrator.ts`
- [x] 1.2 Eliminar las importaciones no usadas que quedaron de `runEscalationPass` (si las hay)

## 2. Implementar elevación de urgencia por proximidad

- [x] 2.1 Agregar un paso de "urgency elevation" al inicio del orquestador: query `status == "queued"` && `scheduledFor <= now` && `expiresAt - now < 24h` && `isUrgent == false`
- [x] 2.2 Batch-update esos documentos con `isUrgent = true` y `priority = 10`
- [x] 2.3 Agregar log de cuántos mensajes fueron elevados a urgente en cada ciclo

## 3. Tests

- [x] 3.1 Test: mensaje con `scheduledFor <= now` y slots disponibles → se despacha en el ciclo
- [x] 3.2 Test: límite diario alcanzado → mensaje permanece `queued`, `scheduledFor` sin cambios
- [x] 3.3 Test: mensaje `queued` vencido con `expiresAt - now < 24h` → recibe `isUrgent = true`
- [x] 3.4 Test: mensaje `queued` vencido con `expiresAt - now >= 24h` → `isUrgent` no cambia
- [x] 3.5 Test: verificar que `scheduledFor` nunca se modifica por el orquestador

## 4. Fix `checkDuplicate`

- [x] 4.1 Cambiar status filter de `["queued", "processing", "sent"]` a `["processing", "sent"]`
- [x] 4.2 Cambiar campo de ventana temporal de `createdAt` a `processedAt`

## 5. Fix `queueCleanup`

- [x] 5.1 Reemplazar el batch único por un loop que emita batches de máximo 500 operaciones

## 6. Fix `dailyScheduledActivator`

- [x] 6.1 Cambiar `maxInstances: 10` a `maxInstances: 1`

## 7. Tests adicionales

- [x] 7.1 Test: `checkDuplicate` con un mensaje `"queued"` existente → `isDuplicate = false`
- [x] 7.2 Test: `checkDuplicate` con un mensaje `"sent"` con `processedAt` dentro de 24h → `isDuplicate = true`
- [x] 7.3 Test: `checkDuplicate` con un mensaje `"sent"` con `processedAt` fuera de 24h → `isDuplicate = false`
- [x] 7.4 Test: `queueCleanup` con 600 documentos elegibles → dos batches sin error

## 8. Fix `onAppointmentCreated` — variables faltantes

- [x] 8.1 Extraer `nombre_profesional` del provider doc ya leído (`profession + name`, igual que en `appointmentReminderGenerator`)
- [x] 8.2 Extraer `concepto_turno` de `appointmentData.concept` con default `"Consulta"`
- [x] 8.3 Agregar ambas variables al objeto `variables` del `enqueueMessage`
- [x] 8.4 Test: turno < 48h → mensaje encolado tiene `nombre_profesional` y `concepto_turno` no vacíos
- [x] 8.5 Test: turno sin `concept` → `concepto_turno` es `"Consulta"`

## 9. Fix `onAppointmentDeleted` — cancelar reminder encolado

- [x] 9.1 Al final del trigger, buscar en `message_queue` por `sourceAppointmentId == appointmentId` y `status == "queued"`
- [x] 9.2 Marcar los items encontrados con `status: "cancelled"`
- [x] 9.3 Agregar `"cancelled"` al set de statuses terminales en `queueCleanup` para que sea limpiado después de 7 días
- [x] 9.4 Test: turno eliminado con reminder `"queued"` → item pasa a `"cancelled"`
- [x] 9.5 Test: turno eliminado con reminder `"processing"` → item no se modifica
- [x] 9.6 Test: turno eliminado sin reminder → no error

## 10. Fix `queueCleanup` — limpiar items `"processing"` atascados

- [x] 10.1 Agregar query: `status == "processing"` y `processedAt < 48h ago`
- [x] 10.2 Incluir esos docs en el batch de eliminación (respetando chunks de 500)
- [x] 10.3 Test: item `"processing"` con `processedAt` hace 49h → eliminado
- [x] 10.4 Test: item `"processing"` con `processedAt` hace 24h → no eliminado

## 11. Refactor — extraer `enqueueUrgentReminder` como utilidad compartida

- [x] 11.1 Extraer el fast-path de `onAppointmentCreated` (enqueue urgente < 48h) a una función `enqueueUrgentAppointmentReminder(appointmentId, appointmentData, providerId, patientId)` en `utils/messaging_utils.ts`
- [x] 11.2 Reemplazar el código inline en `onAppointmentCreated` por una llamada a la nueva función

## 12. Fix `onAppointmentUpdated` — cancelar y re-encolar cuando cambia la fecha

- [x] 12.1 Al detectar `dateChanged == true`, buscar item `"queued"` con `sourceAppointmentId == appointmentId` y marcarlo `"cancelled"`
- [x] 12.2 Si nueva fecha en el pasado → no encolar
- [x] 12.3 Si nueva fecha ≥ 48h → no encolar (el generator lo toma)
- [x] 12.4 Si nueva fecha < 48h → llamar a `enqueueUrgentAppointmentReminder`
- [x] 12.5 Test: fecha cambia a < 48h → reminder viejo `"cancelled"`, nuevo encolado con variables actualizadas
- [x] 12.6 Test: fecha cambia a ≥ 48h → reminder viejo `"cancelled"`, no se encola nuevo
- [x] 12.7 Test: fecha cambia a pasado → reminder viejo `"cancelled"`, no se encola nuevo
- [x] 12.8 Test: actualización sin cambio de fecha → `message_queue` no se toca

## 13. Validación post-deploy

- [ ] 13.1 Verificar en Firebase logs que el primer ciclo post-deploy despacha mensajes con `scheduledFor` ya vencido
- [ ] 13.2 Confirmar que no hay documentos de `message_queue` con `scheduledFor` modificado por el orquestador
