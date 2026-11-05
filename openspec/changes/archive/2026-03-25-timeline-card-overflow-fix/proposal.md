## Why

Al migrar de la tira horizontal a la línea del tiempo vertical, `TodayAppointmentCard` se reutilizó sin adaptar su layout a las restricciones de espacio del timeline: ancho reducido cuando hay solapamientos (múltiples columnas) y altura fija mínima de 48dp para turnos cortos. El resultado son overflows horizontales y verticales en la pantalla de Home, que empeoran cuando coinciden varios turnos a la misma hora.

## What Changes

- Adaptar el layout interno de `TodayAppointmentCard` para el modo `inTimeline`: usar `overflow: hidden` / `Overflow.clip`, y ajustar progresivamente el contenido visible según la altura disponible (`_kMinCardHeight` ≥ 48dp).
- Rediseñar `_CardTopRow` y `_CardBottomRow` para soportar ancho mínimo sin overflow: el botón "Cobrar total" se colapsa a un ícono cuando no hay espacio.
- En `DayTimelineView`, cuando `entry.cols ≥ 3`, limitar a máximo 3 columnas paralelas y apilar el resto con un offset visual para evitar tarjetas de < 80dp de ancho.
- Agregar `overflow: Overflow.clip` al `Stack` raíz del timeline para cortar cualquier contenido que sobresalga.

## Capabilities

### New Capabilities

- `timeline-card-adaptive-layout`: Layout progresivo de la tarjeta de turno en el timeline, que oculta elementos secundarios según la altura y colapsa acciones según el ancho disponible.

### Modified Capabilities

<!-- No hay cambios de requisitos a nivel de spec existente, solo ajuste de implementación UI -->

## Impact

- `lib/presentation/home/widgets/today_appointment_card.dart` — lógica de layout condicional.
- `lib/presentation/home/widgets/day_timeline_view.dart` — cap de columnas y `clipBehavior`.
- No hay cambios en Domain, Data ni Cloud Functions.
- No hay cambios en navegación ni rutas.
