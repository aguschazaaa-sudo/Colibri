## ADDED Requirements

### Requirement: Monthly debt notification cron job
El sistema SHALL ejecutar un cron job (`monthlyDebtNotifier`) el 1ro de cada mes a las 09:00 hora de Buenos Aires que encole mensajes `payment_reminder` para cada paciente con deuda > 0 de cada provider con plan activo.

#### Scenario: Provider con plan activo y pacientes con deuda
- **WHEN** el cron ejecuta el 1ro del mes a las 15:00 (Buenos Aires) y existe un provider con `subscriptionStatus: "active"` y `subscriptionPlan` en `["basic", "premium", "trial"]` que tiene pacientes con turnos `status: "unpaid"`
- **THEN** el sistema SHALL encolar un mensaje `payment_reminder` en `message_queue` por cada paciente con deuda, con `priority: 30`, `isUrgent: false`, `expiresAt: scheduledFor + 10 días`

#### Scenario: Provider con plan inactivo
- **WHEN** el cron ejecuta y un provider tiene `subscriptionStatus` distinto de `"active"` (ej: `"past_due"`, `"suspended"`)
- **THEN** el sistema SHALL omitir ese provider y no encolar ningún mensaje para sus pacientes

#### Scenario: Paciente sin deuda
- **WHEN** un paciente tiene `totalDebt == 0` o no tiene turnos con `status: "unpaid"`
- **THEN** el sistema SHALL no encolar mensaje para ese paciente

#### Scenario: Provider sin pacientes
- **WHEN** un provider activo no tiene pacientes registrados
- **THEN** el sistema SHALL continuar sin error y procesar el siguiente provider

### Requirement: Debt calculation with per-appointment detail
El sistema SHALL calcular la deuda consultando directamente los turnos con `status: "unpaid"` del paciente, obteniendo fecha y monto individual de cada uno. SHALL validar que la suma coincida con `patient.totalDebt`.

#### Scenario: Cálculo con múltiples turnos impagos
- **WHEN** un paciente tiene 3 turnos impagos (15/03: $5.000, 22/03: $3.000, 29/03: $2.000)
- **THEN** el mensaje SHALL incluir `monto_total: "$10.000"`, con detalle de las 3 fechas y sus montos individuales

#### Scenario: Cálculo con un solo turno impago
- **WHEN** un paciente tiene 1 turno impago (15/03: $5.000)
- **THEN** el mensaje SHALL incluir `monto_total: "$5.000"` con detalle de esa única fecha

#### Scenario: Discrepancia entre totalDebt y suma de appointments
- **WHEN** `patient.totalDebt` difiere de la suma de montos de turnos `unpaid`
- **THEN** el sistema SHALL loguear un warning (sin PII), usar la suma de appointments como fuente de verdad, y enviar el mensaje igualmente

#### Scenario: Paciente con más de 7 turnos impagos
- **WHEN** un paciente tiene más de 7 turnos con `status: "unpaid"`
- **THEN** el sistema SHALL incluir las 7 fechas más recientes en el detalle, y agregar texto `"... y X turnos anteriores"` donde X es la cantidad restante

### Requirement: Message priority and expiration
Los mensajes de debt notification SHALL iniciar con prioridad baja y vencimiento de 10 días, permitiendo escalamiento natural del orchestrator.

#### Scenario: Prioridad inicial baja
- **WHEN** el cron mensual encola un mensaje `payment_reminder`
- **THEN** el mensaje SHALL tener `priority: 30` e `isUrgent: false`, quedando por debajo de appointment reminders (prioridad 10-20)

#### Scenario: Escalamiento natural antes de vencer
- **WHEN** un mensaje `payment_reminder` tiene `expiresAt` a menos de 24h y aún está en estado `queued`
- **THEN** el orchestrator SHALL elevar su prioridad a 10 y marcarlo como `isUrgent: true` (comportamiento estándar del urgency elevation pass)

#### Scenario: Mensaje expirado
- **WHEN** un mensaje `payment_reminder` del cron mensual no fue procesado en 10 días
- **THEN** el orchestrator SHALL marcarlo como `status: "expired"`

### Requirement: Remove message enqueuing from monthlyDebtProcessor
El `monthlyDebtProcessor` SHALL dejar de encolar mensajes `payment_reminder`. La responsabilidad de notificaciones de deuda pasa al nuevo cron `monthlyDebtNotifier`.

#### Scenario: monthlyDebtProcessor ya no encola mensajes
- **WHEN** el `monthlyDebtProcessor` ejecuta el 1ro del mes
- **THEN** SHALL procesar intereses, guardar snapshots y resetear revenue, pero SHALL NOT escribir documentos en `message_queue`
