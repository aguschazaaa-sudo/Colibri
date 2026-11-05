# Módulo cron

## Propósito

Contiene las Cloud Functions programadas (scheduled) que ejecutan tareas de mantenimiento periódicas: generación de turnos recurrentes, activación de turnos agendados, procesamiento mensual de deudas e intereses, reconciliación del estado de suscripciones contra Mercado Pago, y orquestación del sistema de mensajería WhatsApp.

## Archivos principales

- `dailyRecurringProcessor.ts` — Genera turnos recurrentes con dos días de anticipación (06:00 Buenos Aires, todos los días). Respeta días no laborables y vacaciones del profesional.
- `dailyScheduledActivator.ts` — Convierte turnos en estado `scheduled` a `unpaid` una vez que su fecha ha llegado (cada hora, en punto). Delega la lógica de deuda al trigger `onAppointmentUpdated`.
- `monthlyDebtProcessor.ts` — El día 1 de cada mes a las 15:00 aplica interés mensual a turnos impagos con más de un mes de antigüedad, actualiza `totalDebt` de cada paciente. Antes de resetear `monthlyRevenue`, guarda un snapshot mensual vía `saveMonthlySnapshot`. Solo procesa proveedores premium activos.
- `monthlyDebtNotifier.ts` — El día 1 de cada mes a las 16:00 (1 hora después de `monthlyDebtProcessor`) encola recordatorios de pago WhatsApp (`payment_reminder`) para todos los pacientes con `totalDebt > 0` de proveedores `active` con plan `basic`, `premium` o `trial`. Construye variables detalladas del template (monto, lista de fechas con importes).
- `subscriptionReconciler.ts` — Cada 6 horas consulta el estado de cada pre-aprobación en Mercado Pago y sincroniza `subscriptionStatus` y `plan` en el documento del proveedor.
- `messageOrchestrator.ts` — Cada 10 minutos lee la cola `message_queue`, verifica la ventana horaria (normal 8-20, urgentes 6-20 hora Buenos Aires), aplica el pass de escalamiento para turnos y promueve mensajes a `communications` dentro del límite diario de conversaciones.
- `appointmentReminderGenerator.ts` — Diariamente a las 07:00 busca turnos a +2 días, genera entradas en `message_queue` solo para proveedores premium activos. Idempotente via `sourceAppointmentId`.
- `queueCleanup.ts` — Diariamente a las 03:00 elimina documentos terminales (`sent`, `expired`, `duplicate`, `failed` con `attempts >= 3`) de `message_queue` con más de 7 días de antigüedad.
- `index.ts` — Barrel de re-exportaciones.

## Funciones documentadas

### dailyRecurringProcessor
- **Tipo:** scheduled
- **Trigger:** `0 6 * * *` — todos los días a las 06:00 (America/Argentina/Buenos_Aires)
- **Input:** ninguno
- **Output:** ninguno (escribe en Firestore)
- **Dependencias:**
  - Lee colección `recurring_appointments` (collectionGroup) filtrada por `active == true`
  - Lee colección `providers` para obtener `nonWorkingDays` y `vacations`
  - Escribe en `patients/{id}/appointments`
  - El trigger `onAppointmentCreated` maneja deuda y métricas del dashboard

---

### dailyScheduledActivator
- **Tipo:** scheduled
- **Trigger:** `0 * * * *` — cada hora en punto (America/Argentina/Buenos_Aires)
- **Input:** ninguno
- **Output:** ninguno (actualiza documentos en Firestore)
- **Dependencias:**
  - Lee colección `appointments` (collectionGroup) filtrada por `status == scheduled` y `date <= now`
  - Actualiza `status` a `unpaid`; el trigger `onAppointmentUpdated` toma el control desde ahí

---

### monthlyDebtProcessor
- **Tipo:** scheduled
- **Trigger:** `0 15 1 * *` — el día 1 de cada mes a las 15:00 (America/Argentina/Buenos_Aires)
- **Input:** ninguno
- **Output:** ninguno (actualiza documentos en Firestore)
- **Dependencias:**
  - Lee `providers` filtrado por `subscriptionStatus == active` **y `plan == premium`** (solo proveedores premium)
  - Lee `appointments` (collectionGroup) filtrado por `status == unpaid` y `date <= now`
  - Actualiza `totalAmount` en turnos con interés aplicado
  - Incrementa `totalDebt` en documentos de pacientes
  - Llama a `saveMonthlySnapshot` (persiste el revenue del mes en `providers/{id}/metrics/dashboard/monthly_snapshots/{YYYY-MM}`) antes del reset
  - Llama a `resetMonthlyRevenue` e `incrementDashboardMetrics` por proveedor
- **Nota:** los recordatorios de pago WhatsApp se delegan a `monthlyDebtNotifier` (16:00, 1 hora después)

---

### monthlyDebtNotifier
- **Tipo:** scheduled
- **Trigger:** `0 16 1 * *` — el día 1 de cada mes a las 16:00 (America/Argentina/Buenos_Aires, 1 hora después de `monthlyDebtProcessor`)
- **Input:** ninguno
- **Output:** ninguno (escribe en `message_queue`)
- **Dependencias:**
  - Lee `providers` filtrado por `subscriptionStatus == active` y `plan in [basic, premium, trial]`
  - Por cada proveedor: lee `patients` donde `totalDebt > 0`
  - Por cada paciente: lee `appointments` donde `status == unpaid`, ordenado por `date desc`
  - Encola recordatorio vía `enqueueMessage()` con `messageType=payment_reminder`, `priority=30`, `isUrgent=false`, `expiresAt=+10 días`
  - Variables del template: `nombre_paciente`, `profesional_profesion`, `monto_total`, `detalle_origen` (1 turno: "$X del DD/MM"; múltiples: "la suma de N turnos pendientes"), `fechas` (lista max 7 fechas con importes + "... y N turnos anteriores" si hay más)
- **Validación cruzada:** si la suma de appointments difiere del `totalDebt` del paciente en más de $1, registra un warning de diagnóstico (sin PII financiero).

---

### subscriptionReconciler
- **Tipo:** scheduled
- **Trigger:** `0 */6 * * *` — cada 6 horas (America/Argentina/Buenos_Aires)
- **Input:** ninguno
- **Output:** ninguno (actualiza documentos en Firestore)
- **Errores:** registra error por proveedor y continúa con el siguiente
- **Dependencias:**
  - Lee `providers` donde `mpPreapprovalId != null`
  - Consulta API de Mercado Pago (`PreApproval.get`) usando el secreto `MP_ACCESS_TOKEN`
  - Actualiza `subscriptionStatus`, `plan` y `subscriptionExpiresAt` en `providers/{id}`

---

### messageOrchestrator
- **Tipo:** scheduled (`maxInstances: 1`)
- **Trigger:** `*/10 * * * *` — cada 10 minutos (America/Argentina/Buenos_Aires)
- **Input:** ninguno
- **Output:** ninguno (crea documentos en `communications` y actualiza `message_queue`)
- **Dependencias:**
  - Lee `metadata/messaging` para la configuración de límites y ventana horaria
  - Lee `metadata/messaging_counters/current/current` para el contador diario de conversaciones
  - Lee `message_queue` filtrado por `status == queued` y `scheduledFor <= now`
  - Ejecuta `runEscalationPass()`: escala los recordatorios de turno de nivel 0→1 (24h antes) y 1→2/urgente (3h antes)
  - Escribe en `providers/{id}/communications` y en la sub-colección espejo `providers/{id}/patients/{id}/communications`
  - Actualiza `status` a `processing` en el documento de `message_queue`
  - Llama a `incrementCounter()` por cada mensaje promovido

---

### appointmentReminderGenerator
- **Tipo:** scheduled (`maxInstances: 1`)
- **Trigger:** `0 7 * * *` — todos los días a las 07:00 (America/Argentina/Buenos_Aires)
- **Input:** ninguno
- **Output:** ninguno (escribe en `message_queue`)
- **Dependencias:**
  - Lee `appointments` (collectionGroup) filtrado por `dateKey == hoy + 2 días`
  - Lee `providers` para verificar `subscriptionStatus == active` y `plan == premium` (con caché en memoria)
  - Lee `patients` para obtener el nombre (con caché en memoria)
  - Lee `message_queue` para idempotencia por `sourceAppointmentId`
  - Escribe en `message_queue` vía `enqueueMessage()` (messageType=`appointment_reminder`, priority=20, escalationLevel=0, expiresAt=fecha del turno)

---

### queueCleanup
- **Tipo:** scheduled (`maxInstances: 1`)
- **Trigger:** `0 3 * * *` — todos los días a las 03:00 (America/Argentina/Buenos_Aires)
- **Input:** ninguno
- **Output:** ninguno (elimina documentos de `message_queue`)
- **Dependencias:**
  - Lee `message_queue` con dos queries paralelas: estados terminales (`sent`, `expired`, `duplicate`) con `createdAt < cutoff` y `failed` con `attempts >= 3` y `createdAt < cutoff`
  - El cutoff es 7 días en el pasado
  - Usa batch delete (máx. 500 docs × 2 queries = 1 000 docs por ejecución)

## Dependencias

- `firebase-functions` y `firebase-admin` para scheduling y acceso a Firestore
- `mercadopago` (SDK) en `subscriptionReconciler`
- `../utils/dateAndInterest` — cálculo de interés mensual y lógica de fechas para recurrentes
- `../utils/metrics_utils` — helpers para actualizar métricas del dashboard y para guardar snapshots mensuales (`saveMonthlySnapshot`)
- `../utils/messaging_utils` — interfaces y funciones compartidas del sistema de mensajería (`enqueueMessage`, `getMessagingConfig`, `getOrResetCounter`, `incrementCounter`, `checkDuplicate`, `getBuenosAiresHour`)

## Notas

- `dailyRecurringProcessor` aumentó su lookahead de +1 a +2 días para que `appointmentReminderGenerator` (07:00) encuentre los turnos recurrentes ya creados cuando busca a +2 días.
- `messageOrchestrator` corre con `maxInstances: 1` para evitar condiciones de carrera en la actualización del contador diario.
- `monthlyDebtProcessor` usa un `BatchWriter` interno que auto-flushea cada 450 operaciones para respetar el límite de Firestore de 500 ops por batch.
- Los intereses solo se aplican a turnos con fecha anterior a `oneMonthAgo`; turnos más recientes acumulan deuda sin interés.
- `appointmentReminderGenerator` corre 1 hora después de `dailyRecurringProcessor` (06:00) para garantizar que los turnos recurrentes del día objetivo ya existen en Firestore.
- El escalamiento de recordatorios de turno es progresivo: nivel 0 (48h antes, normal) → nivel 1 (24h antes, normal) → nivel 2 (3h antes, urgente con priority=10).
