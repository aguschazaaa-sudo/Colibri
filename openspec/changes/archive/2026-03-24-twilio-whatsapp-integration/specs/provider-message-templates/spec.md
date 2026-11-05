## ADDED Requirements

### Requirement: Template global por tipo de mensaje
El sistema SHALL soportar un Content SID de Twilio global por tipo de mensaje, almacenado en `metadata/messaging.templates.<messageType>.contentSid` en Firestore.

#### Scenario: Lookup de template global existente
- **WHEN** se invoca `resolveTemplateContentSid(providerId, "appointment_reminder")` y el provider no tiene override
- **THEN** el sistema retorna el `contentSid` de `metadata/messaging.templates.appointment_reminder`

#### Scenario: Template global ausente
- **WHEN** `metadata/messaging` no tiene configurado `templates.<messageType>.contentSid`
- **THEN** `resolveTemplateContentSid` lanza `TemplateNotConfiguredError`

### Requirement: Override de template por proveedor
El sistema SHALL permitir a cada provider configurar su propio Content SID de Twilio por tipo de mensaje en `providers/{id}.messageTemplates.<messageType>`, que tiene precedencia sobre el global.

#### Scenario: Provider con override configurado
- **WHEN** `providers/{id}.messageTemplates.appointment_reminder` existe y es no-vacío
- **THEN** `resolveTemplateContentSid` retorna ese SID sin consultar `metadata/messaging`

#### Scenario: Provider sin override
- **WHEN** `providers/{id}.messageTemplates` es null o no tiene la clave del tipo de mensaje
- **THEN** el sistema hace fallback al SID global de `metadata/messaging`

### Requirement: Cache en memoria de template global
El sistema SHALL cachear el SID global de `metadata/messaging` en memoria de la Cloud Function por hasta 5 minutos para reducir lecturas a Firestore en ráfagas del orquestador.

#### Scenario: Cache hit dentro de ventana de 5 minutos
- **WHEN** `resolveTemplateContentSid` se llama dos veces dentro de 5 minutos para el mismo tipo de mensaje
- **THEN** la segunda llamada no genera lectura a Firestore

#### Scenario: Cache expirado
- **WHEN** han pasado más de 5 minutos desde la última lectura del template global
- **THEN** el sistema relee `metadata/messaging` desde Firestore

### Requirement: Extensible a payment_reminder (TODO)
La infraestructura de templates SHALL ser genérica — `resolveTemplateContentSid(providerId, messageType)` funciona con cualquier `messageType` definido en `VALID_MESSAGE_TYPES`.

#### Scenario: payment_reminder sin template configurado
- **WHEN** se intenta enviar un `payment_reminder` y no hay SID configurado en global ni en provider
- **THEN** el sistema lanza `TemplateNotConfiguredError`, el worker marca la communication como `aborted` con `reason: "template_not_configured"`
