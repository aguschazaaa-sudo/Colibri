## Why

La vista actual de turnos del día es una tira horizontal de tarjetas planas sin sentido de tiempo — no transmite cuándo empieza cada turno, cuánto dura, ni si hay solapamientos. Reemplazarla por una línea de tiempo vertical convierte la home en un calendario de trabajo real, permitiendo al profesional ver de un vistazo su jornada completa.

## What Changes

- Se elimina el strip horizontal de tarjetas (`TodayAppointmentsSection` con `ListView` horizontal) y se reemplaza por un widget de línea de tiempo vertical scrollable.
- Cada turno confirmado (`Appointment`) se renderiza como una tarjeta posicionada en el slot de tiempo correspondiente, con altura proporcional a su duración.
- Los turnos solapados (mismo horario o superposición parcial) se muestran en columnas paralelas dentro del mismo slot.
- Las reglas de turno recurrente (`RecurringAppointment`) activas que proyectan un turno en el día seleccionado pero aún no tienen un `Appointment` generado se muestran como "fantasmas" diferenciados visualmente (chip "Pendiente de confirmar").
- La navegación de fecha (flechas + datepicker) se mantiene sin cambios.

## Capabilities

### New Capabilities
- `day-timeline-view`: Vista de línea de tiempo vertical del día, con posicionamiento proporcional de turnos, soporte de solapamientos y visualización de turnos proyectados desde reglas recurrentes.

### Modified Capabilities
- (ninguna)

## Impact

- **Presentation:** `lib/presentation/home/widgets/today_appointments.dart` — refactor completo del body; el `_DateNavigationRow` se reutiliza sin cambios.
- **Presentation:** `lib/presentation/home/widgets/today_appointment_card.dart` — el card se adapta para funcionar tanto en modo vertical (timeline) como se extiende con un indicador visual para turnos proyectados.
- **Providers:** Se necesita un nuevo provider que combine `ledgerProvider` (turnos reales) + `recurringAppointmentsProvider` del día seleccionado para generar los "turnos proyectados" que aún no existen como `Appointment`.
- **Domain:** `Appointment.endTime` ya existe; `RecurringAppointment.defaultSessionDurationMinutes` ya existe. No se requieren cambios en el dominio.
- **No hay cambios en Cloud Functions ni en Firestore rules.**
