## ADDED Requirements

### Requirement: Card muestra contenido progresivo según altura disponible
Cuando `TodayAppointmentCard` opera en modo `inTimeline: true`, el card SHALL adaptar su contenido según la altura que le asigna el `Positioned` padre:
- Altura < 56dp: mostrar únicamente hora + ícono de estado.
- 56dp ≤ altura < 80dp: mostrar hora + ícono de estado + nombre del paciente (1 línea, ellipsis).
- Altura ≥ 80dp: mostrar todos los elementos (hora, estado, nombre, concepto, y fila de monto/acción).

#### Scenario: Turno de 30 minutos renderiza en modo compacto
- **WHEN** un `DayScheduleItem` tiene duración de 30 min y `_kPixelsPerMinute = 1.2` (altura = 36dp, se aplica `_kMinCardHeight = 48dp`)
- **THEN** el card muestra solo hora + ícono de estado, sin texto de nombre ni botón

#### Scenario: Turno de 1 hora renderiza con nombre visible
- **WHEN** un `DayScheduleItem` tiene duración de 60 min (altura = 72dp)
- **THEN** el card muestra hora + ícono + nombre del paciente, pero oculta concepto y fila de monto/acción

#### Scenario: Turno de 90 minutos renderiza completo
- **WHEN** un `DayScheduleItem` tiene duración de 90 min (altura = 108dp)
- **THEN** el card muestra todos los elementos: hora, estado, nombre, concepto, monto y botón de acción

### Requirement: Fila de acción adapta el botón al ancho disponible
Cuando `TodayAppointmentCard` opera en modo `inTimeline: true` y la altura es ≥ 80dp, la fila de acción SHALL adaptar el botón "Cobrar total" al ancho disponible:
- Ancho disponible < 120dp: mostrar solo ícono `Icons.payments_outlined`.
- Ancho disponible ≥ 120dp: mostrar `FilledButton.tonal` con texto "Cobrar total".
El monto SHALL mostrarse siempre (en modo ícono se omite el texto del botón, no el monto).

#### Scenario: Card en columna angosta colapsa botón a ícono
- **WHEN** el card tiene ancho disponible < 120dp (e.g., 2–3 columnas en pantalla de 360dp)
- **THEN** la fila de acción muestra el monto + ícono `payments_outlined` sin texto

#### Scenario: Card en columna normal mantiene botón con texto
- **WHEN** el card tiene ancho disponible ≥ 120dp
- **THEN** la fila de acción muestra el monto + `FilledButton.tonal` con texto "Cobrar total"

### Requirement: El timeline limita columnas paralelas a 3
`DayTimelineView` SHALL limitar el número de columnas paralelas visibles a un máximo de 3, independientemente de cuántos turnos solapen en el mismo slot horario.

#### Scenario: Cuatro turnos simultáneos renderizan con máximo 3 columnas
- **WHEN** `assignColumns` devuelve items con `cols = 4`
- **THEN** `_buildPositionedItem` usa `colWidth = availableWidth / 3` y los items de columna 3+ se renderizan con offset de 8dp vertical y 4dp horizontal con opacidad 0.85

#### Scenario: Dos turnos simultáneos renderizan normalmente en 2 columnas
- **WHEN** `assignColumns` devuelve items con `cols = 2`
- **THEN** cada card ocupa exactamente `availableWidth / 2` sin modificaciones

### Requirement: El Stack del timeline no permite overflow visible
El `Stack` de appointments en `DayTimelineView` SHALL tener `clipBehavior: Clip.hardEdge` para recortar cualquier contenido que sobresalga de los límites del área de appointments.

#### Scenario: Contenido de card no sobresale del área del timeline
- **WHEN** un card renderiza contenido que excedería los límites de su `Positioned`
- **THEN** el Stack recorta el contenido en el borde del área de appointments
