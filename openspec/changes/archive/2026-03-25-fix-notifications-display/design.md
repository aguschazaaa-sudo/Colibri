## Context

La colección `providers/{providerId}/communications` ya almacena los campos `messageType` (`"appointment_reminder"` | `"payment_reminder"`) y `variables` (mapa con `fecha_turno`, `hora_turno`, `nombre_profesional`, `concepto_turno` para turnos; `monto_total` para deudas). Estos campos son escritos por el `messageOrchestrator` antes de crear el documento. Flutter no los lee actualmente.

El stat card "Total del Mes" filtra por mes calendario pero no por `status`, por lo que incluye documentos en estado `pending`, `aborted`, `failed` junto con los `sent`.

## Goals / Non-Goals

**Goals:**
- Exponer `messageType` y `variables` en la entidad `CommunicationLog` y su modelo Firestore.
- Mostrar en `ReminderHistoryItem` el tipo de notificación y un resumen breve del contenido.
- Corregir `remindersStats` para contar solo `status == "sent"`.

**Non-Goals:**
- Cambiar Cloud Functions (los datos ya están en Firestore).
- Cambiar la estructura del documento en Firestore.
- Soporte para tipos de notificación futuros más allá de los dos actuales.

## Decisions

### D1 — Agregar `messageType` y `variables` a `CommunicationLog`

**Decisión:** Agregar `String? messageType` y `Map<String, String>? variables` a la entidad Freezed y al modelo Firestore.

**Rationale:** Ambos campos ya existen en Firestore. Exponerlos en el dominio es suficiente para cubrir el display sin escritura adicional. Hacer el campo opcional (`?`) garantiza compatibilidad con documentos históricos que no los tengan.

**Alternativa descartada:** Agregar un `String? contentSummary` pre-computado en Firestore. Requeriría modificar Cloud Functions y lógica adicional en el servidor para algo que puede resolverse puramente en el cliente con datos disponibles.

### D2 — Derivar el snippet de contenido en el widget, no en el Provider

**Decisión:** La lógica de formateo del snippet (`"Turno: 28/03 a las 10:00"` / `"Deuda: $3.500"`) vive en `ReminderHistoryItem` como helpers privados, no en el Provider.

**Rationale:** Es lógica de presentación pura (formato de texto para pantalla). El Provider no necesita conocer el formato visual. El widget ya tiene acceso a toda la información necesaria.

**Alternativa descartada:** Computar un `displayLabel` en el Provider y pasarlo al widget. Agrega un ViewModel innecesario para un cambio de alcance pequeño.

### D3 — Filtrar `totalThisMonth` por `status == "sent"` en el Provider

**Decisión:** Agregar `.where((l) => l.status == 'sent')` al filtro existente en `remindersStats`.

**Rationale:** El stat card dice "Envíos exitosos" pero contaba todos los estados. El fix es trivial y localizado.

**Valores considerados como "exitosos":** Solo `"sent"`. Los estados `"pending"` (en tránsito), `"aborted"` (abort decidido) y `"failed"` (error transitorio) no deben contar.

## Risks / Trade-offs

- **[Documentos sin `messageType`]** → Los documentos creados antes de que `messageOrchestrator` escribiera ese campo mostrarán el fallback "Recordatorio" en el widget. Aceptable dado que el campo se trata como opcional.
- **[`variables` con claves distintas]** → Si en el futuro se cambia el nombre de las variables en las Cloud Functions, el widget mostraría vacío en el snippet. Mitigación: usar fallbacks nulos (`variables?['fecha_turno'] ?? ''`).
- **[Cast de variables]** → Firestore devuelve `Map<String, dynamic>`, hay que castear a `Map<String, String>`. Valores no-string deberán convertirse con `.toString()`.

## Migration Plan

1. Actualizar `CommunicationLog` (dominio) — agregar `messageType` y `variables`.
2. Actualizar `CommunicationLogModel` (datos) — leer los campos de Firestore.
3. Actualizar `ReminderHistoryItem` (presentación) — mostrar tipo + snippet.
4. Actualizar `remindersStats` (presentación) — filtrar por `status == 'sent'`.

No requiere deploy ni migración de datos. Los cambios son backward-compatible. Sin rollback especial.

## Open Questions

Ninguna — todos los datos necesarios ya están en Firestore.
