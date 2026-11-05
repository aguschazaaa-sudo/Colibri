## Why

La sección de Recordatorios muestra un historial de envíos con información insuficiente (solo nombre del paciente, fecha relativa y estado), y el contador mensual incluye envíos fallidos. Ambos problemas degradan la utilidad de la pantalla como herramienta de seguimiento del profesional.

## What Changes

- **Tipo de notificación visible en cada item**: Cada entrada del historial mostrará una etiqueta del tipo ("Recordatorio de turno", "Recordatorio de deuda") y un resumen breve del contenido (monto de deuda o fecha del turno).
- **Campo `messageType` en `CommunicationLog`**: Se agrega un campo `messageType` a la entidad y al modelo Firestore para distinguir el tipo de mensaje enviado.
- **Campo `contentSummary` en `CommunicationLog`**: Campo opcional que almacena un snippet legible del contenido (ej: "Deuda: $3.500" o "Turno: 28/03 a las 10:00 hs."), escrito por la Cloud Function al momento del envío.
- **Filtro por estado en el contador mensual**: `remindersStats` filtrará por `status == 'sent'` para contar solo envíos exitosos.
- **Actualización de Cloud Functions**: Las funciones que escriben en `communications` deberán incluir los nuevos campos `messageType` y `contentSummary`.

## Capabilities

### New Capabilities

- `notification-item-enriched-display`: Visualización enriquecida de cada item del historial, con tipo de notificación y resumen de contenido.

### Modified Capabilities

- `appointment-reminder-messaging`: La Cloud Function de recordatorio de turno debe escribir `messageType: 'appointment_reminder'` y `contentSummary` con fecha y hora del turno.
- `monthly-debt-messaging`: La Cloud Function de deuda mensual debe escribir `messageType: 'debt_reminder'` y `contentSummary` con el monto de deuda.

## Impact

- **Domain**: `lib/domain/communication_log.dart` — agregar `messageType` y `contentSummary`.
- **Data**: `lib/data/models/communication_log_model.dart` (o equivalente) — sincronizar los nuevos campos con Firestore.
- **Presentation**: `lib/presentation/reminders/widgets/reminder_history_item.dart` — mostrar tipo y resumen.
- **Presentation**: `lib/presentation/providers/reminders_provider.dart` — filtrar `totalThisMonth` por `status == 'sent'`.
- **Firebase Functions**: `firebase/functions/src/workers/sendWhatsAppReminder.ts` y `firebase/functions/src/cron/monthlyDebtProcessor.ts` — escribir los nuevos campos al crear el log.
