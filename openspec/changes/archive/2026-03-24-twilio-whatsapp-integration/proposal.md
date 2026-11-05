## Why

El sistema de mensajería WhatsApp tiene toda la infraestructura de cola, rate limiting y escalación implementada, pero el último metro falta: `sendWhatsAppReminder` llama a un mock que nunca contacta ninguna API real. Además hay un bug semántico donde los recordatorios de turno usan el mensaje de deuda, y dos inconsistencias de negocio (filtro premium y guard duplicada) que generarán problemas en producción.

## What Changes

- **Integración real con Twilio**: reemplazar `mockSendWhatsApp()` por llamadas reales a la Twilio API usando WhatsApp templates aprobados.
- **Fix bug semántico**: `appointment_reminder` debe usar las variables `fecha_turno` / `hora_turno` con su propio template, no el mensaje de deuda.
- **Sistema de templates por proveedor**: cada provider puede configurar su propio Content SID de Twilio (por tipo de mensaje), con fallback al SID global en `metadata/messaging`. Aplicado a `appointment_reminder`; `payment_reminder` queda como TODO con la infraestructura lista.
- **Deduplicar guard de 24h**: eliminar la query redundante en `sendWhatsAppReminder`; la única fuente de verdad queda en `messageOrchestrator` via `checkDuplicate()`.
- **Fix filtro premium en `monthlyDebtProcessor`**: agregar `plan === "premium"` al filtro de providers antes de encolar recordatorios de pago, igual que `appointmentReminderGenerator`.
- **Secrets vía Firebase Secret Manager**: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM` — nunca hardcodeados.
- **Retry strategy**: hasta 3 intentos con backoff exponencial; al agotar intentos el mensaje queda en `failed` con `lastError`.
- **Skip si paciente sin teléfono**: loguear warning y marcar communication como `aborted` con `reason: "no_phone"`.

## Capabilities

### New Capabilities

- `twilio-whatsapp-sender`: Envío real de mensajes WhatsApp via Twilio API con soporte de templates aprobados, retry con backoff, manejo de errores Twilio, y skip cuando el paciente no tiene teléfono registrado.
- `provider-message-templates`: Sistema de templates por proveedor — cada provider puede configurar Content SIDs de Twilio por tipo de mensaje; si no configura, se usa el SID global de `metadata/messaging`.

### Modified Capabilities

- `appointment-reminder-messaging`: El recordatorio de turno ahora usa su propio template con `fecha_turno` y `hora_turno` en lugar del mensaje de deuda. Comportamiento observable cambia para el paciente final.
- `monthly-debt-messaging`: El procesador mensual agrega el filtro `plan === "premium"` antes de encolar recordatorios de pago, alineándose con la política de negocio existente en `appointmentReminderGenerator`.

## Impact

**Firebase Functions:**
- `firebase/functions/src/workers/sendWhatsAppReminder.ts` — reescritura completa del handler
- `firebase/functions/src/cron/messageOrchestrator.ts` — eliminar guard duplicada
- `firebase/functions/src/cron/monthlyDebtProcessor.ts` — agregar filtro `plan === "premium"`
- `firebase/functions/src/utils/messaging_utils.ts` — agregar función `resolveTemplate()` (lookup por tipo + proveedor)

**Nueva dependencia:** `twilio` npm package en `firebase/functions`

**Firestore schema:**
- `metadata/messaging`: nuevos campos `templates.appointment_reminder.contentSid` y `templates.payment_reminder.contentSid`
- `providers/{id}`: nuevo campo opcional `messageTemplates.appointment_reminder` (Content SID override)

**Secrets Firebase Secret Manager:** `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM`

**No hay breaking changes para el cliente Flutter** — el sistema de cola y las colecciones `communications` no cambian estructura.
