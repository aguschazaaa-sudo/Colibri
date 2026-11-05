## MODIFIED Requirements

### Requirement: Despacho del orquestador sin cap por `dailyConversationLimit`
El orquestador SHALL despachar todo mensaje con `status == "queued"` y `scheduledFor <= now` hasta el `batchLimit` (default 500), sin gatear por `dailyConversationLimit` ni por `urgentReservePercentage`. El contador `metadata/messaging_counters` se mantiene para observabilidad pero NO gatea despachos.

#### Scenario: Batch de 500 mensajes despachados en un ciclo
- **WHEN** el orquestador corre y existen 500 mensajes `queued` con `scheduledFor <= now`
- **THEN** el orquestador despacha los 500 sin chequear ningún cap artificial
- **THEN** el counter `sentCount` se incrementa en 500

#### Scenario: Cap legado `dailyConversationLimit` ignorado
- **WHEN** `metadata/messaging` tiene `dailyConversationLimit: 250` y `sentCount: 250`
- **THEN** el orquestador sigue despachando mensajes normalmente
- **THEN** NO existe el log `"daily limit reached"`

#### Scenario: Reserva legada `urgentReservePercentage` ignorada
- **WHEN** `metadata/messaging` tiene `urgentReservePercentage: 0.15`
- **THEN** el orquestador no reserva cupos para urgentes
- **THEN** urgentes y normales comparten la misma cola ordenada

### Requirement: Orden estricto urgentes-primero en la query del orquestador
El orquestador SHALL ordenar su query principal por `isUrgent DESC, priority ASC, scheduledFor ASC, createdAt ASC`. Los mensajes urgentes SHALL despacharse antes que los normales dentro del mismo ciclo, incluso si un urgente llegó después a la cola.

#### Scenario: Urgente creado después gana prioridad
- **WHEN** existe un mensaje normal encolado en `t0` con `scheduledFor = t0` y un mensaje urgente encolado en `t0 + 1min` con `scheduledFor = t0 + 1min`
- **THEN** el orquestador despacha el urgente primero

#### Scenario: Ordenamiento dentro del mismo nivel de urgencia
- **WHEN** hay dos mensajes urgentes con distinto `priority`
- **THEN** el de menor `priority` se despacha primero

#### Scenario: Ordenamiento dentro del mismo `priority`
- **WHEN** hay dos mensajes urgentes con igual `priority` pero distinto `scheduledFor`
- **THEN** el de menor `scheduledFor` se despacha primero

### Requirement: Orquestador corre con `maxInstances: 1` y `timeoutSeconds: 540`
El `messageOrchestrator` SHALL declararse con `maxInstances: 1` (para prevenir ciclos concurrentes) y `timeoutSeconds: 540` (para acomodar batch grandes con pacing).

#### Scenario: Función declarada correctamente
- **WHEN** se hace deploy de `messageOrchestrator`
- **THEN** la función tiene `maxInstances: 1, timeoutSeconds: 540` en `runWith`
