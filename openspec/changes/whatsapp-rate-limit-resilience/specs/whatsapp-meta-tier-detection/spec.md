## ADDED Requirements

### Requirement: Detección de tier exhaustion de Meta via error de Twilio
El sistema SHALL identificar el error de tier exhaustion de Meta cuando Twilio retorna un error con código `63038` o `63032`. Estos códigos SHALL ser tratados como una señal de "capacidad temporalmente agotada", NO como fallo del mensaje.

#### Scenario: Twilio retorna 63038
- **WHEN** `sendWhatsAppReminder` llama a Twilio y recibe un error con `code: 63038`
- **THEN** el sistema ejecuta el flujo de rollback por tier exhaustion
- **THEN** el sistema NO marca el queue item como `failed`
- **THEN** el sistema NO marca la communication como `failed`

#### Scenario: Twilio retorna 63032
- **WHEN** `sendWhatsAppReminder` llama a Twilio y recibe un error con `code: 63032`
- **THEN** el sistema ejecuta el flujo de rollback por tier exhaustion

#### Scenario: Twilio retorna 429 sin metadata de Meta
- **WHEN** `sendWhatsAppReminder` llama a Twilio y recibe un `status: 429` que no corresponde a tier exhaustion de Meta
- **THEN** el sistema aplica el retry path existente (1s, 4s)
- **THEN** el sistema NO escribe `pausedUntil` ni ejecuta el rollback de tier

### Requirement: Rollback limpio ante tier exhaustion
Ante la detección de tier exhaustion, el sender SHALL borrar el documento de `communications` (y su mirror en la sub-colección del paciente), revertir el queue item a `status: "queued"` con `processedAt` limpio, y NO incrementar `attempts`.

#### Scenario: Rollback completo
- **WHEN** el sender detecta tier exhaustion para un mensaje con `commId` en `providers/{providerId}/communications/{commId}` y `queueItemId` en `message_queue/{queueItemId}`
- **THEN** el documento `providers/{providerId}/communications/{commId}` es borrado
- **THEN** el documento espejo `providers/{providerId}/patients/{patientId}/communications/{commId}` es borrado
- **THEN** el documento `message_queue/{queueItemId}` tiene `status = "queued"`
- **THEN** el campo `processedAt` del queue item es removido
- **THEN** el campo `attempts` del queue item NO cambia

#### Scenario: Rollback idempotente
- **WHEN** el rollback se ejecuta dos veces para el mismo mensaje (por retry del trigger de Firestore)
- **THEN** la segunda ejecución no lanza excepción
- **THEN** el estado final es el mismo que con una sola ejecución

#### Scenario: Queue item ya borrado durante rollback
- **WHEN** el rollback intenta actualizar un queue item que ya no existe en `message_queue`
- **THEN** el sistema loguea warn pero no lanza excepción
- **THEN** el rollback del comm doc y el write de `pausedUntil` se completan normalmente

### Requirement: Circuit breaker via `metadata/messaging.pausedUntil`
Ante la detección de tier exhaustion, el sender SHALL escribir `pausedUntil` en `metadata/messaging` con el valor `now + tierExhaustedPauseMs`. El orquestador SHALL leer este campo antes del paso de despacho y saltear el ciclo si la pausa está vigente.

#### Scenario: Sender escribe pausedUntil al detectar tier exhaustion
- **WHEN** el sender detecta tier exhaustion en `tA`
- **THEN** el documento `metadata/messaging` tiene `pausedUntil` igual a `tA + tierExhaustedPauseMs`
- **THEN** otros campos de `metadata/messaging` no son modificados (merge write)

#### Scenario: Orquestador saltea ciclo durante pausa activa
- **WHEN** el orquestador corre en `tB` y `metadata/messaging.pausedUntil` es `tB + 10min` (pausa activa)
- **THEN** el orquestador loguea `"dispatch paused due to tier exhaustion"` con el timestamp de `pausedUntil`
- **THEN** el orquestador no ejecuta el paso de despacho
- **THEN** el orquestador SÍ ejecuta el paso de urgency elevation (no cuesta API calls)

#### Scenario: Pausa expirada
- **WHEN** el orquestador corre en `tC` y `metadata/messaging.pausedUntil` es `tC - 1min` (expirada)
- **THEN** el orquestador despacha normalmente

#### Scenario: Campo pausedUntil ausente
- **WHEN** el orquestador corre y `metadata/messaging` no contiene `pausedUntil`
- **THEN** el orquestador despacha normalmente

### Requirement: Sin logging de PII en el rollback
El flujo de rollback por tier exhaustion SHALL omitir números de teléfono, nombres de pacientes y montos de todos los logs.

#### Scenario: Log de rollback
- **WHEN** el sender ejecuta el rollback por tier exhaustion
- **THEN** los logs contienen `commId`, `queueItemId`, `providerId` y `pausedUntil`
- **THEN** los logs NO contienen `phoneNumber`, `patientName`, ni `variables.monto_total`
