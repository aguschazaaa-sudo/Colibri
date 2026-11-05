## Context

El sistema de mensajería tiene una arquitectura de cola sofisticada (productores → `message_queue` → `messageOrchestrator` → `communications` → `sendWhatsAppReminder`) pero el worker final llama a `mockSendWhatsApp()` — un `setTimeout(1000)` sin ninguna llamada HTTP real. El usuario ya tiene un sender de Twilio configurado y un WhatsApp Content Template aprobado para recordatorio de turno (`appointment_reminder`). El template de pago (`payment_reminder`) no existe aún en Twilio.

**Estado actual del worker `sendWhatsAppReminder`:**
- Escucha `onCreate` en `providers/{providerId}/communications/{commId}`
- Hace idempotency check redundante (ya existe en el orquestador)
- Formatea un mensaje hardcodeado de deuda (incorrecto para `appointment_reminder`)
- Llama `mockSendWhatsApp()` sin tocar ninguna API
- Guarda `messageId: "mock-msg-id-${Date.now()}"` como si hubiera enviado

**Bugs a corregir en esta implementación:**
1. Mock → Twilio real
2. Template único hardcodeado → lookup por tipo de mensaje + provider
3. Guard 24h duplicada → eliminar del worker, dejar solo en orquestador
4. `monthlyDebtProcessor` no filtra `plan === "premium"` para encolar reminders

## Goals / Non-Goals

**Goals:**
- Enviar WhatsApp reales via Twilio para `appointment_reminder`
- Sistema de template SIDs: global con override por provider, extensible a `payment_reminder`
- Retry hasta 3 intentos con backoff exponencial (1s, 4s, 9s)
- Skip graceful si paciente sin teléfono (`aborted` + `reason: "no_phone"`)
- Secrets via Firebase Secret Manager, nunca en código ni env vars de función
- Eliminar guard duplicada del worker
- Fix filtro premium en `monthlyDebtProcessor`

**Non-Goals:**
- Implementar `payment_reminder` real (queda como TODO; la infraestructura de templates sí se construye)
- Webhooks de delivery status de Twilio (status updates como `delivered`, `read`)
- UI en Flutter para configurar templates por provider (se hace directo en Firestore por ahora)
- Internacionalización de templates
- Soporte multi-número (un WHATSAPP_FROM por tenant)

## Decisions

### D1 — Twilio SDK vs. HTTP directo

**Decisión:** Usar el paquete oficial `twilio` npm.

**Alternativas consideradas:**
- HTTP directo con `axios`: menos dependencias, pero requiere manejar auth, serialización y errores manualmente.
- `twilio` SDK: client oficial, manejo de errores tipado (`TwilioRestException`), abstracción de versión de API. Ganador claro.

**Implicación:** `npm install twilio` en `firebase/functions`.

---

### D2 — Dónde resolver el template SID

**Decisión:** Función utilitaria `resolveTemplateContentSid(providerId, messageType)` en `messaging_utils.ts`.

```
resolveTemplateContentSid(providerId, messageType):
  1. Lee providers/{providerId}.messageTemplates[messageType]  → si existe, retornar
  2. Lee metadata/messaging.templates[messageType].contentSid  → si existe, retornar
  3. throw TemplateNotConfiguredError                          → marcar como aborted
```

**Segundo utilitario:** `buildTwilioContentVariables(messageType, variables)` mapea nombres semánticos a posiciones numéricas requeridas por la Twilio Content API:

```
appointment_reminder (template HX5434632a7b72b2d9adacd23f73a35767):
  "1" → nombre_paciente
  "2" → fecha_turno
  "4" → hora_turno      ({{3}} no existe en el template — se omite)
  "5" → nombre_profesional  (= "${profession} ${name}" si profession existe, si no solo name)
  "6" → concepto_turno

payment_reminder: TODO — lanzar error hasta que el template esté aprobado
```

**Implicación en el productor:** `appointmentReminderGenerator` debe incluir `nombre_profesional` (del cache de providers ya existente) y `concepto_turno` (del appointment doc) en las variables del queue item.

**Alternativas consideradas:**
- Guardar SID como Secret: no es un secret (no es credencial), es configuración. Firestore es el lugar correcto.
- SID hardcodeado como env var: no permite override por provider ni cambio en runtime.

**Cache:** dado que `maxInstances: 10` y el orquestador emite en ráfagas, cachear el template global en memoria de la función (warm instance) por hasta 5 minutos reduciría lecturas a Firestore. Se implementa con un mapa `Map<string, {sid, expiresAt}>`.

---

### D3 — Retry strategy en el worker

**Decisión:** Backoff exponencial dentro del mismo invocation: hasta 3 intentos, esperas de `attempt² × 1000ms` (1s, 4s, 9s). Si todos fallan: `status: "failed"`, `lastError`, `attempts` incrementado.

**Por qué no Cloud Tasks o re-enqueue:** la función ya tiene `maxInstances: 10`. El backoff dentro del invocation es suficiente para errores transitorios de Twilio (rate limit 429, timeout 5xx). Re-enqueue añade complejidad desproporcionada para un SaaS con 250 mensajes/día.

**Límite absoluto:** el campo `attempts` ya existe en `QueuedMessage`. `queueCleanup` elimina `failed` con `attempts >= 3` después de 7 días — sin cambios necesarios.

---

### D4 — Eliminar guard duplicada del worker

**Decisión:** Eliminar completamente el bloque de idempotency de `sendWhatsAppReminder`. La única fuente de verdad es `checkDuplicate()` en `messageOrchestrator`, que ya ejecuta antes de mover el item a `processing`.

**Razonamiento:** el trigger `onCreate` en `communications` no puede dispararse dos veces por el mismo documento (Firestore garantía). El único escenario de duplicado real ya está cubierto en el orquestador. Mantener ambas queries es overhead sin beneficio de seguridad real.

**Salvaguarda que se mantiene:** el guard de `subscriptionStatus !== "active"` sí se conserva en el worker (segunda línea de defensa).

---

### D5 — Manejo de paciente sin teléfono

**Decisión:** En `sendWhatsAppReminder`, si `patient.phone` es null/vacío:
- Actualizar communication a `status: "aborted"`, `reason: "no_phone"`
- Actualizar queue item a `status: "failed"`, `lastError: "no_phone"`
- Log warning sin PII (solo `patientId`)
- No lanzar excepción (no reintento — el retry no resolvería la falta de teléfono)

**Por qué no skip en el orquestador:** el orquestador no tiene el teléfono disponible sin una lectura extra de Firestore por cada mensaje. Es más eficiente detectarlo en el worker que ya lee el paciente de todas formas.

---

### D6 — Secrets: Firebase Secret Manager

**Decisión:** Los tres secrets (`TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM`) se almacenan en Firebase Secret Manager y se acceden via `runWith({ secrets: [...] })`.

```typescript
export const sendWhatsAppReminder = functions
  .runWith({
    maxInstances: 10,
    secrets: ["TWILIO_ACCOUNT_SID", "TWILIO_AUTH_TOKEN", "TWILIO_WHATSAPP_FROM"],
  })
  .firestore.document("providers/{providerId}/communications/{commId}")
  .onCreate(...)
```

**Implicación de deploy:** los secrets deben existir en Secret Manager antes del primer deploy. Documentado en tasks.md.

---

### D7 — Fix `monthlyDebtProcessor` — filtro premium

**Decisión:** Al construir `activeProviderIds`, filtrar `plan === "premium"` además de `subscriptionStatus === "active"`. Alinea con `appointmentReminderGenerator`.

```typescript
// Antes
.where("subscriptionStatus", "==", "active")

// Después
.where("subscriptionStatus", "==", "active")
.where("plan", "==", "premium")
```

**Justificación:** según reglas de negocio, los mensajes automáticos son feature premium. El procesador mensual era el único lugar donde esta política no se aplicaba.

## Risks / Trade-offs

**[Twilio credentials en Secret Manager → cold start más lento]** → Aceptado. El overhead es ~200ms en cold start. Con `maxInstances: 10` y el volumen actual (≤250/día) esto es despreciable.

**[Template SID no configurado → mensajes silenciosamente abortados]** → Mitigación: loguear error claro con `providerId` y `messageType`. En el futuro se puede añadir alerta en Firestore o email al provider.

**[Twilio rate limits (429)]** → Mitigación: el backoff de hasta 9s cubre la mayoría de rate limit windows de Twilio (que son por segundo). Con 250 msgs/día y el orquestador corriendo cada 10 min, nunca se llegará a límites reales.

**[Número de teléfono en formato incorrecto]** → Twilio retorna error descriptivo. El worker lo captura, guarda `lastError` con el mensaje de Twilio, y marca `failed`. No hay validación previa de formato E.164 — se delega a Twilio por ahora.

**[`payment_reminder` queda sin template real]** → El orquestador puede encolar `payment_reminder` pero el worker lo marcará `aborted` con `reason: "template_not_configured"` hasta que el template se apruebe en Twilio y se configure el SID. Esto es comportamiento explícito y documentado.

## Migration Plan

**Orden de deploy:**
1. Crear secrets en Firebase Secret Manager (`TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM`)
2. Configurar `metadata/messaging.templates.appointment_reminder.contentSid` en Firestore (SID del template aprobado)
3. Deploy de functions (`firebase deploy --only functions`)
4. Verificar en logs que el primer `sendWhatsAppReminder` real llega a Twilio
5. Monitorear `message_queue` y `communications` para confirmar flujo completo

**Rollback:**
- Revertir el deploy de functions al commit anterior restaura el mock instantáneamente
- Los secrets en Secret Manager no requieren rollback (solo se usan si la función los referencia)
- Los documentos en Firestore (`metadata/messaging.templates`) pueden eliminarse sin efecto si se hace rollback de la función

## Open Questions

- ¿El Content SID del template de recordatorio de turno ya está aprobado en el Business Account de Twilio del usuario? → Asumir que sí (el usuario lo confirmó).
- ¿Los números de teléfono en `patients.phone` están en formato E.164 (`+549...`)? → Asumir que sí; documentar en tasks como prerequisito a verificar.
- ¿Se quiere un override de número `WHATSAPP_FROM` por provider (multi-número)? → **Fuera de scope** para este cambio.
