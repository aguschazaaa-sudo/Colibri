## 1. Modelo de presentación y lógica de proyección

- [x] 1.1 Crear sealed class `DayScheduleItem` (`RealDayItem` / `ProjectedDayItem`) en `lib/presentation/providers/day_schedule_provider.dart`
- [x] 1.2 Implementar función pura `projectRecurringToDate(RecurringAppointment rule, DateTime date) → DateTime?` que replica la lógica de la Cloud Function (weekly/biweekly/monthly desde `baseDate`)
- [x] 1.3 Crear `dayScheduleProvider(providerId, date)` que combina `ledgerProvider` + `recurringAppointmentsProvider`, deduplica proyectados con reales y devuelve `List<DayScheduleItem>`

## 2. Algoritmo de layout de solapamientos

- [x] 2.1 Implementar función `assignColumns(List<DayScheduleItem> items) → List<DayScheduleItemWithLayout>` con `col` y `cols` usando algoritmo greedy de columnas
- [x] 2.2 Añadir tests unitarios para `assignColumns` cubriendo: sin solapamiento, solapamiento parcial, solapamiento total, más de 3 simultáneos

## 3. Widgets de la línea de tiempo

- [x] 3.1 Crear `DayTimelineView` (organism) en `lib/presentation/home/widgets/day_timeline_view.dart`: `SingleChildScrollView` + `Stack` con posicionamiento absoluto, rango de horas calculado dinámicamente
- [x] 3.2 Crear `TimeAxisColumn` (atom) que renderiza etiquetas de hora y líneas divisoras horizontales
- [x] 3.3 Adaptar `TodayAppointmentCard` para recibir altura como constraint externa (eliminar `Spacer()` interno cuando la altura es dada por el layout padre)
- [x] 3.4 Crear `ProjectedAppointmentCard` (atom) con estilo ghost: opacidad 0.55, borde punteado, chip "Pendiente de confirmar", sin botón de cobro
- [x] 3.5 Crear `CurrentTimeIndicator` (atom): línea horizontal accent que muestra la hora actual; visible solo cuando `selectedDate == today`; se actualiza con `Timer.periodic(1.minute)`

## 4. Integración en `TodayAppointmentsSection` y layout responsivo

- [x] 4.1 Refactorizar `_HomeBody` en `home_page.dart`: detectar breakpoint 900px con `MediaQuery.sizeOf`; en mobile renderizar `Column` con `DashboardMetrics` + `Expanded(child: DayTimelineView)`; en desktop renderizar `Row` con timeline (flex 2) + `TopDebtorsSection` (width 300dp)
- [x] 4.2 Añadir botón de ícono `Icons.people_alt_outlined` en las `actions` del AppBar (solo en home, mobile) que llama a `Scaffold.of(context).openEndDrawer()`; registrar `TopDebtorsSection` como `endDrawer` en `HomePage` via un `Builder` wrapper
- [x] 4.3 Conectar `DayTimelineView` a `dayScheduleProvider` y manejar `AsyncValue.when(data/loading/error)`
- [x] 4.4 Adaptar el skeleton de carga: `Skeletonizer` con placeholders de altura realista (3 bloques de 60dp en posiciones de ejemplo)
- [x] 4.5 Mantener `_DateNavigationRow` sin cambios; pasar `_selectedDate` a `dayScheduleProvider`

## 5. Scroll, auto-scroll y FAB clearance

- [x] 5.1 Envolver el `SingleChildScrollView` del timeline en `ScrollConfiguration` con `dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}`
- [x] 5.2 Pasar `ScrollController` al `DayTimelineView`; en `initState`/`didUpdateWidget` (cuando cambia `selectedDate`), si es today ejecutar `addPostFrameCallback` con `animateTo` a la posición de la hora actual (1/3 desde arriba del viewport)
- [x] 5.3 Añadir `padding: EdgeInsets.only(bottom: kFloatingActionButtonMargin + 56 + MediaQuery.of(context).padding.bottom)` al `SingleChildScrollView` para dejar espacio libre bajo el FAB

## 6. Indicador de duración estimada

- [x] 6.1 Mostrar badge "~Xmin estimado" en cards de `RealDayItem` cuando `endTime == null` (duración inferida por fallback)

## 7. Pruebas

- [x] 7.1 Tests unitarios de `projectRecurringToDate` para los tres tipos de frecuencia (`weekly`, `biweekly`, `monthly`) con fechas base variadas
- [x] 7.2 Tests de `dayScheduleProvider`: caso con solo reales, solo proyectados, mix con deduplicación, día sin nada
- [x] 7.3 Widget test de `DayTimelineView`: verifica posicionamiento correcto de dos turnos no solapados y uno solapado
- [x] 7.4 Widget test del layout responsivo: mobile muestra botón endDrawer en AppBar y no muestra TopDebtors inline; desktop muestra ambas secciones en row
