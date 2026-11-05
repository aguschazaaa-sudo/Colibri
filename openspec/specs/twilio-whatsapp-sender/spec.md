## ADDED Requirements

### Requirement: Envío real via Twilio API
El sistema SHALL enviar mensajes WhatsApp reales usando el SDK oficial de Twilio (`twilio` npm) con el Content Template aprobado correspondiente al tipo de mensaje.

#### Scenario: Envío exitoso de appointment_reminder
- **WHEN** se crea un documento en `providers/{id}/communications/{commId}` con `type: "whatsapp_reminder"` y `status: "pending"`
- **THEN** el sistema obtiene el Content SID via `resolveTemplateContentSid`, llama a Twilio Messages API, actualiza el documento a `status: "sent"` con el `messageId` real de Twilio, y actualiza el queue item a `status: "sent"`

#### Scenario: Paciente sin teléfono registrado
- **WHEN** el paciente asociado al mensaje no tiene campo `phone` o está vacío
- **THEN** el sistema marca la communication como `status: "aborted"`, `reason: "no_phone"`, el queue item como `status: "failed"`, `lastError: "no_phone"`, y no realiza ningún intento a Twilio

#### Scenario: Template no configurado
- **WHEN** `resolveTemplateContentSid` no encuentra SID ni en el provider ni en `metadata/messaging`
- **THEN** el sistema marca la communication como `status: "aborted"`, `reason: "template_not_configured"`, y no realiza ningún intento a Twilio

#### Scenario: Error transitorio de Twilio (1er intento)
- **WHEN** Twilio retorna error 429 o 5xx en el primer intento
- **THEN** el sistema espera 1 segundo y reintenta

#### Scenario: Error transitorio de Twilio (2do intento)
- **WHEN** Twilio retorna error 429 o 5xx en el segundo intento
- **THEN** el sistema espera 4 segundos y reintenta

#### Scenario: Fallo agotado (3 intentos)
- **WHEN** Twilio falla en los 3 intentos
- **THEN** el sistema marca la communication como `status: "failed"` con el `lastError` del mensaje de Twilio, actualiza `attempts` en el queue item, y no lanza excepción no capturada

#### Scenario: Suscripción inactiva del provider
- **WHEN** el provider asociado tiene `subscriptionStatus !== "active"`
- **THEN** el sistema marca la communication como `status: "aborted"`, `reason: "subscription_inactive"`, sin llamar a Twilio

### Requirement: Secrets via Firebase Secret Manager
Las credenciales de Twilio SHALL obtenerse exclusivamente de Firebase Secret Manager; nunca de variables de entorno hardcodeadas ni código fuente.

#### Scenario: Función declarada con secrets
- **WHEN** se hace deploy de `sendWhatsAppReminder`
- **THEN** la función tiene `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM` declarados en `runWith({ secrets: [...] })`

### Requirement: Sin logging de PII
El sistema SHALL omitir números de teléfono, nombres y montos de todos los logs.

#### Scenario: Log de intento de envío
- **WHEN** el sistema intenta enviar un mensaje
- **THEN** los logs contienen solo `commId`, `providerId`, `messageType` y estado — nunca el número de teléfono ni nombre del paciente
