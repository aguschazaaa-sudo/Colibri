## Context

La home muestra un strip horizontal fijo de 140px con las tarjetas del día. No hay sentido temporal: los turnos no se posicionan según su hora ni muestran duración. El dominio ya tiene todo lo necesario: `Appointment.date` (inicio), `Appointment.endTime` (fin opcional), `RecurringAppointment.defaultSessionDurationMinutes` y `RecurringAppointment.frequency/baseDate` para proyectar turnos futuros.

Stack: Flutter + Riverpod + Freezed. La capa de presentación no puede tocar Firestore directamente.

## Goals / Non-Goals

**Goals:**
- Vista vertical scrollable con eje de tiempo (horas del día) posicionado con `Stack` de coordenadas absolutas.
- Cards de turno con altura proporcional a su duración; mínimo visual de 48dp para turnos muy cortos o sin `endTime`.
- Solapamientos resueltos en columnas paralelas (same-slot tiling): cada card ocupa una fracción del ancho disponible.
- Turnos proyectados desde `RecurringAppointment` (regla activa cuyo día proyectado coincide con `_selectedDate` y aún no tiene un `Appointment` generado) se muestran con estilo "ghost" diferenciado.
- Rango horario visible: 07:00 – 22:00 por defecto, se ajusta al mínimo/máximo real del día + 30 min de margen.
- La navegación de fecha existente (`_DateNavigationRow`) no cambia.
- **Auto-scroll** a la hora actual al cargar (cuando `selectedDate == today`).
- **Scroll funciona en todos los dispositivos** (touch + mouse drag).
- **FAB no ocluye contenido** — padding inferior en el timeline igual a la altura del FAB + margen.
- **Layout responsivo**: mobile (< 900px) → timeline ocupa toda la columna principal, TopDebtors se mueve a un `endDrawer` accesible desde un icono en el AppBar; desktop (≥ 900px) → layout de dos columnas: timeline a la izquierda, TopDebtors en panel fijo a la derecha.

**Non-Goals:**
- Drag-and-drop para reprogramar turnos.
- Sincronización con calendarios externos (Google Calendar, etc.).
- Crear un `Appointment` real desde un turno proyectado directamente en esta vista.
- Cambios en Cloud Functions o Firestore rules.

## Decisions

### D1 — Posicionamiento: `CustomScrollView` + `SliverToBoxAdapter` con `Stack` absoluto

**Elegido:** `SingleChildScrollView` con un `Stack` de posicionamiento absoluto usando `Positioned`. La altura del stack es `rangeHours * pixelsPerHour`. Cada card se posiciona con `top = minutesFromRangeStart * pixelsPerMinute`.

**Alternativa descartada:** `CustomPainter` con canvas — más performante pero no permite widgets interactivos (GestureDetector, InkWell, botones).

**Alternativa descartada:** `ListView` con slots fijos por hora — pierde precisión de posicionamiento y complica los solapamientos.

### D2 — Resolución de solapamientos: algoritmo greedy de columnas

**Elegido:** Antes del render, agrupar los items del día y asignar una columna (`col`) y total de columnas (`cols`) con un algoritmo O(n²) simple. Cada card recibe `width = availableWidth / cols` y `left = col * (availableWidth / cols)`. Para n < 20 turnos/día este costo es despreciable.

**Alternativa descartada:** Algoritmo interval-graph coloring completo — overkill para el caso de uso.

### D3 — Fuente de datos: provider combinado `dayScheduleProvider`

**Elegido:** Nuevo Riverpod provider `dayScheduleProvider(providerId, date)` que:
1. Lee `ledgerProvider` filtrando el día → `List<Appointment>` (reales).
2. Lee `recurringAppointmentsProvider` → proyecta fechas con la función auxiliar `RecurringRule.nextOccurrences(date)` → filtra los proyectados cuya fecha coincide con el día seleccionado y no tienen un `Appointment` ya existente con el mismo `recurringAppointmentId`.
3. Devuelve un `List<DayScheduleItem>` (sealed class: `RealAppointment | ProjectedAppointment`).

**Alternativa descartada:** Lógica de proyección inline en el widget — viola separación de responsabilidades y dificulta el test.

### D4 — Modelo de presentación: `DayScheduleItem` (sealed)

```dart
sealed class DayScheduleItem {
  DateTime get startTime;
  DateTime get endTime; // real o proyectado con defaultSessionDurationMinutes ?? providerDefault ?? 45min
}

class RealDayItem extends DayScheduleItem { final Appointment appointment; }
class ProjectedDayItem extends DayScheduleItem { final RecurringAppointment rule; }
```

Vive en `lib/presentation/providers/day_schedule_provider.dart`. Es una clase de presentación pura, no dominio.

### D5 — Reutilización del card existente

`TodayAppointmentCard` se adapta para aceptar altura variable y operar en modo vertical (el `Spacer()` interno se elimina cuando la altura es constraints-driven). Para `ProjectedDayItem` se crea `ProjectedAppointmentCard` con estilo opaco/ghost y chip "Pendiente".

### D6 — FAB clearance: padding dinámico en el timeline

**Elegido:** El `SingleChildScrollView` del timeline recibe `padding: EdgeInsets.only(bottom: kFloatingActionButtonMargin + 56 + MediaQuery.of(context).padding.bottom)` (~88dp total). Esto garantiza que el último slot visible no quede oculto bajo el FAB en mobile.

**Alternativa descartada:** `floatingActionButtonLocation: FloatingActionButtonLocation.endContained` (requiere NavigationBar, no aplica aquí). `extendBody: true` en Scaffold solo afecta NavigationBar/BottomAppBar, no el FAB flotante.

### D7 — Layout responsivo: endDrawer mobile / dos columnas desktop

**Elegido:**

- **Mobile (< 900px):** `_HomeBody` pasa a ser una `Column` con `DashboardMetrics` fijo arriba + `Expanded(child: DayTimelineView)`. `TopDebtorsSection` se mueve a un `endDrawer` del `AppShell`; se añade un botón de icono (ej: `Icons.people_alt_outlined`) en las `actions` del `AppBar` solo cuando la ruta activa es la home, que llama a `Scaffold.of(context).openEndDrawer()`.
- **Desktop (≥ 900px):** `_HomeBody` detecta `MediaQuery.sizeOf(context).width >= 900` y renderiza un `Row`: `Expanded(flex: 2, child: timeline)` + `SizedBox(width: 300, child: TopDebtorsSection)`.

**Por qué endDrawer y no bottom sheet:** el endDrawer es persistente y no bloquea el timeline; en desktop se convierte en columna fija, manteniendo coherencia visual.

**Impacto en `AppShell`:** añadir soporte a `ShellState` para `endDrawer` widget (similar a `floatingActionButton`), o bien manejar el `endDrawer` directamente en `HomePage` con un `Builder` + `Scaffold.of`. Se prefiere la segunda opción para no acoplar AppShell a contenido específico de Home.

### D8 — Auto-scroll a la hora actual

**Elegido:** `DayTimelineView` recibe un `ScrollController`. En `initState` (o en `didChangeDependencies` al cambiar `selectedDate`), cuando `selectedDate == today`, se ejecuta:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  final offset = (now.hour * 60 + now.minute - rangeStartMinutes) * pixelsPerMinute - screenHeight / 3;
  controller.animateTo(offset.clamp(0, controller.position.maxScrollExtent),
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeInOut);
});
```
Para días futuros/pasados no se hace auto-scroll (se muestra desde el inicio del rango).

**Scroll cross-device:** el `SingleChildScrollView` se envuelve en `ScrollConfiguration` con `dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}` (patrón ya usado en `TodayAppointmentsSection`).

## Risks / Trade-offs

- **Turnos sin `endTime`** → Se usa `defaultSessionDurationMinutes` del proveedor como fallback, luego 45 min. El riesgo es que la duración visual no refleje la realidad → Mitigación: mostrar indicador "duración estimada" en el card.
- **Muchos solapamientos** → Con 4+ columnas las cards se vuelven muy angostas en mobile → Mitigación: limitar a máximo 3 columnas paralelas; si hay más, apilar con desplazamiento (offset visual).
- **Performance en scroll** → Stack con 15–20 Positioned widgets es trivial. Si el rango es 15h × 60px/h = 900dp, entra en pantalla normalmente. No requiere virtualización.
- **Proyección de recurrentes** → La lógica de "¿cae un turno este día?" debe replicar exactamente lo que hace la Cloud Function. Si divergen, se muestran "fantasmas" que luego no se convierten en turnos reales → Mitigación: extraer la lógica a `recurring_utils.dart` compartida (ya existe en functions, portar a Dart).

## Open Questions

- ¿El proveedor tiene un `defaultSessionDurationMinutes` en su modelo? (verificar `Provider` domain entity — si no existe, hardcodear 45min como fallback).
- ¿El rango horario debe ser configurable por el proveedor (ej: "mi jornada es 8–20h") o se calcula automáticamente según los turnos del día? → Para MVP: calcular automáticamente.
