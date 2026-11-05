## MODIFIED Requirements

### Requirement: Variables correctas para recordatorio de turno
El mensaje enviado al paciente para `appointment_reminder` SHALL usar las 6 variables posicionales del Content Template de Twilio aprobado. El worker mapea variables semánticas a posiciones numéricas antes de llamar a la API.

Mapeo posicional (fijo por el template aprobado `HX5434632a7b72b2d9adacd23f73a35767`):

| Posición Twilio | Variable semántica   | Fuente                              |
|-----------------|----------------------|-------------------------------------|
| `{{1}}`         | `nombre_paciente`    | `patients/{id}.name`                |
| `{{2}}`         | `fecha_turno`        | `appointment.date` (dd/mm/yyyy)     |
| `{{3}}`         | _(no usado)_         | omitir                              |
| `{{4}}`         | `hora_turno`         | `appointment.date` (HH:mm)          |
| `{{5}}`         | `nombre_profesional` | `"${profession} ${name}"` si `profession` no está vacío; solo `name` si está vacío. Ej: `"Psicóloga Paola"` |
| `{{6}}`         | `concepto_turno`     | `appointment.concept` (fallback: `"Consulta"`) |

#### Scenario: Variables completas enviadas a Twilio
- **WHEN** el orquestador promueve un `appointment_reminder` a `communications`
- **THEN** `contentVariables` enviado a Twilio es `{"1": nombre, "2": fecha, "4": hora, "5": profesional, "6": concepto}` — el campo `"3"` se omite

#### Scenario: Concepto del turno ausente
- **WHEN** `appointment.concept` es null o vacío
- **THEN** la variable `concepto_turno` toma el valor `"Consulta"`

#### Scenario: Profesional con título configurado
- **WHEN** `providers/{id}.profession` es no vacío (ej: `"Psicóloga"`)
- **THEN** `nombre_profesional` es `"${profession} ${name}"` (ej: `"Psicóloga Paola"`)

#### Scenario: Profesional sin título
- **WHEN** `providers/{id}.profession` es null o vacío
- **THEN** `nombre_profesional` es solo `name` del provider (ej: `"Paola"`)

#### Scenario: Variables encoladas desde appointmentReminderGenerator
- **WHEN** `appointmentReminderGenerator` encola un mensaje
- **THEN** el documento en `message_queue` contiene `variables.nombre_profesional` y `variables.concepto_turno` además de `nombre_paciente`, `fecha_turno`, `hora_turno`

## ADDED Requirements

### Requirement: Guard de 24h centralizada en orquestador
El sistema SHALL verificar duplicados de mensajes por paciente/tipo en una única ubicación: `checkDuplicate()` en `messageOrchestrator`, antes de mover el item a `processing`. El worker `sendWhatsAppReminder` NO SHALL reimplementar esta lógica.

#### Scenario: Duplicado detectado en orquestador
- **WHEN** `checkDuplicate(patientId, messageType)` retorna `true` durante la pasada del orquestador
- **THEN** el queue item se marca `status: "duplicate"` y no se crea documento en `communications`

#### Scenario: Worker no hace query de duplicado
- **WHEN** `sendWhatsAppReminder` procesa un documento de `communications`
- **THEN** el worker no ejecuta ninguna query a `message_queue` o `communications` para verificar duplicados previos
