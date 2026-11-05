## Why

El sistema actual de notificaciones WhatsApp solo soporta recordatorios de turno (`appointment_reminder`). El `payment_reminder` ya existe como messageType en la cola pero `buildTwilioContentVariables()` lanza error porque no tiene las variables mapeadas. Los profesionales necesitan enviar resúmenes de deuda mensuales a pacientes, y el template de turno necesita actualizarse (nuevo SID con texto plano, mismas variables).

## What Changes

- **Actualizar template de recordatorio de turno**: cambiar el Content SID en Twilio/metadata para apuntar al nuevo template con texto plano (mismas variables, nuevo formato).
- **Implementar `payment_reminder` en `buildTwilioContentVariables()`**: mapear las 5 variables del nuevo template de cobro (nombre paciente, profesional|profesión, monto total, detalle de montos por fecha, listado de fechas).
- **Nuevo cron `monthlyDebtNotifier`**: ejecuta 1 vez al mes, itera sobre todos los providers con plan activo (basic/premium/trial), calcula deuda por paciente con detalle de fechas, y encola mensajes `payment_reminder`.
- **Modificar `monthlyDebtProcessor`**: separar la lógica de encolado de mensajes del procesamiento de intereses/snapshots, ya que el nuevo cron se encarga de las notificaciones de deuda.
- **Actualizar frontend**: distinguir tipos de notificación en el historial de comunicaciones, mostrar las variables del `payment_reminder` de forma legible.
- **Registrar template SID de `payment_reminder`** en `metadata/messaging.templates.payment_reminder.contentSid`.

## Capabilities

### New Capabilities
- `monthly-debt-notification`: Cron mensual que calcula deuda por paciente con detalle de fechas/montos y encola mensajes WhatsApp de tipo `payment_reminder` para todos los providers con plan activo. Prioridad fija (nunca escala), vencimiento 10 días.
- `payment-reminder-template`: Mapeo de variables del template de cobro en `buildTwilioContentVariables()` y resolución del Content SID para `payment_reminder`.

### Modified Capabilities
- (ninguna capability existente con spec cambia a nivel de requisitos)

## Impact

- **Cloud Functions afectadas**:
  - `messaging_utils.ts` — implementar `buildTwilioContentVariables` para `payment_reminder` (5 variables posicionales)
  - `monthlyDebtProcessor.ts` — remover encolado de mensajes (se mueve al nuevo cron)
  - Nuevo archivo `cron/monthlyDebtNotifier.ts`
  - `cron/index.ts` — exportar el nuevo cron
- **Firestore**:
  - `metadata/messaging.templates.payment_reminder.contentSid` — nuevo campo
  - `message_queue` — nuevos docs con `messageType: "payment_reminder"` y variables expandidas
  - `communications` — docs con variables de deuda detallada
- **Frontend Flutter**:
  - `communication_log_model.dart` / `communication_log.dart` — parsear las nuevas variables
  - UI de historial de comunicaciones — renderizar distinto según `messageType`
- **Twilio/Meta**: requiere crear el template en la plataforma y obtener el Content SID
- **Dependencias**: ninguna nueva
- **SID del template de turno**: solo requiere actualizar el valor en `metadata/messaging` (o provider override) — el código ya resuelve dinámicamente, no hay cambio de código necesario
