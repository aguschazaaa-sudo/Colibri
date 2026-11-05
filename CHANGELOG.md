# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es/1.0.0/) y el versionado sigue [Semantic Versioning](https://semver.org/lang/es/).

## [Sin publicar]

### Agregado
- **`monthlyDebtNotifier` cron:** nueva Cloud Function (`0 16 1 * *`, 16:00 Buenos Aires) que envía recordatorios de pago WhatsApp detallados para todos los proveedores activos (basic, premium, trial). Corre 1 hora después de `monthlyDebtProcessor` para garantizar que los intereses ya fueron aplicados. Las variables del template incluyen monto total, detalle de origen (1 turno o suma) y lista de hasta 7 fechas con importes individuales.
- **`formatCurrency(amount)` en `messaging_utils.ts`:** helper para formateo consistente de montos en pesos argentinos (e.g. `15000` → `"$15.000"`).
- **`formatDebtDetail(appointments)` en `messaging_utils.ts`:** helper que genera `detalle_origen` (texto descriptivo) y `fechas` (lista de hasta 7 fechas, con truncado "... y N turnos anteriores") para el template `payment_reminder`.
- **`buildTwilioContentVariables` — case `payment_reminder`:** implementado con mapeo a 5 posiciones (`nombre_paciente`, `profesional_profesion`, `monto_total`, `detalle_origen`, `fechas`). Elimina el throw previo de "not yet implemented".
- **`utils/batch_utils.ts`:** clase `BatchWriter` extraída de `monthlyDebtProcessor` para reuso compartido.
- **`utils/firestore_utils.ts`:** función `getAllInChunks` extraída de `monthlyDebtProcessor` para reuso compartido.
- **Widget `ReminderHistoryItem`:** para `payment_reminder` ahora muestra `monto_total` de las variables del template (ya formateado como `"$15.000"`) en lugar de formatear `totalDebtAtThatTime`. Fallback a `totalDebtAtThatTime` si las variables no están disponibles.

### Modificado
- **`monthlyDebtProcessor`:** eliminado el bloque de encolado de recordatorios WhatsApp (`queueWhatsAppReminder`, líneas 175-259). La responsabilidad se delegó a `monthlyDebtNotifier`. La función ahora solo aplica intereses, actualiza deudas y guarda snapshots.
- **`utils/messaging_utils.ts`:** `payment_reminder` en `buildTwilioContentVariables` ya no lanza error; ahora retorna el mapa de posiciones correcto.

### Configuración requerida
- Setear `metadata/messaging.templates.payment_reminder.contentSid = "HX444ff8072252e471cf2a88981c168088"` en Firestore antes del deploy.

### Agregado
- **`enqueueUrgentAppointmentReminder()`** en `messaging_utils.ts`: nueva función utilitaria compartida que encapsula el fast-path de recordatorio urgente (<48h). Construye `nombre_profesional` (`profession + name`) y `concepto_turno` (con fallback `"Consulta"`), y delega a `enqueueMessage()`. Usada por `onAppointmentCreated` y `onAppointmentUpdated`.
- **`onAppointmentDeleted` cancela reminders encolados:** al borrar un turno, el trigger busca en `message_queue` documentos con `sourceAppointmentId == appointmentId` y `status == "queued"` y los marca como `"cancelled"`. Error no-fatal.
- **`onAppointmentUpdated` cancela y re-encola al cambiar fecha:** cuando `dateChanged == true`, cancela cualquier reminder `"queued"` del turno y, si la nueva fecha es futura y está dentro de 48h con proveedor premium activo, encola un nuevo reminder urgente vía `enqueueUrgentAppointmentReminder()`. Error no-fatal.
- **Estado `"cancelled"` en `QueuedMessage`:** nuevo estado terminal para mensajes cancelados por eliminación o cambio de fecha. Limpiado por `queueCleanup` después de 7 días junto con los demás estados terminales.

### Modificado
- **`messageOrchestrator`**: eliminado `runEscalationPass()` (rescheduling de `scheduledFor` en el orquestador causaba overflow). Reemplazado por "urgency elevation pass": batch-update de mensajes `queued` con `scheduledFor <= now` y `expiresAt <= now+24h` a `isUrgent=true, priority=10`. El orquestador nunca más modifica `scheduledFor`.
- **`checkDuplicate()`**: el filtro de estado cambia de `["queued", "processing", "sent"]` a `["processing", "sent"]`. Los mensajes `queued` ya no bloquean el encolado de nuevos mensajes. El campo de ventana temporal cambia de `createdAt` a `processedAt` (solo mensajes ya procesados dentro de 24h se consideran duplicados).
- **`queueCleanup`**: agrega `"cancelled"` al set de estados terminales con limpieza a 7 días. Agrega query para ítems `"processing"` con `processedAt < 48h ago` (stuck items). Reemplaza batch único por loop de chunks de máximo 500 operaciones para respetar el límite de Firestore.
- **`dailyScheduledActivator`**: `maxInstances` reducido de 10 a 1 (previene ejecuciones concurrentes del activador diario).
- **`onAppointmentCreated`**: el fast-path urgente ahora incluye `nombre_profesional` y `concepto_turno` en las variables del mensaje. Refactorizado para usar `enqueueUrgentAppointmentReminder()`.

### Agregado
- **Integración Twilio WhatsApp (Content API):** `sendWhatsAppReminder` ahora envía mensajes reales via Twilio usando Content SIDs. Incluye:
  - `TemplateNotConfiguredError`: error tipado cuando no hay Content SID configurado.
  - `resolveTemplateContentSid(providerId, messageType)`: resuelve el Content SID con prioridad proveedor > global (`metadata/messaging.templates`), con cache TTL 5 min por `providerId:messageType`.
  - `buildTwilioContentVariables(messageType, variables)`: mapea variables semánticas a posiciones numéricas del Content API de Twilio (`appointment_reminder`: pos 1=nombre_paciente, 2=fecha_turno, 4=hora_turno, 5=nombre_profesional, 6=concepto_turno).
  - `sendWhatsAppReminder` renovado: lee phone del paciente, resuelve template SID, envía via Twilio con retry (hasta 3 intentos, back-off cuadrático, retriable en 429/5xx/ECONNRESET). Razones de abort: `subscription_inactive`, `no_phone`, `template_not_configured`. Secrets requeridos: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM`.
- **Variables de proveedor en recordatorios de turno:** `appointmentReminderGenerator` ahora incluye `nombre_profesional` (formateado como `"${profession} ${name}"` o solo `name`) y `concepto_turno` (con fallback `"Consulta"`) en las variables del mensaje encoleado.

### Modificado
- `monthlyDebtProcessor`: la query de proveedores activos ahora filtra también por `plan == "premium"` (ademas de `subscriptionStatus == "active"`). Solo proveedores premium reciben el procesamiento mensual de deuda e intereses.

### Agregado
- **Sistema de mensajería WhatsApp con cola orquestada:** nuevo módulo de mensajería basado en una cola Firestore (`message_queue`) con procesamiento por prioridad, límite diario de conversaciones configurable (default 250), reserva de slots para mensajes urgentes (15 %) y ventana horaria Buenos Aires (normal 8-20 h, urgentes 6-20 h).
  - `messaging_utils.ts` — interfaces `QueuedMessage`, `MessagingConfig`, `MessagingCounter`, `EnqueueParams`; funciones `getMessagingConfig()`, `getOrResetCounter()`, `incrementCounter()`, `enqueueMessage()`, `checkDuplicate()`, `getBuenosAiresHour()`.
  - `messageOrchestrator` — cron cada 10 min que ejecuta el pass de escalamiento de recordatorios de turno (nivel 0→1→2/urgente) y promueve mensajes de `message_queue` a `providers/{id}/communications` respetando los límites configurados.
  - `appointmentReminderGenerator` — cron diario 07:00 que genera recordatorios de turno a +2 días para proveedores premium activos; idempotente via `sourceAppointmentId`.
  - `queueCleanup` — cron diario 03:00 que elimina documentos terminales de `message_queue` con más de 7 días de antigüedad.
- **Escalamiento progresivo de recordatorios de turno:** los recordatorios de turno escalan automáticamente: 48 h antes (nivel 0, normal) → 24 h antes (nivel 1, normal) → 3 h antes (nivel 2, urgente, priority=10).
- **Fast-path para turnos urgentes:** cuando `onAppointmentCreated` detecta un turno premium a menos de 48 h, encola directamente un recordatorio urgente (`isUrgent=true`, `escalationLevel=2`) sin esperar al cron generador.
- **Colección `message_queue`** (top-level) y documento de configuración `metadata/messaging` con reglas Firestore deny-all para el cliente y 6 índices compuestos nuevos.
- **Colección `metadata/messaging_counters`** con reglas deny-all para el cliente.
- 8 suites de tests (119 tests) para todos los nuevos módulos del sistema de mensajería.

### Modificado
- `monthlyDebtProcessor` — `queueWhatsAppReminder()` ahora escribe a `message_queue` vía `enqueueMessage()` en lugar de a `communications` directamente (messageType=`payment_reminder`, priority=30, expiresAt=+30 días).
- `triggerManualReminders` — reemplazado batch writes a `communications` por `enqueueMessage()` con priority=25.
- `sendWhatsAppReminder` — agrega `updateQueueItemStatus()`: al finalizar (sent/failed) actualiza el campo `status`, `processedAt` y `attempts` en el documento de `message_queue` correspondiente via `queueItemId`.
- `dailyRecurringProcessor` — lookahead aumentado de +1 a +2 días para garantizar que los turnos recurrentes existan cuando `appointmentReminderGenerator` corra a las 07:00.

### Agregado
- **Duración en turnos recurrentes:** nuevo campo opcional `defaultSessionDurationMinutes` en la entidad `RecurringAppointment`. Permite especificar la duración de sesión por regla recurrente. Las Cloud Functions `dailyRecurringProcessor` y `onCreateRecurringAppointment` ahora calculan `endTime = date + duración` al generar cada turno, con fallback al valor del profesional y luego a 45 min.
- Dropdown de duración en el modal "Turno Recurrente" (opciones 15–120 min; nulo = "Por defecto del profesional").

### Modificado
- Renombradas todas las etiquetas de UI "abono recurrente" / "Abono Recurrente" a "turno recurrente" / "Turno Recurrente" en el modal de creación, el drawer de acciones del home y el tooltip de pacientes.
- El texto informativo del modal de turnos recurrentes ya no menciona "regla de facturación" sino "turno recurrente".
- El placeholder del campo Concepto cambió de "Abono Ortodoncia" a "Consulta Ortodoncia".

### Corregido
- **Historial mensual de ingresos:** nueva sección "Historial de Ingresos" en la pantalla de Finanzas con gráfico de barras (`fl_chart`) que muestra hasta 12 meses anteriores. Los meses cerrados provienen de snapshots persistidos en Firestore; el mes en curso se muestra como barra provisional usando los datos de `monthlyRevenue` del dashboard en tiempo real.
- Nueva Cloud Function utilitaria `saveMonthlySnapshot(providerId)` en `utils/metrics_utils.ts` que persiste el revenue acumulado del mes en `providers/{providerId}/metrics/dashboard/monthly_snapshots/{YYYY-MM}` antes del reset.
- Nueva entidad `MonthlySnapshot` en Domain (`lib/domain/monthly_snapshot.dart`) con campos `id`, `month`, `year`, `monthIndex`, `totalRevenue` y `savedAt`.
- Nuevo método abstracto `watchMonthlySnapshots` en `ProviderRepository` con su implementación en la capa Data y provider Riverpod `monthlySnapshotsProvider`.
- Nueva regla de lectura en Firestore Security Rules para la subcolección `metrics/{metricId}/monthly_snapshots/{snapshotId}`.

### Corregido
- `monthlyDebtProcessor` ahora itera correctamente sobre **todos** los proveedores con suscripción `active` al momento de ejecutar el reset mensual, no solo aquellos que tenían intereses aplicables. Esto garantiza que el snapshot y el reset de `monthlyRevenue` se realizan para todos los proveedores sin excepción.

### Modificado
- El cron `monthlyDebtProcessor` se reprogramó del día 28 de cada mes al día 1, a las 15:00 UTC (12:00 hora Buenos Aires). Esto alinea el procesamiento mensual de deudas e intereses con el inicio del nuevo ciclo de facturación. Los textos informativos en las vistas de finanzas y home también se actualizaron para reflejar la nueva fecha de reseteo.
