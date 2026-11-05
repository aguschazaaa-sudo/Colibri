## MODIFIED Requirements

### Requirement: Filtro premium en procesador mensual
`monthlyDebtProcessor` SHALL encolar recordatorios de pago solo para providers con `subscriptionStatus === "active"` AND `plan === "premium"`, alineándose con la política de negocio que restringe mensajería automática al plan premium.

#### Scenario: Provider activo plan premium recibe recordatorio
- **WHEN** `monthlyDebtProcessor` corre el 1ro del mes y encuentra un provider con `subscriptionStatus: "active"` y `plan: "premium"` con pacientes con deuda
- **THEN** el sistema encola `payment_reminder` para esos pacientes

#### Scenario: Provider activo plan básico NO recibe recordatorio
- **WHEN** `monthlyDebtProcessor` corre y encuentra un provider con `subscriptionStatus: "active"` pero `plan: "basic"` (o cualquier plan no-premium)
- **THEN** el sistema NO encola recordatorios de pago para ese provider

#### Scenario: Consistencia con appointmentReminderGenerator
- **WHEN** ambos `monthlyDebtProcessor` y `appointmentReminderGenerator` procesan un mismo provider
- **THEN** los dos aplican el mismo criterio de elegibilidad: `subscriptionStatus === "active"` AND `plan === "premium"`
