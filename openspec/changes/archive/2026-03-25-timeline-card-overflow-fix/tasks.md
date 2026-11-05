## 1. Stack del timeline — clip y límite a 2 columnas visibles

- [x] 1.1 En `day_timeline_view.dart`, cambiar `clipBehavior: Clip.none` a `Clip.hardEdge` en el `Stack` de appointments
- [x] 1.2 Agrupar los items de `withLayout` por slot de solapamiento: identificar grupos donde `entry.cols > 2`
- [x] 1.3 Para grupos con ≤ 2 items, renderizar con `_buildPositionedItem` normal (sin cambios)
- [x] 1.4 Para grupos con > 2 items, renderizar solo los primeros 2 items; sobre el segundo, superponer el badge `_SlotOverflowBadge`

## 2. Badge "+N" tappable con énfasis animado

- [x] 2.1 Crear widget `_SlotOverflowBadge` en `day_timeline_view.dart`: `FilledButton` 28×28dp con `Icons.expand_more` + label `+N`, color `colorScheme.primary`, posicionado en `Positioned` esquina superior derecha del segundo card
- [x] 2.2 Agregar animación de entrada con `flutter_animate`: `.animate().scale(begin: Offset(0.5, 0.5), end: Offset(1, 1), curve: Curves.elasticOut, duration: 400.ms)`
- [x] 2.3 Encadenar idle pulse con `.then(delay: 1.seconds).scale(end: Offset(1.14, 1.14), duration: 550.ms, curve: Curves.easeInOut).then().scale(end: Offset(1, 1), duration: 550.ms).repeat(pause: 3.seconds)`
- [x] 2.4 Respetar `MediaQuery.of(context).disableAnimations`: si es `true`, omitir el idle pulse (mantener solo la entrada estática o sin animación)
- [x] 2.5 Envolver el badge en `RepaintBoundary` para aislar el repaint del pulse
- [x] 2.6 El badge al presionarse llama `showModalBottomSheet` con `_SlotOverflowSheet`
- [x] 2.7 Asegurarse de que el hit test del badge no se solape con el tap del card subyacente (`z-order` superior en el `Stack`)

## 3. BottomSheet de turnos del slot

- [x] 3.1 Crear widget `_SlotOverflowSheet` en `day_timeline_view.dart`
- [x] 3.2 Header con rango horario del slot (ej: "09:00 – 09:45") y total de turnos ("4 turnos")
- [x] 3.3 Lista scrollable de `TodayAppointmentCard` (modo `inTimeline: false`, ancho completo) para cada `DayScheduleItem` del grupo
- [x] 3.4 Usar `DraggableScrollableSheet` o `showModalBottomSheet(isScrollControlled: true)` para que el sheet se pueda agrandar si hay muchos turnos

## 4. Card adaptativo por altura — progressive disclosure

- [x] 4.1 En `today_appointment_card.dart`, envolver el `Column` hijo del `Container` en un `LayoutBuilder` cuando `inTimeline: true`
- [x] 4.2 Implementar lógica de threshold: `height < 56` → solo `_CardTopRow`; `56 ≤ height < 80` → `_CardTopRow` + nombre; `height ≥ 80` → layout completo
- [x] 4.3 Extraer la selección de children a un método privado `_buildTimelineChildren(double height)` para mantener `build()` < 60 líneas

## 5. Fila de acción adaptativa al ancho

- [x] 5.1 En `_CardBottomRow`, envolver en `LayoutBuilder` para detectar `constraints.maxWidth`
- [x] 5.2 Si `maxWidth < 120`, mostrar `IconButton` con `Icons.payments_outlined` en lugar del `FilledButton.tonal` con texto
- [x] 5.3 El monto siempre visible; solo el botón cambia de forma

## 6. Turnos recurrentes proyectados — chip de frecuencia + navegación

- [x] 6.1 En `projected_appointment_card.dart`, verificar qué campo de `RecurringAppointment` representa la frecuencia y agregar helper de presentación si no existe (ej: `frequencyLabel` → "Semanal", "Quincenal", "Mensual")
- [x] 6.2 Reemplazar `_PendingChip` por `_FrequencyChip` que muestre `Icons.repeat` + label de frecuencia (mismo estilo visual, color `secondaryContainer`)
- [x] 6.3 Cambiar el `onTap` de `GestureDetector` para navegar a `/patients/${rule.patientId}` con `context.push` en lugar de mostrar el `SnackBar`

## 7. Validación visual

- [ ] 7.1 Verificar con 2 turnos simultáneos: no hay overflow, 2 columnas normales
- [ ] 7.2 Verificar con 3+ turnos simultáneos: aparecen 2 columnas + badge `+N` con color primario visible
- [ ] 7.3 Tocar badge `+N`: abre BottomSheet con todos los turnos del slot listos para scrollear
- [ ] 7.4 Verificar turno de 30min (~48dp alto): muestra solo hora + ícono sin overflow
- [ ] 7.5 Verificar turno de 60min (~72dp alto): muestra hora + nombre sin BottomRow
- [ ] 7.6 Verificar turno proyectado recurrente: chip de frecuencia visible, tap navega al paciente
