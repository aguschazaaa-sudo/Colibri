## Why

El sistema de mensajería WhatsApp tiene cuatro bugs que en conjunto hacen que los mensajes nunca se envíen a las 48h planeadas y que en casos de alta carga fallen silenciosamente. El bug principal es una `runEscalationPass()` que reschedula mensajes en lugar de despacharlos. Los otros tres son bugs secundarios descubiertos en la misma revisión.

## What Changes

- Eliminar `runEscalationPass()` del `messageOrchestrator` — la escalation automática impide que los mensajes se envíen en su ventana de 48h.
- Reemplazar la escalation por **urgencia por proximidad**: mensajes vencidos y no enviados se marcan `isUrgent = true` cuando el turno está a menos de 24h.
- Corregir `checkDuplicate` para que no self-identifique mensajes como duplicados (eliminar `"queued"` del filtro de status).
- Corregir `checkDuplicate` para anclar la ventana de 24h a `processedAt` en vez de `createdAt`.
- Corregir `queueCleanup` para no exceder el límite de 500 operaciones por batch de Firestore.
- Corregir `dailyScheduledActivator` cambiando `maxInstances: 10` a `maxInstances: 1` para evitar activaciones duplicadas de turnos.
- Corregir `onAppointmentCreated` para incluir `nombre_profesional` y `concepto_turno` en las variables del recordatorio urgente (turnos creados con < 48h de anticipación).
- Corregir `onAppointmentDeleted` para cancelar el item en `message_queue` cuando un turno es eliminado con un reminder ya encolado.
- Corregir `queueCleanup` para eliminar items atascados en `"processing"` con más de 48h desde `processedAt`.
- Corregir `onAppointmentUpdated` para cancelar el reminder encolado y re-encolarlo con las variables actualizadas cuando la fecha/hora del turno cambia.

## Capabilities

### New Capabilities

- `message-overflow-escalation`: Lógica que convierte mensajes vencidos y no enviados en urgentes cuando el turno está próximo, sin bloquear el envío en la ventana de 48h.

### Modified Capabilities

- (ninguna — los contratos de `message_queue` y `communications` no cambian)

## Impact

- **`firebase/functions/src/cron/messageOrchestrator.ts`**: Eliminar `runEscalationPass()`. Agregar urgency elevation pass antes del despacho.
- **`firebase/functions/src/utils/messaging_utils.ts`**: `checkDuplicate` — cambiar status filter y campo de ventana temporal.
- **`firebase/functions/src/cron/queueCleanup.ts`**: Dividir batch único en chunks de 500.
- **`firebase/functions/src/cron/dailyScheduledActivator.ts`**: `maxInstances: 10` → `maxInstances: 1`.
- **`firebase/functions/src/appointments/onAppointmentCreated.ts`**: agregar `nombre_profesional` y `concepto_turno` a las variables del recordatorio urgente.
- **`firebase/functions/src/appointments/onAppointmentDeleted.ts`**: cancelar item en `message_queue` con `sourceAppointmentId == appointmentId` y `status == "queued"`.
- **`firebase/functions/src/cron/queueCleanup.ts`**: agregar query de items `"processing"` con `processedAt < 48h ago`.
- **`firebase/functions/src/appointments/onAppointmentUpdated.ts`**: cuando `dateChanged == true`, cancelar reminder `"queued"` y re-encolar urgente si la nueva fecha es futura y < 48h.
- **Sin cambios en schema de Firestore** ni en clientes Flutter.
