## MODIFIED Requirements

### Requirement: Card muestra contenido progresivo según altura disponible
Cuando `TodayAppointmentCard` opera en modo `inTimeline: true`, el card SHALL adaptar su contenido según la altura que le asigna el `Positioned` padre:
- Altura < 56dp: mostrar únicamente hora + ícono de estado.
- 56dp ≤ altura < 90dp: mostrar hora + ícono de estado + nombre del paciente (1 línea, ellipsis).
- Altura ≥ 90dp: mostrar todos los elementos (hora, estado, nombre, concepto, y fila de monto/acción).

#### Scenario: Turno de 15 minutos renderiza en modo ultra-compacto
- **WHEN** un `DayScheduleItem` tiene duración de 15 min y `_kPixelsPerMinute = 2.0` (altura = 30dp, se aplica `_kMinCardHeight = 56dp`)
- **THEN** el card muestra hora + ícono + nombre del paciente (threshold 56dp superado)

#### Scenario: Turno de 30 minutos renderiza con nombre visible
- **WHEN** un `DayScheduleItem` tiene duración de 30 min (altura = 60dp)
- **THEN** el card muestra hora + ícono + nombre del paciente

#### Scenario: Turno de 45 minutos renderiza completo
- **WHEN** un `DayScheduleItem` tiene duración de 45 min (altura = 90dp)
- **THEN** el card muestra todos los elementos: hora, estado, nombre, concepto, monto y botón de acción

#### Scenario: Turno de 60 minutos renderiza completo con espacio
- **WHEN** un `DayScheduleItem` tiene duración de 60 min (altura = 120dp)
- **THEN** el card muestra todos los elementos con espacio vertical confortable

### Requirement: El timeline usa escala de 2.0 píxeles por minuto
`DayTimelineView` SHALL usar `_kPixelsPerMinute = 2.0` y `_kMinCardHeight = 56.0` para garantizar que los cards tengan espacio suficiente para su contenido.

#### Scenario: Constantes del timeline reflejan la nueva escala
- **WHEN** el timeline se renderiza
- **THEN** `_kPixelsPerMinute` es `2.0` y `_kMinCardHeight` es `56.0`

#### Scenario: Stack height calculado con nueva escala
- **WHEN** el rango del timeline es de 15 horas (7:00–22:00)
- **THEN** el `stackHeight` es 1800dp (15 × 60 × 2.0)
