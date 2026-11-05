## ADDED Requirements

### Requirement: Mensaje enviado en ventana de 48h cuando hay capacidad
El orquestador SHALL despachar mensajes con `scheduledFor <= now` y `status == "queued"` en el ciclo en que caen dentro de la ventana, siempre que haya slots disponibles dentro del límite diario.

#### Scenario: Slot disponible al llegar scheduledFor
- **WHEN** el orquestador corre y un mensaje tiene `scheduledFor <= now` y `sentCount < dailyConversationLimit`
- **THEN** el mensaje es promovido a `communications` con `status = "processing"` en ese mismo ciclo

#### Scenario: Límite diario alcanzado
- **WHEN** el orquestador corre y `sentCount >= dailyConversationLimit`
- **THEN** el mensaje permanece en `status = "queued"` y no es modificado
- **THEN** el mensaje será procesado en el siguiente ciclo cuando la ventana se resetee

### Requirement: Elevación automática a urgente por proximidad del turno
El orquestador SHALL marcar como `isUrgent = true` cualquier mensaje que cumpla simultáneamente: `status == "queued"`, `scheduledFor <= now`, y `expiresAt - now < 24h`.

#### Scenario: Mensaje no enviado con turno a menos de 24h
- **WHEN** el orquestador corre y existe un mensaje `queued` cuyo `scheduledFor` ya pasó y cuyo turno es en menos de 24h
- **THEN** el mensaje recibe `isUrgent = true` antes del paso de despacho
- **THEN** el mensaje compite por el cupo reservado para urgentes (`urgentReservePercentage`)
- **THEN** el mensaje puede enviarse en la ventana extendida (desde `urgentWindowStart`)

#### Scenario: Mensaje vencido con turno a más de 24h — sin elevación
- **WHEN** el orquestador corre y existe un mensaje `queued` cuyo `scheduledFor` ya pasó pero el turno es en más de 24h
- **THEN** el mensaje no recibe `isUrgent = true`
- **THEN** el mensaje compite por el cupo normal en el siguiente ciclo

### Requirement: Ausencia de reschedule automático
El orquestador NO SHALL modificar `scheduledFor` de ningún mensaje en la `message_queue`. El tiempo de envío es determinado únicamente por el productor que encola el mensaje.

#### Scenario: Mensaje vencido no enviado por límite de capacidad
- **WHEN** el orquestador corre y no puede enviar un mensaje por límite de capacidad
- **THEN** `scheduledFor` del mensaje permanece igual
- **THEN** el mensaje aparecerá en la query del siguiente ciclo con `scheduledFor <= now`

#### Scenario: No existe `runEscalationPass`
- **WHEN** el orquestador procesa la cola
- **THEN** no existe ningún paso previo que modifique `scheduledFor` ni `escalationLevel` de mensajes

### Requirement: `checkDuplicate` no marca mensajes pendientes como duplicados
El sistema SHALL considerar un mensaje como duplicado únicamente si existe otro mensaje del mismo tipo para el mismo paciente con status `"processing"` o `"sent"` en las últimas 24h. Mensajes con status `"queued"` NO deben ser considerados duplicados.

#### Scenario: Primer mensaje del día para un paciente
- **WHEN** el orquestador evalúa un mensaje y no existe ningún `"processing"` ni `"sent"` del mismo tipo para ese paciente en las últimas 24h
- **THEN** `isDuplicate` es `false` y el mensaje se procesa normalmente

#### Scenario: Mensaje duplicado real
- **WHEN** el orquestador evalúa un mensaje y ya existe otro con status `"sent"` del mismo tipo para ese paciente con `processedAt >= 24h ago`
- **THEN** `isDuplicate` es `true` y el mensaje se descarta con status `"duplicate"`

#### Scenario: Mensaje en cola no bloquea al siguiente
- **WHEN** existe un mensaje `"queued"` del mismo tipo para el mismo paciente
- **THEN** ese mensaje `"queued"` NO cuenta como duplicado para mensajes procesados posteriormente

### Requirement: `checkDuplicate` ancla la ventana de 24h a `processedAt`
El sistema SHALL usar `processedAt >= 24h ago` como criterio temporal para detectar duplicados, no `createdAt`. Esto evita que el tiempo de espera en cola consuma la ventana de protección del paciente.

#### Scenario: Mensaje retrasado por overflow no bloquea al día siguiente
- **WHEN** un mensaje fue encolado hace 20h (`createdAt = 20h ago`) pero procesado hace 2h (`processedAt = 2h ago`)
- **THEN** la ventana de duplicado se cuenta desde `processedAt` — el paciente no puede recibir otro mensaje del mismo tipo por las próximas 22h

### Requirement: `queueCleanup` respeta el límite de 500 operaciones por batch
El sistema SHALL dividir las eliminaciones en batches de máximo 500 documentos cada uno cuando el total de documentos a eliminar supere ese límite.

#### Scenario: Limpieza con más de 500 documentos elegibles
- **WHEN** `queueCleanup` encuentra más de 500 documentos para eliminar
- **THEN** los elimina en múltiples batches de ≤ 500 operaciones cada uno sin errores de Firestore

#### Scenario: Limpieza normal dentro del límite
- **WHEN** `queueCleanup` encuentra 500 o menos documentos para eliminar
- **THEN** los elimina en un único batch

### Requirement: `dailyScheduledActivator` no ejecuta instancias simultáneas
El sistema SHALL ejecutar el activador con `maxInstances: 1` para evitar que dos instancias procesen los mismos turnos en paralelo y disparen `onAppointmentUpdated` múltiples veces.

#### Scenario: Ejecución de larga duración
- **WHEN** una invocación del activador tarda más de 1 hora
- **THEN** Cloud Functions no lanza una segunda instancia paralela que procese los mismos turnos

### Requirement: Recordatorio urgente incluye todas las variables de plantilla
Cuando `onAppointmentCreated` encola un recordatorio urgente para un turno con menos de 48h de anticipación, el mensaje SHALL incluir `nombre_profesional` y `concepto_turno` además de `nombre_paciente`, `fecha_turno` y `hora_turno`.

#### Scenario: Turno creado con menos de 48h — variables completas
- **WHEN** se crea un turno con menos de 48h de anticipación para un provider premium activo
- **THEN** el mensaje encolado incluye `nombre_profesional` con el nombre y profesión del provider
- **THEN** el mensaje encolado incluye `concepto_turno` con el concepto del turno o `"Consulta"` por defecto

#### Scenario: Concepto de turno vacío usa valor por defecto
- **WHEN** el turno no tiene campo `concept` definido
- **THEN** `concepto_turno` en las variables es `"Consulta"`

### Requirement: Turno eliminado cancela su reminder encolado
Cuando un turno es eliminado, el sistema SHALL buscar y cancelar cualquier item en `message_queue` con `sourceAppointmentId == appointmentId` y `status == "queued"`, marcándolo como `"cancelled"`.

#### Scenario: Turno eliminado con reminder pendiente
- **WHEN** se elimina un turno que tiene un item `"queued"` en `message_queue` con `sourceAppointmentId` coincidente
- **THEN** ese item es marcado `status: "cancelled"`
- **THEN** el orquestador no despacha ese mensaje

#### Scenario: Turno eliminado sin reminder encolado
- **WHEN** se elimina un turno que no tiene ningún item en `message_queue`
- **THEN** `onAppointmentDeleted` completa sin errores

#### Scenario: Turno eliminado con reminder en processing
- **WHEN** se elimina un turno cuyo item en `message_queue` tiene `status == "processing"`
- **THEN** ese item NO es modificado (el worker ya fue despachado, no se puede cancelar)

### Requirement: `queueCleanup` elimina items `"processing"` atascados
El sistema SHALL eliminar items en `message_queue` con `status == "processing"` y `processedAt < 48h ago`, ya que indican un fallo del worker sin actualización de status.

#### Scenario: Item processing atascado por más de 48h
- **WHEN** `queueCleanup` corre y encuentra un item con `status == "processing"` y `processedAt` hace más de 48h
- **THEN** el documento es eliminado

#### Scenario: Item processing reciente no se toca
- **WHEN** `queueCleanup` corre y encuentra un item con `status == "processing"` y `processedAt` hace menos de 48h
- **THEN** el documento NO es eliminado

### Requirement: Turno reprogramado actualiza su reminder encolado
Cuando la fecha de un turno cambia, el sistema SHALL cancelar el reminder `"queued"` existente y re-encolar uno nuevo si la nueva fecha es futura y está a menos de 48h.

#### Scenario: Fecha cambia, nueva fecha < 48h en el futuro
- **WHEN** se actualiza la fecha de un turno y la nueva fecha es futura y está a menos de 48h
- **THEN** el item `"queued"` existente con `sourceAppointmentId` coincidente es marcado `"cancelled"`
- **THEN** se encola un nuevo reminder urgente con las variables actualizadas (`fecha_turno`, `hora_turno`, `scheduledFor`, `expiresAt`)

#### Scenario: Fecha cambia, nueva fecha ≥ 48h en el futuro
- **WHEN** se actualiza la fecha de un turno y la nueva fecha es futura y está a 48h o más
- **THEN** el item `"queued"` existente es marcado `"cancelled"`
- **THEN** NO se encola un nuevo reminder (el `appointmentReminderGenerator` lo tomará en el ciclo correcto)

#### Scenario: Fecha cambia a fecha pasada
- **WHEN** se actualiza la fecha de un turno a una fecha en el pasado
- **THEN** el item `"queued"` existente es marcado `"cancelled"`
- **THEN** NO se encola ningún reminder nuevo

#### Scenario: Actualización sin cambio de fecha
- **WHEN** se actualiza un turno pero solo cambia `totalAmount` o `status` (no la fecha)
- **THEN** el reminder en `message_queue` no es modificado
