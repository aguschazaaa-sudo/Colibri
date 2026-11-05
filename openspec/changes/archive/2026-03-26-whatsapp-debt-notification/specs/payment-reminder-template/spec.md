## ADDED Requirements

### Requirement: Payment reminder template variable mapping
El sistema SHALL mapear las 5 variables del template de cobro en `buildTwilioContentVariables()` para el messageType `payment_reminder`.

#### Scenario: Variables mapeadas correctamente
- **WHEN** se construyen las variables para un `payment_reminder` con datos: paciente "Juan Pérez", provider "Dra. María López | Odontología", deuda total $10.000, 2 turnos (15/03: $5.000, 22/03: $5.000)
- **THEN** el sistema SHALL producir:
  - `{{1}}`: `"Juan Pérez"` (nombre paciente)
  - `{{2}}`: `"Dra. María López | Odontología"` (nombre profesional | profesión)
  - `{{3}}`: `"$10.000"` (monto total pendiente)
  - `{{4}}`: `"la suma de 2 turnos pendientes"` (descripción del origen)
  - `{{5}}`: `"- 15/03/2026: $5.000\n- 22/03/2026: $3.000"` (listado de fechas)

#### Scenario: Un solo turno impago
- **WHEN** el paciente tiene 1 solo turno impago del 15/03 por $5.000
- **THEN** `{{4}}` SHALL ser `"$5.000 del 15/03"` y `{{5}}` SHALL ser `"- 15/03/2026: $5.000"`

#### Scenario: Más de 10 turnos
- **WHEN** el paciente tiene 12 turnos impagos
- **THEN** `{{5}}` SHALL listar las 10 fechas más recientes y terminar con `"... y 2 turnos anteriores"`

### Requirement: Payment reminder template SID resolution
El sistema SHALL resolver el Content SID para `payment_reminder` usando el mismo mecanismo de dos niveles: override del provider primero, fallback al global en `metadata/messaging.templates.payment_reminder.contentSid`.

#### Scenario: SID configurado globalmente
- **WHEN** existe `metadata/messaging.templates.payment_reminder.contentSid` y el provider no tiene override
- **THEN** el sistema SHALL usar el SID global

#### Scenario: SID con override del provider
- **WHEN** el provider tiene `messageTemplates.payment_reminder` configurado
- **THEN** el sistema SHALL usar el SID del provider, ignorando el global

#### Scenario: SID no configurado
- **WHEN** no existe SID ni global ni en el provider para `payment_reminder`
- **THEN** el sistema SHALL lanzar `TemplateNotConfiguredError` y el worker SHALL marcar la comunicación como `status: "aborted"`, `reason: "template_not_configured"`

### Requirement: Frontend communication log rendering by message type
El frontend SHALL renderizar las entradas del historial de comunicaciones de forma diferenciada según `messageType`.

#### Scenario: Renderizar payment_reminder en historial
- **WHEN** el frontend muestra una comunicación con `messageType: "payment_reminder"`
- **THEN** SHALL mostrar: el monto total de deuda, y un detalle expandible/visible con las fechas y montos individuales extraídos de `variables`

#### Scenario: Renderizar appointment_reminder en historial
- **WHEN** el frontend muestra una comunicación con `messageType: "appointment_reminder"`
- **THEN** SHALL mantener el render actual sin cambios

#### Scenario: messageType null o desconocido
- **WHEN** el frontend encuentra una comunicación sin `messageType` o con un tipo desconocido
- **THEN** SHALL renderizar con un formato genérico sin romper la UI
