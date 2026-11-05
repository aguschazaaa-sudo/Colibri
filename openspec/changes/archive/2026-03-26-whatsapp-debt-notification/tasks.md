## 1. Refactor — extraer utilidades compartidas

- [x] 1.1 Extraer `BatchWriter` de `monthlyDebtProcessor.ts` a `utils/batch_utils.ts`
- [x] 1.2 Extraer `getAllInChunks` de `monthlyDebtProcessor.ts` a `utils/firestore_utils.ts`
- [x] 1.3 Actualizar imports en `monthlyDebtProcessor.ts` para usar las utilidades extraídas
- [x] 1.4 Verificar que `monthlyDebtProcessor` sigue funcionando igual tras el refactor

## 2. Template de payment_reminder en messaging_utils

- [x] 2.1 Implementar el case `payment_reminder` en `buildTwilioContentVariables()` con las 5 variables posicionales (nombre_paciente, profesional|profesión, monto_total, detalle_origen, fechas)
- [x] 2.2 Agregar helper `formatDebtDetail()` que genera {{4}} (texto origen) y {{5}} (lista de fechas con montos) con truncado a 7 fechas
- [x] 2.3 Agregar helper `formatCurrency()` para formateo consistente de montos en pesos argentinos

## 3. Cron monthlyDebtNotifier

- [x] 3.1 Crear `firebase/functions/src/cron/monthlyDebtNotifier.ts` con cron schedule `0 16 1 * *` (1ro de cada mes, 16:00 Buenos Aires — 1h después del debtProcessor)
- [x] 3.2 Implementar query de providers elegibles: `subscriptionStatus == "active"` AND `plan` in `["basic", "premium", "trial"]`
- [x] 3.3 Implementar lógica por provider: query pacientes con `totalDebt > 0`, luego por cada paciente query appointments `status: "unpaid"` ordenados por fecha desc
- [x] 3.4 Implementar validación cruzada: comparar suma de appointments vs `patient.totalDebt`, loguear warning si difieren (sin PII)
- [x] 3.5 Construir variables del template por paciente: nombre, profesional|profesión, monto total, detalle origen, fechas (usando helpers de 2.2/2.3)
- [x] 3.6 Encolar mensajes via `enqueueMessage()` con `priority: 30`, `isUrgent: false`, `expiresAt: scheduledFor + 10 días`
- [x] 3.7 Usar `BatchWriter` importado de `utils/batch_utils.ts`
- [x] 3.8 Exportar en `cron/index.ts`

## 4. Limpiar monthlyDebtProcessor

- [x] 4.1 Remover `queueWhatsAppReminder()`, el bloque de encolado (líneas 175-207), y el import de `enqueueMessage`
- [x] 4.2 Remover `getAllInChunks` (ya extraída a utils)

## 5. Configuración en Firestore

- [x] 5.1 Setear `metadata/messaging.templates.payment_reminder.contentSid` = `HX444ff8072252e471cf2a88981c168088` en Firestore
- [x] 5.2 Documentar que para actualizar el template de turno, solo hay que cambiar `metadata/messaging.templates.appointment_reminder.contentSid`

## 6. Frontend — historial de comunicaciones

- [x] 6.1 Actualizar el widget de historial de comunicaciones para renderizar diferenciado por `messageType`: mostrar detalle de deuda (monto, fechas) para `payment_reminder`
- [x] 6.2 Manejar `messageType` null o desconocido con render genérico sin romper UI

## 7. Tests

- [x] 7.1 Tests unitarios para `formatDebtDetail()`: 1 turno, múltiples turnos, >7 turnos con truncado
- [x] 7.2 Tests unitarios para `buildTwilioContentVariables()` case `payment_reminder`
- [x] 7.3 Tests para `monthlyDebtNotifier`: provider activo con deuda, provider inactivo (skip), paciente sin deuda (skip), discrepancia totalDebt, >7 turnos
- [x] 7.4 Tests para `monthlyDebtProcessor` post-cleanup: verificar que ya no encola mensajes
- [x] 7.5 Tests de widget frontend: render de payment_reminder, render de appointment_reminder, render de messageType desconocido
