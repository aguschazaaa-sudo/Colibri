## Context

El sistema de notificaciones WhatsApp ya tiene una arquitectura de cola robusta: producer -> `message_queue` -> `messageOrchestrator` (cada 10 min) -> `communications` -> `sendWhatsAppReminder` (trigger onCreate) -> Twilio. El `messageType: "payment_reminder"` ya existe como concepto en la cola y en los modelos, pero `buildTwilioContentVariables()` lanza error porque las variables no están mapeadas. El `monthlyDebtProcessor` ya encola payment reminders pero con solo 2 variables (nombre, monto total). El nuevo template requiere 5 variables con detalle de fechas.

**Estado actual:**
- `appointmentReminderGenerator` (7 AM diario) genera reminders de turno con prioridad 20/10.
- `monthlyDebtProcessor` (1ro de cada mes, 15h) aplica intereses, guarda snapshots, resetea revenue, Y encola payment reminders.
- Template `appointment_reminder`: 6 variables posicionales en Twilio.
- Template `payment_reminder`: existe en Twilio (SID: `HX444ff8072252e471cf2a88981c168088`), pero no mapeado en código ni configurado en Firestore.

## Goals / Non-Goals

**Goals:**
- Implementar el template de cobro con 5 variables (nombre, profesional|profesión, monto, detalle montos, fechas).
- Crear un cron mensual dedicado que calcule deuda por paciente con detalle de cada turno impago.
- Que el cálculo de deuda sea exacto y auditable (query directa a appointments, no cached).
- Que el frontend pueda renderizar las variables del payment_reminder en el historial.
- Prioridad fija (30), nunca escala, vencimiento 10 días.
- Aplica a todos los providers con plan activo (basic, premium, trial).

**Non-Goals:**
- Cambiar la lógica de intereses/snapshots del `monthlyDebtProcessor`.
- Implementar opt-out por paciente (futuro).
- Configurar día del mes de envío por provider (futuro, siempre 1ro del mes).
- Cambiar el flujo de `appointment_reminder` (solo se cambia el SID en metadata).
- Rate limiting del callable `triggerManualReminders` (issue separado).

## Decisions

### D1: Nuevo cron separado vs. modificar monthlyDebtProcessor

**Decisión:** Crear `monthlyDebtNotifier.ts` como cron independiente, separado de `monthlyDebtProcessor`.

**Razón:** El `monthlyDebtProcessor` tiene responsabilidades financieras (intereses, snapshots, reset revenue) que son críticas y distintas del envío de notificaciones. Separar permite:
- Ejecutar las notificaciones en horario diferente (ambos a las 15h pero potencialmente desacoplarlos).
- Reintentar notificaciones sin re-ejecutar lógica financiera.
- Testing independiente.
- El `monthlyDebtProcessor` deja de encolar mensajes.

**Alternativa descartada:** Agregar las 5 variables al encolado existente en `monthlyDebtProcessor` — mezcla responsabilidades y dificulta testing.

### D2: Cálculo de deuda — query directa vs. usar totalDebt del paciente

**Decisión:** Query directa a appointments `status: "unpaid"` del paciente para obtener detalle de fechas y montos individuales, pero **validar** que la suma coincida con `patient.totalDebt`.

**Razón:** El template necesita el detalle por fecha (variables {{4}} y {{5}}), que no está disponible en el campo `totalDebt` del paciente. La query a appointments es la única fuente de verdad para el desglose. La validación cruzada detecta inconsistencias.

**Si hay discrepancia:** Loguear warning (sin PII), usar la suma de appointments como fuente de verdad, y enviar el mensaje igual.

### D3: Formato de variables {{4}} y {{5}}

**Decisión:**
- **{{4}}** (detalle de montos): Si es un solo turno → `$5.000 del 15/03`. Si son múltiples → `la suma de X turnos pendientes` (ej: `la suma de 3 turnos pendientes`).
- **{{5}}** (fechas): Lista con formato `- 15/03/2026: $5.000\n- 22/03/2026: $3.000`. Máximo 7 fechas más recientes; si hay más, mostrar las 7 más recientes + `... y X turnos anteriores`.

**Razón:** WhatsApp tiene límite de ~1024 chars por variable. Con 7 fechas en formato `- DD/MM/YYYY: $XX.XXX\n` (~25 chars c/u) estamos en ~175 chars, seguro.

### D4: Prioridad y vencimiento

**Decisión:** `priority: 30`, `isUrgent: false`, `expiresAt: scheduledFor + 10 días`. Se permite escalamiento natural del orchestrator.

**Razón:** Son mensajes informativos, arrancan con prioridad baja (30) para no competir con reminders de turno. 10 días de vencimiento da margen al orchestrator para despachar gradualmente. Si al día 9 aún no se enviaron, el urgency elevation pass del orchestrator los eleva automáticamente — esto es deseable, ya que asegura que se envíen antes de expirar.

### D5: Planes elegibles — todos los activos

**Decisión:** Enviar a providers con `subscriptionStatus` en `["active"]` y `subscriptionPlan` en `["basic", "premium", "trial"]`.

**Razón:** El usuario quiere que todos los que tienen plan activo reciban el beneficio. No filtrar por plan premium como hace `monthlyDebtProcessor`.

### D6: Template SID del appointment_reminder

**Decisión:** Solo actualizar el valor en `metadata/messaging.templates.appointment_reminder.contentSid` (o el override del provider). No hay cambio de código.

**Razón:** `resolveTemplateContentSid()` ya resuelve dinámicamente. Cambiar el SID en Firestore es suficiente siempre que el nuevo template use las mismas variables posicionales en el mismo orden.

### D7: Refactor — extraer utilidades compartidas

**Decisión:** Extraer `BatchWriter` y `getAllInChunks` de `monthlyDebtProcessor.ts` a archivos de utilidades compartidos (`utils/batch_utils.ts` y `utils/firestore_utils.ts`). Ambos crons los importan.

**Razón:** `monthlyDebtProcessor` y `monthlyDebtNotifier` usan exactamente la misma implementación de `BatchWriter` (batches de 450 ops) y `getAllInChunks` (lectura en chunks de 300 con concurrencia 5). Duplicar es deuda técnica innecesaria.

**No se extrae:** La query de providers (filtros distintos) ni la agregación por paciente (el notifier necesita detalle de fechas/montos que el processor no usa).

### D8: Horario — desfasar processor y notifier

**Decisión:** `monthlyDebtProcessor` a las 15:00, `monthlyDebtNotifier` a las 16:00 (ambos el 1ro del mes).

**Razón:** El processor aplica intereses primero, el notifier debe leer los montos ya actualizados. 1 hora de margen es suficiente para que el processor termine.

### D9: Frontend — distinguir tipos de notificación

**Decisión:** Usar el campo `messageType` ya existente en `CommunicationLog` para renderizar distinto. Para `payment_reminder`, mostrar las variables como detalle expandible (monto total, lista de fechas). Para `appointment_reminder`, mantener el render actual.

**Razón:** El modelo ya tiene `messageType` y `variables` (Map). No se necesita nuevo modelo, solo lógica de presentación.

## Risks / Trade-offs

- **[Cálculo de deuda incorrecto]** → Mitigación: validación cruzada con `totalDebt`, tests exhaustivos con múltiples escenarios (0 turnos, 1 turno, >10 turnos, pagos parciales).
- **[Template no aprobado en Meta]** → Mitigación: el sistema ya maneja `TemplateNotConfiguredError` gracefully (abort, no crash). Se puede desplegar el código antes de tener el template aprobado.
- **[Volumen de mensajes alto el 1ro del mes]** → Mitigación: el orchestrator ya tiene rate limiting (250/día, ventana 8-20h). Los payment reminders tienen prioridad 30 (baja), no bloquean turnos urgentes (prioridad 10). Con 10 días de vencimiento, se despachan gradualmente.
- **[Variables {{5}} demasiado largas]** → Mitigación: límite de 10 fechas + truncado con "... y X turnos anteriores".
- **[Discrepancia totalDebt vs suma appointments]** → Mitigación: log de warning, usar appointments como fuente de verdad, no bloquear envío.
