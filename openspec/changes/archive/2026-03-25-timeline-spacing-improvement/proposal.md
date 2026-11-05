## Why

Con `_kPixelsPerMinute = 1.2`, un turno de 30 min ocupa solo 36dp (clamped a 48dp) y uno de 60 min ocupa 72dp. Esto obliga a un progressive disclosure agresivo que oculta el nombre del paciente y el botón "Cobrar" — las dos piezas de información más importantes para el profesional. Aumentar la escala del timeline elimina el problema de raíz: los cards son lo suficientemente altos para mostrar todo su contenido sin necesidad de ocultar elementos clave.

## What Changes

- Aumentar `_kPixelsPerMinute` de `1.2` a `2.0`, de modo que un turno de 30 min ocupe 60dp y uno de 60 min ocupe 120dp.
- Ajustar `_kMinCardHeight` de `48.0` a `56.0` para que incluso turnos de 15 min muestren al menos nombre + hora.
- Revisar los thresholds de progressive disclosure (56dp / 80dp) dado que con la nueva escala la mayoría de turnos los superan holgadamente; simplificar si ya no hace falta ocultar contenido en escenarios reales.
- Ajustar el offset de auto-scroll (`_scrollToNow`) para que la hora actual quede a ~1/3 del viewport (ya funciona, pero verificar que el mayor stack height no rompa nada).
- Para días que no son hoy: auto-scroll al primer turno del día en vez de empezar desde las 7am. El profesional abre un día pasado o futuro y quiere ver los turnos, no 3 horas vacías.

## Capabilities

### New Capabilities

- `timeline-smart-scroll`: Auto-scroll inteligente para días que no son hoy — posiciona el viewport en el primer turno del día con un margen visual de ~30 min arriba.

### Modified Capabilities

- `timeline-card-adaptive-layout`: Los thresholds de progressive disclosure se relajan porque la escala mayor hace innecesario ocultar contenido en turnos de ≥ 30 min. El threshold mínimo baja a que solo turnos de ~15 min (raros) usen modo ultra-compacto.

## Impact

- `lib/presentation/home/widgets/day_timeline_view.dart` — constantes `_kPixelsPerMinute`, `_kMinCardHeight`, auto-scroll para otros días, y `DayTimelineSkeleton`.
- `lib/presentation/home/widgets/today_appointment_card.dart` — thresholds en `_buildTimelineChildren`.
- No hay cambios en Domain, Data, Cloud Functions ni navegación.
- El timeline será ~67% más alto en scroll total (de 15h × 72px/h = 1080px a 15h × 120px/h = 1800px), pero el auto-scroll posiciona al usuario en el lugar correcto.
