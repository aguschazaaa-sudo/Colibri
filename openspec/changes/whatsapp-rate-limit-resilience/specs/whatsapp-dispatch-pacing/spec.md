## ADDED Requirements

### Requirement: Pacing defensivo del orquestador a 80 MPS
El orquestador SHALL respetar una tasa máxima de creaciones de documentos `communications` por segundo, configurable via `metadata/messaging.maxDispatchRatePerSecond` (default `40`). El pacing se aplica introduciendo un delay mínimo entre despachos dentro del mismo run.

#### Scenario: Pacing con 5 mensajes y rate de 10 MPS
- **WHEN** el orquestador despacha 5 mensajes con `maxDispatchRatePerSecond: 10`
- **THEN** el tiempo total entre el primer y el último dispatch es al menos `400ms` (4 gaps de 100ms)

#### Scenario: Default rate de 40 MPS
- **WHEN** la config de `metadata/messaging` no especifica `maxDispatchRatePerSecond`
- **THEN** el orquestador aplica un delay de 25ms entre despachos (1000 / 40)

#### Scenario: Config deshabilita el pacing
- **WHEN** `maxDispatchRatePerSecond` está configurado en `0` o valor no finito
- **THEN** el orquestador no aplica delay entre despachos

#### Scenario: Pacing no bloquea la urgency elevation pass
- **WHEN** el orquestador corre el paso de urgency elevation (batch update)
- **THEN** no se aplica el delay de pacing a las operaciones de elevación

### Requirement: Timeout del orquestador compatible con batch grande
El `messageOrchestrator` SHALL configurarse con `timeoutSeconds: 540` para que el pacing del batch de 500 mensajes no exceda el timeout default.

#### Scenario: Función declarada con timeout extendido
- **WHEN** se hace deploy de `messageOrchestrator`
- **THEN** la función tiene `timeoutSeconds: 540` en `runWith`
