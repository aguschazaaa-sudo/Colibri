# Módulo utils

## Propósito

Contiene funciones auxiliares y utilidades compartidas por las Cloud Functions del proyecto. Agrupa lógica transversal para evitar duplicación: cálculo de fechas e intereses, manipulación de métricas del dashboard y, desde la feature de mensajería, toda la infraestructura de la cola de mensajes WhatsApp.

## Archivos principales

- `dateAndInterest.ts` — Constante `MONTHLY_INTEREST_RATE`, función `calculateInterest()` y helpers de formateo de fechas (ej. `toDateKey()`).
- `metrics_utils.ts` — Helpers para actualizar métricas del dashboard del proveedor: `incrementDashboardMetrics()`, `resetMonthlyRevenue()`, `saveMonthlySnapshot()`.
- `payment_distribution.ts` — Lógica de distribución FIFO de pagos entre turnos impagos de un paciente.
- `recurring_utils.ts` — Utilidades para la generación de turnos recurrentes (cálculo de próxima fecha, validación de días no laborables).
- `messaging_utils.ts` — Interfaces y funciones del sistema de mensajería WhatsApp: definición del esquema de `message_queue`, configuración de límites, contador diario, función de encolado, resolución de templates Twilio y construcción de variables de Content API. Incluye helpers de formateo: `formatCurrency()` y `formatDebtDetail()`.
- `batch_utils.ts` — Clase `BatchWriter` para escrituras Firestore en lotes auto-paginados (threshold: 450 ops). Extraída de `monthlyDebtProcessor` para reuso en múltiples cron jobs.
- `firestore_utils.ts` — Función `getAllInChunks()` para lecturas paralelas de múltiples documentos en chunks configurables (hasta 5 workers concurrentes). Extraída de `monthlyDebtProcessor`.

## Interfaces exportadas por `messaging_utils.ts`

### `MessagingConfig`
Configuración del sistema de mensajería leída desde `metadata/messaging`.

| Campo | Tipo | Descripción |
|---|---|---|
| `dailyConversationLimit` | `number` | Máximo de conversaciones WhatsApp por ventana de 24 h. Default: 250. |
| `urgentReservePercentage` | `number` | Fracción del límite reservado para mensajes urgentes. Default: 0.15. |
| `sendWindowStart` | `number` | Hora de inicio de la ventana normal (hora local Buenos Aires). Default: 8. |
| `sendWindowEnd` | `number` | Hora de fin de la ventana (ambos tipos). Default: 20. |
| `urgentWindowStart` | `number` | Hora de inicio de la ventana solo para urgentes. Default: 6. |
| `enabled` | `boolean` | Kill-switch global del orquestador. |

### `QueuedMessage`
Documento de la colección `message_queue`. Representa un mensaje en cualquier estado de su ciclo de vida.

| Campo | Tipo | Descripción |
|---|---|---|
| `providerId` | `string` | Identificador del proveedor (multi-tenancy). |
| `patientId` | `string` | Identificador del paciente. |
| `patientName` | `string` | Nombre del paciente para personalización del mensaje. |
| `messageType` | `"payment_reminder" \| "appointment_reminder"` | Tipo de mensaje. |
| `variables` | `Record<string, unknown>` | Variables de plantilla (`nombre_paciente`, `monto_total`, `fecha_turno`, `hora_turno`). |
| `priority` | `number` | Prioridad de envío: 10=urgente, 20=turno normal, 25=manual, 30=auto-pago. |
| `isUrgent` | `boolean` | Si ocupa el cupo reservado para urgentes. |
| `status` | `string` | Estado del ciclo de vida: `queued`, `processing`, `sent`, `failed`, `expired`, `duplicate`. |
| `scheduledFor` | `Timestamp` | No enviar antes de este momento. |
| `expiresAt` | `Timestamp` | Si llega a este momento sin enviarse, pasa a `expired`. |
| `escalationLevel` | `0 \| 1 \| 2` | Solo en `appointment_reminder`. Nivel de escalamiento alcanzado. |
| `sourceAppointmentId` | `string?` | ID del turno origen. Usado para idempotencia. |
| `sourceRecurringId` | `string?` | ID de la regla recurrente origen. |
| `createdAt` | `Timestamp` | Timestamp de creación. |
| `processedAt` | `Timestamp?` | Timestamp en que el orquestador promovió el mensaje. |
| `attempts` | `number` | Cantidad de intentos de envío. Incrementado por `sendWhatsAppReminder` en cada fallo. |
| `lastError` | `string?` | Último mensaje de error en caso de fallo. |

### `MessagingCounter`
Estado del contador de conversaciones diarias. Almacenado en `metadata/messaging_counters/current/current`.

| Campo | Tipo | Descripción |
|---|---|---|
| `windowStart` | `Timestamp` | Inicio de la ventana de 24 h actual. |
| `sentCount` | `number` | Mensajes enviados en la ventana. |
| `urgentSentCount` | `number` | Mensajes urgentes enviados en la ventana. |
| `lastUpdated` | `Timestamp` | Última actualización del contador. |

### `EnqueueParams`
Parámetros de entrada de la función `enqueueMessage()`. Mismos campos que `QueuedMessage` excepto los auto-generados (`status`, `createdAt`, `attempts`). Acepta `Date` nativo en lugar de `Timestamp` para `scheduledFor` y `expiresAt`.

## Funciones exportadas por `messaging_utils.ts`

### `getMessagingConfig(): Promise<MessagingConfig>`
Lee el documento `metadata/messaging` de Firestore y devuelve la configuración del sistema de mensajería. Si el documento no existe, devuelve los valores por defecto (250 conversaciones, 15% reserva urgente, ventana 8-20, urgentes 6-20, habilitado).

### `getOrResetCounter(): Promise<MessagingCounter>`
Obtiene el contador diario actual dentro de una transacción Firestore. Si el contador existe y la ventana de 24 h no ha expirado, devuelve los valores actuales. Si la ventana expiró o el contador no existe, lo resetea a cero y establece una nueva `windowStart`.

### `incrementCounter(isUrgent: boolean): Promise<void>`
Incrementa atómicamente `sentCount` en el contador diario. Si `isUrgent` es `true`, también incrementa `urgentSentCount`. Usa `FieldValue.increment` para evitar conflictos de concurrencia.

### `enqueueMessage(params: EnqueueParams): Promise<string>`
Crea un documento en la colección `message_queue` con `status: "queued"` y `attempts: 0`. Valida que `messageType` sea uno de los valores permitidos antes de escribir. Devuelve el ID del documento creado.

### `checkDuplicate(patientId: string, messageType: string): Promise<boolean>`
Verifica si existe un mensaje activo (`queued`, `processing` o `sent`) del mismo tipo para el mismo paciente en las últimas 24 h. Devuelve `true` si hay duplicado (el mensaje no debe enviarse).

### `getBuenosAiresHour(): number`
Devuelve la hora actual en formato 24 h según la zona horaria `America/Argentina/Buenos_Aires`. Utilizado por el orquestador para verificar la ventana de envío.

### `TemplateNotConfiguredError`
Error tipado lanzado por `resolveTemplateContentSid` cuando no existe Content SID configurado para el tipo de mensaje, ni a nivel de proveedor ni a nivel global.

Constructor: `new TemplateNotConfiguredError(providerId: string, messageType: string)`

### `resolveTemplateContentSid(providerId: string, messageType: MessageType): Promise<string>`
Resuelve el Content SID de Twilio para el tipo de mensaje. Orden de resolución:
1. Campo `messageTemplates[messageType]` en el documento `providers/{providerId}` (override por proveedor, sin cache).
2. Campo `templates[messageType].contentSid` en `metadata/messaging` (global, con cache TTL 5 min, clave `providerId:messageType`).
3. Lanza `TemplateNotConfiguredError` si no encuentra ninguno.

### `buildTwilioContentVariables(messageType: MessageType, variables: Record<string, unknown>): Record<string, string>`
Mapea variables semánticas a las posiciones numéricas requeridas por el Content API de Twilio.

Mapeo para `appointment_reminder`:
| Posición | Variable semántica |
|---|---|
| `"1"` | `nombre_paciente` |
| `"2"` | `fecha_turno` |
| `"4"` | `hora_turno` |
| `"5"` | `nombre_profesional` |
| `"6"` | `concepto_turno` |

Mapeo para `payment_reminder`:
| Posición | Variable semántica |
|---|---|
| `"1"` | `nombre_paciente` |
| `"2"` | `profesional_profesion` |
| `"3"` | `monto_total` |
| `"4"` | `detalle_origen` |
| `"5"` | `fechas` |

### `formatCurrency(amount: number): string`
Formatea un monto en pesos argentinos usando `Intl.NumberFormat` con locale `es-AR` y moneda `ARS`. Ej: `15000` → `"$15.000"`. Sin decimales.

### `formatDebtDetail(appointments: AppointmentDebtItem[]): { detalleOrigen: string; fechas: string }`
Genera las variables `{{4}}` (`detalle_origen`) y `{{5}}` (`fechas`) del template `payment_reminder`.

- Si hay 1 turno: `detalleOrigen = "$5.000 del 15/03"` (monto del único turno + fecha DD/MM en hora Buenos Aires).
- Si hay múltiples: `detalleOrigen = "la suma de N turnos pendientes"`.
- `fechas`: lista de hasta 7 fechas más recientes en formato `"- DD/MM/YYYY: $X.XXX"`, separadas por `\n`. Si hay más de 7, agrega una línea `"... y N turnos anteriores"`.
- Los turnos se ordenan por fecha descendente (más reciente primero).
- Si el array está vacío, devuelve `{ detalleOrigen: "", fechas: "" }`.

## Dependencias

- `firebase-admin` — acceso a Firestore
- `firebase-functions` — logging

## Notas

- `getOrResetCounter` usa una transacción Firestore para garantizar consistencia cuando múltiples invocaciones del orquestador podrían leer el contador simultáneamente (aunque `maxInstances: 1` mitiga este riesgo en producción).
- El documento de configuración `metadata/messaging` debe crearse manualmente como seed antes del primer deploy. Si no existe, el sistema funciona con los valores por defecto.
- `enqueueMessage` es la única función que escribe en `message_queue`; todos los productores de mensajes (cron jobs, triggers y callables) deben pasar por ella.
- El campo `metadata/messaging.templates` debe incluir una clave por messageType con `{ contentSid: "HX..." }` para que `resolveTemplateContentSid` encuentre el SID global.

### Actualizar el Content SID de un template

Los Content SIDs de Twilio se almacenan en `metadata/messaging` (Firestore). Para cambiar el template de un tipo de mensaje, solo hay que actualizar el campo correspondiente:

| Tipo de mensaje | Campo en Firestore | SID actual |
|---|---|---|
| `appointment_reminder` | `templates.appointment_reminder.contentSid` | `HX5434632a7b72b2d9adacd23f73a35767` |
| `payment_reminder` | `templates.payment_reminder.contentSid` | `HX444ff8072252e471cf2a88981c168088` |

**Para actualizar el template de recordatorio de turno (`appointment_reminder`):**
```
metadata/messaging
  └─ templates.appointment_reminder.contentSid = "HXnuevo_sid_aqui"
```

**Para actualizar el template de recordatorio de deuda (`payment_reminder`):**
```
metadata/messaging
  └─ templates.payment_reminder.contentSid = "HXnuevo_sid_aqui"
```

El campo se puede actualizar via Firebase CLI:
```bash
# Ejemplo: actualizar el SID del recordatorio de turno
firebase firestore:set metadata/messaging --merge --data '{"templates":{"appointment_reminder":{"contentSid":"HXnuevo_sid"}}}'
```

O via Firebase Console en `Firestore > metadata > messaging > templates > appointment_reminder > contentSid`.

**Override por proveedor:** si un proveedor tiene `messageTemplates.appointment_reminder` (o `payment_reminder`) en su documento `providers/{providerId}`, ese valor tiene prioridad sobre el global. Ver `resolveTemplateContentSid` para el orden de resolución completo.
- Los secrets `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` y `TWILIO_WHATSAPP_FROM` deben configurarse en Firebase Secrets Manager antes del deploy de `sendWhatsAppReminder`.
