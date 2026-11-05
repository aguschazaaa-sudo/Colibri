## Context

El sistema de mensajería tiene tres capas:
1. **`appointmentReminderGenerator`** (cron 07:00): encola turnos del día +2 con `scheduledFor = appt - 48h`, `escalationLevel: 0`.
2. **`messageOrchestrator`** (cada 10 min): despacha mensajes de `message_queue` respetando el límite diario de 250 conversaciones y la ventana horaria (normal: 8–20h, urgente: 6–20h).
3. **`sendWhatsAppReminder`** (Firestore trigger): envía vía Twilio cuando se crea un doc en `communications`.

El problema actual: el orquestador ejecuta `runEscalationPass()` **antes** del despacho. Este pass mueve mensajes `level=0` vencidos a `scheduledFor = appt - 24h` (level=1), y luego a `appt - 3h` (level=2, urgente). Como consecuencia, los mensajes nunca se despachan en su ventana original de 48h — siempre quedan rescheduleados al futuro.

La intención del diseñador era usar el límite de 250 mensajes como presión de carga distribuida: enviar a 48h cuando hay capacidad, y si no hay, el sobrante llega con más urgencia al día siguiente. La escalation actual invierte esta lógica: no envía nada hasta 3h antes.

## Goals / Non-Goals

**Goals:**
- Los mensajes se envían en la ventana de 48h cuando hay slots disponibles.
- Si el límite diario se agota, los mensajes que no se enviaron permanecen en cola y son procesados en el siguiente ciclo del orquestador.
- Cuando un mensaje no enviado llega a menos de 24h del turno, se eleva a urgente automáticamente para aprovechar la ventana extendida (6–20h) y la reserva de urgentes.
- La lógica de overflow es simple, observable y fácil de razonar.

**Non-Goals:**
- No se mantiene la cascada multi-nivel (level 0 → 1 → 2). Se elimina por completo.
- No se implementa reintento automático de mensajes fallidos (ya existe `failed` status).
- No se cambia el schema de Firestore ni la interfaz con Flutter.

## Decisions

### Decisión 1: Eliminar `runEscalationPass()` completamente

**Alternativa rechazada:** Corregir la condición de la escalation pass para que solo escale mensajes que *no* pudieron enviarse por falta de slots.

**Rationale:** La escalation pass es inherentemente racy — corre antes del despacho y no sabe si el mensaje va a poder enviarse en este ciclo. Cualquier "corrección" requiere lookahead o state adicional. La lógica más simple y correcta es: despachar el mensaje cuando `scheduledFor <= now` y hay slots; si no hay slots, el mensaje queda en cola y se reintentará en 10 minutos. Eventualmente llegará a la zona de urgencia por el paso del tiempo, sin necesitar un pass separado.

### Decisión 2: Urgencia por proximidad — inline en el orquestador

En lugar de un pass separado que reschedula, el orquestador eleva `isUrgent = true` en batch antes del despacho para todos los mensajes que cumplan:
- `status == "queued"`
- `scheduledFor <= now` (ya vencidos, no enviados por overflow)
- `expiresAt - now < 24h` (turno a menos de 24h)

Esto es un `update` batch en Firestore, no un reschedule. El mensaje sigue con su `scheduledFor` original (ya en el pasado), por lo que aparecerá inmediatamente en la query de despacho con flag urgente.

**Alternativa rechazada:** Elevar urgencia al momento de `enqueueMessage` si el turno está cerca.
**Rationale:** El generador ya marca urgentes los turnos creados con < 48h de anticipación. La elevación de urgencia por overflow es dinámica — depende de cuándo el orquestador procesa, no de cuándo se creó el turno.

### Decisión 3: Prioridad de despacho — sin cambios

El query existente ya ordena por `scheduledFor ASC`, `priority ASC`, `createdAt ASC`. Los mensajes más viejos y más urgentes se despachan primero. No se requiere cambiar el orden.

### Decisión 4: `escalationLevel` se depreca silenciosamente

El campo existe en Firestore pero ya no se modifica. No se migran documentos existentes. El campo puede ignorarse o eliminarse en una limpieza futura.

### Decisión 5: `checkDuplicate` — status filter y ventana temporal

**Problema A — self-identify:** `checkDuplicate` incluye `"queued"` en el filtro de status. Un mensaje recién encolado se encuentra a sí mismo y es descartado como duplicado antes de enviarse.

**Fix:** Cambiar a `["processing", "sent"]`. Un mensaje `queued` no es "ya enviado" — no debe contar como duplicado.

**Problema B — ventana anclada a `createdAt`:** La ventana de 24h usa `createdAt` (cuando se encoló) en vez de `processedAt` (cuando se intentó enviar). Un mensaje que pasó horas en cola por overflow "consume" tiempo de la ventana de protección del paciente sin haberle mandado nada.

**Fix:** Cambiar a `processedAt >= 24h ago`. `processedAt` existe en todos los docs con status `"processing"` o `"sent"` — lo setea el orquestador en el paso de despacho.

**Alternativa rechazada:** Consultar la colección `communications` en vez de `message_queue`.
**Rationale:** `message_queue` ya tiene los índices necesarios. Agregar una query a `communications` duplica la lectura sin beneficio adicional dado que `processedAt` en `message_queue` es equivalente a `sentAt` en `communications`.

### Decisión 6: `queueCleanup` — chunked batch

El código actual puede acumular hasta 1000 documentos (500 de cada query) en un solo `WriteBatch`. Firestore limita los batches a 500 operaciones.

**Fix:** Iterar en chunks de 500 y hacer `commit()` por chunk. La lógica de qué se borra no cambia.

### Decisión 7: `dailyScheduledActivator` — `maxInstances: 1`

El activador usa `maxInstances: 10` pero tiene concurrencia interna con 10 workers JS. Si una ejecución tarda más de 1 hora, Cloud Functions puede lanzar una segunda instancia que procesa los mismos turnos y dispara `onAppointmentUpdated` dos veces (deuda duplicada).

**Fix:** `maxInstances: 1`. Los 10 workers internos son suficientes para la concurrencia deseada dentro de una sola instancia.

### Decisión 8: `onAppointmentCreated` — variables faltantes en recordatorio urgente

Cuando un turno se crea con < 48h de anticipación, el trigger encola un recordatorio urgente con `scheduledFor = now`. Pero omite `nombre_profesional` y `concepto_turno` — `buildTwilioContentVariables` los completa con `""`, enviando el mensaje con placeholders vacíos.

**Fix:** Leer el provider doc (ya se lee para verificar `isPremiumActive`) y extraer `name` + `profession` para `nombre_profesional`. Leer `appointmentData.concept` para `concepto_turno` (default `"Consulta"` si está vacío), igual que hace `appointmentReminderGenerator`.

**Sin cambios en schema** — los datos ya existen en los documentos que el trigger ya lee.

### Decisión 9: `onAppointmentDeleted` — cancelar reminder encolado

Cuando un turno es eliminado, el item correspondiente en `message_queue` con `sourceAppointmentId == appointmentId` y `status == "queued"` debe marcarse `"cancelled"` para que el orquestador lo ignore.

**Por qué `"cancelled"` y no `"expired"`:** `"expired"` tiene semántica temporal (el turno llegó sin enviarse). `"cancelled"` es una acción explícita del provider. Ambos son terminales y `queueCleanup` puede limpiarlos. Agregar `"cancelled"` al set de statuses terminales en `queueCleanup` es un cambio de una línea.

**Scope de la query:** Solo cancela items `"queued"` — items en `"processing"` ya fueron despachados al worker; cancelarlos en `message_queue` no previene el envío a Twilio. Si el turno se elimina mientras el worker está en vuelo, el mensaje se enviará de todas formas (ventana de race muy estrecha, aceptable).

### Decisión 10: `queueCleanup` — limpiar items `"processing"` atascados

Items que quedan en `"processing"` indefinidamente indican que `sendWhatsAppReminder` falló sin actualizar el status. El cleanup debe eliminarlos después de 48h desde `processedAt`.

**Umbral de 48h:** Suficiente para que cualquier retry razonable haya ocurrido. El trigger de Firestore tiene política de retry automático por hasta 7 días, pero si después de 48h sigue en `"processing"`, algo salió muy mal y el item es basura.

**Impacto en `checkDuplicate`:** Después de 24h el item ya no bloquea (ventana de `processedAt`). La limpieza a las 48h es puramente operacional.

### Decisión 11: `onAppointmentUpdated` — cancelar y re-encolar cuando cambia la fecha

Cuando `dateChanged == true`, el reminder en cola tiene variables (`fecha_turno`, `hora_turno`, `scheduledFor`, `expiresAt`) que ya no corresponden al turno. Se debe:

1. **Cancelar** el item `"queued"` con `sourceAppointmentId == appointmentId` (igual que `onAppointmentDeleted`).
2. **Re-encolar** según la nueva fecha:
   - Nueva fecha en el **pasado** → no encolar.
   - Nueva fecha **≥ 48h en el futuro** → no encolar; el `appointmentReminderGenerator` lo tomará en el ciclo correcto.
   - Nueva fecha **< 48h en el futuro** → encolar urgente inmediato (misma lógica que el fast-path de `onAppointmentCreated`).

**Reutilización de lógica:** El fast-path de `onAppointmentCreated` (enqueue urgente < 48h) debe extraerse a una función utilitaria compartida para evitar duplicación con `onAppointmentUpdated`.

**Scope:** Solo actuar cuando `dateChanged == true`. Cambios de `totalAmount` o `status` sin cambio de fecha no afectan el reminder.

## Risks / Trade-offs

| Riesgo | Mitigación |
|--------|-----------|
| Mensajes generados en días anteriores a este deploy tienen `escalationLevel` y podrían estar en estados intermedios (level=1, level=2). | Al eliminar `runEscalationPass()`, esos mensajes quedan congelados en su `scheduledFor` actual. Si ese timestamp ya pasó, se despacharán normalmente. Si está en el futuro (ej: level=1 scheduleado a 24h antes del turno), esperarán hasta ese timestamp. **Impacto acotado y transitorio.** |
| El límite de 250 mensajes puede hacer que pacientes con turnos en días de alta demanda reciban su recordatorio con menos de 24h de anticipación. | Es el comportamiento esperado y aceptado. Los mensajes urgentes tienen ventana extendida (6–20h) para compensar. |
| El batch de elevación de urgencia corre en cada invocación del orquestador (cada 10 min). | El query es barato (índice en `status` + `expiresAt`). Con `maxInstances: 1` no hay concurrencia. |

## Migration Plan

1. **Deploy de la función corregida**: reemplaza el `messageOrchestrator` actual. Sin cambios en schema ni reglas.
2. **Verificar en logs**: confirmar que mensajes con `scheduledFor <= now` se despachan en el ciclo siguiente al deploy.
3. **Rollback**: re-deploy del código anterior si se detecta degradación. Los documentos en `message_queue` no se modifican estructuralmente — el rollback es inmediato.

## Open Questions

- ¿Se quiere mantener la ventana urgente (6–20h) o unificar a 8–20h para simplificar? (No es bloqueante para este fix.)
- ¿Se debe agregar una métrica/log explícito cuando un mensaje se eleva a urgente por overflow, para poder monitorear la presión de demanda? (Recomendado pero no bloqueante.)
