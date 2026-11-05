## 1. Constantes del timeline

- [x] 1.1 En `day_timeline_view.dart`, cambiar `_kPixelsPerMinute` de `1.2` a `2.0`
- [x] 1.2 En `day_timeline_view.dart`, cambiar `_kMinCardHeight` de `48.0` a `56.0`

## 2. Thresholds de progressive disclosure

- [x] 2.1 En `today_appointment_card.dart`, cambiar el threshold de layout completo de `80` a `90` en `_buildTimelineChildren`
- [x] 2.2 Verificar que el threshold de nombre (`56`) sigue siendo correcto con el nuevo `_kMinCardHeight = 56`

## 3. Auto-scroll inteligente para otros días

- [x] 3.1 Crear método `_scrollToFirstItem()` en `_DayTimelineViewState` que calcula el offset del primer turno menos ~30 min de margen
- [x] 3.2 En `initState`, si `!isToday` y `items.isNotEmpty`, llamar `_scrollToFirstItem()` en `addPostFrameCallback`
- [x] 3.3 En `didUpdateWidget`, si cambia la fecha y `!isToday`, llamar `_scrollToFirstItem()`

## 4. Skeleton placeholder

- [x] 4.1 En `DayTimelineSkeleton`, ajustar la altura de los bloques skeleton de `60` a `100` para reflejar la nueva escala
- [x] 4.2 Ajustar el `stackHeight` del skeleton (cambiar `_kPixelsPerMinute` referencia si es necesario)

## 5. Validación visual

- [ ] 5.1 Verificar turno de 30 min: muestra hora + nombre (60dp con escala 2.0)
- [ ] 5.2 Verificar turno de 45 min: muestra layout completo con botón Cobrar (90dp)
- [ ] 5.3 Verificar turno de 60 min: layout completo con espacio confortable (120dp)
- [ ] 5.4 Verificar auto-scroll a hora actual funciona correctamente con la nueva escala
- [ ] 5.5 Verificar auto-scroll al primer turno cuando se navega a un día que no es hoy
- [ ] 5.6 Verificar que el overflow badge (+N) sigue funcionando con la nueva escala
