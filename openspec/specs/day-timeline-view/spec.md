### Requirement: Timeline renders appointments by time position
The widget `DayTimelineView` SHALL render each `Appointment` of the selected day as a card vertically positioned proportional to its start time, within a scrollable column representing the day's time range.

#### Scenario: Appointment appears at correct position
- **WHEN** an `Appointment` has `date` at 10:30
- **THEN** its card top edge aligns with the 10:30 mark on the time axis

#### Scenario: Empty day shows empty state
- **WHEN** the selected day has no appointments and no projected appointments
- **THEN** the timeline shows the `AppointmentsEmptyState` widget

### Requirement: Card height is proportional to appointment duration
Each appointment card SHALL have a height proportional to its duration. When `endTime` is null, the system SHALL use `RecurringAppointment.defaultSessionDurationMinutes` (if linked), else the provider's `defaultSessionDurationMinutes`, else 45 minutes. The minimum rendered height SHALL be 48dp regardless of computed duration.

#### Scenario: Appointment with endTime renders tall card
- **WHEN** an `Appointment` has `endTime` set to 60 minutes after `date`
- **THEN** the card height equals `60 * pixelsPerMinute`

#### Scenario: Appointment without endTime uses fallback duration
- **WHEN** an `Appointment` has no `endTime` and no linked recurring rule with duration
- **THEN** the card height equals `45 * pixelsPerMinute`

#### Scenario: Very short appointment respects minimum height
- **WHEN** computed duration is less than 48dp worth of minutes
- **THEN** the card height is 48dp

### Requirement: Overlapping appointments render side by side
When two or more appointments overlap in time (partial or full), the timeline SHALL split the horizontal space into equal columns and render each overlapping appointment in its own column without clipping.

#### Scenario: Two overlapping appointments share the row
- **WHEN** two `Appointment` records overlap in time on the same day
- **THEN** each card occupies half the available width, positioned in adjacent columns

#### Scenario: Non-overlapping appointments use full width
- **WHEN** no two appointments overlap
- **THEN** each card uses the full available width

#### Scenario: Maximum columns capped at 3
- **WHEN** more than 3 appointments overlap at the same time slot
- **THEN** the first 3 are rendered side by side and remaining ones are offset visually (stacked with a slight horizontal shift)

### Requirement: Time axis is visible alongside appointments
The timeline SHALL display hour labels (e.g., "08:00", "09:00") on the left side of the timeline at regular intervals, with horizontal divider lines extending across the full width.

#### Scenario: Hour labels appear at correct positions
- **WHEN** the timeline renders the 09:00 hour mark
- **THEN** the "09:00" label aligns exactly with the 09:00 position on the time axis

#### Scenario: Current time indicator shown for today
- **WHEN** the selected date is today
- **THEN** a horizontal accent line indicates the current time, updating in real time (1-minute polling or `Timer.periodic`)

### Requirement: Projected recurring appointments shown as ghost cards
Active `RecurringAppointment` rules that project a session on the selected day but do not yet have a matching `Appointment` (matched by `recurringAppointmentId`) SHALL be rendered as "ghost" cards with a distinct visual style (reduced opacity, dashed border, chip "Pendiente"), UNLESS the projected date's `dateKey` is present in the rule's `cancelledDates` array — in which case no card (ghost or real) SHALL be shown.

#### Scenario: Projected appointment renders with ghost style
- **WHEN** a `RecurringAppointment` projects a session on the selected day and no real `Appointment` exists with that `recurringAppointmentId`
- **THEN** a ghost card is shown at the projected time slot with the label "Pendiente de confirmar"

#### Scenario: Ghost card suppressed when real appointment exists
- **WHEN** a `RecurringAppointment` projects a session on the selected day AND a real `Appointment` with matching `recurringAppointmentId` exists for that day
- **THEN** only the real appointment card is shown (no ghost duplicate)

#### Scenario: Ghost card is non-interactive for payment
- **WHEN** the user taps the "Cobrar total" area of a ghost card
- **THEN** no payment action is triggered; the tap navigates to the patient detail or shows an informational snackbar

#### Scenario: Ghost card suppressed for cancelled occurrence
- **WHEN** a `RecurringAppointment` projects a session on the selected day AND the selected day's `dateKey` is present in `cancelledDates`
- **THEN** no card (ghost or real) is shown for that occurrence on the timeline

### Requirement: Time range auto-adjusts to day content
The visible time range SHALL default to 07:00–22:00. When the earliest appointment starts before 07:00 or the latest ends after 22:00, the range SHALL expand to include those appointments plus a 30-minute margin.

#### Scenario: Default range for normal day
- **WHEN** all appointments are between 08:00 and 20:00
- **THEN** the timeline renders 07:00–22:00

#### Scenario: Early appointment expands range start
- **WHEN** an appointment starts at 06:00
- **THEN** the timeline range starts at 05:30

### Requirement: Date navigation is preserved
The existing `_DateNavigationRow` (previous/next arrows + datepicker) SHALL be kept above the timeline without behavioral changes.

#### Scenario: Navigating to next day updates timeline
- **WHEN** the user taps the next-day arrow
- **THEN** the timeline re-renders with appointments for the new selected date

#### Scenario: Datepicker selection updates timeline
- **WHEN** the user picks a date from the datepicker
- **THEN** the timeline re-renders with appointments for that date

### Requirement: Timeline auto-scrolls to current time on load
When the selected date is today, the timeline SHALL automatically animate the scroll position so that the current time is visible (roughly centered in the upper third of the viewport) after the data loads. For past or future dates, the timeline SHALL start at the top of the range without auto-scroll.

#### Scenario: Auto-scroll on today
- **WHEN** the selected date is today and data finishes loading
- **THEN** the scroll position animates to show the current time within the visible viewport

#### Scenario: No auto-scroll for non-today dates
- **WHEN** the selected date is not today
- **THEN** the timeline starts at the top of the time range with no scroll animation

#### Scenario: Re-selecting today triggers auto-scroll
- **WHEN** the user navigates away to another date and then returns to today
- **THEN** the timeline auto-scrolls to the current time again

### Requirement: Timeline is scrollable on all device types
The timeline's scroll axis SHALL respond to both touch drag (mobile) and mouse drag/wheel (desktop/web), using `ScrollConfiguration` with `dragDevices` including `PointerDeviceKind.touch` and `PointerDeviceKind.mouse`.

#### Scenario: Mouse drag scrolls the timeline on desktop
- **WHEN** the user clicks and drags vertically on the timeline on a desktop browser
- **THEN** the timeline scrolls

#### Scenario: Touch drag scrolls the timeline on mobile
- **WHEN** the user swipes vertically on the timeline on a touch device
- **THEN** the timeline scrolls

### Requirement: FAB does not occlude timeline content
The bottom of the timeline's scroll area SHALL include sufficient padding so that the last time slot is fully visible above the Floating Action Button. The padding SHALL be at least `kFloatingActionButtonMargin + 56 + system bottom inset` (~88dp).

#### Scenario: Last appointment visible above FAB
- **WHEN** an appointment occupies the last time slot of the day
- **THEN** its card is fully visible without being hidden behind the FAB

### Requirement: Responsive layout — mobile single-column with endDrawer, desktop two-column
On mobile (viewport width < 900px): the `_HomeBody` SHALL render `DashboardMetrics` at the top followed by `DayTimelineView` expanded to fill the remaining vertical space. `TopDebtorsSection` SHALL be accessible via an `endDrawer` opened by a dedicated icon button in the AppBar (visible only on the home route). On desktop (≥ 900px): the body SHALL render a `Row` with the timeline taking 2/3 of the width and `TopDebtorsSection` in a fixed-width (300dp) panel on the right.

#### Scenario: Mobile — TopDebtors accessible via AppBar icon
- **WHEN** the viewport is < 900px and the user taps the "top debtors" icon in the AppBar
- **THEN** the endDrawer slides in from the right showing `TopDebtorsSection`

#### Scenario: Desktop — two-column layout
- **WHEN** the viewport is ≥ 900px
- **THEN** the timeline and `TopDebtorsSection` are displayed side by side in the same row

#### Scenario: Mobile — timeline fills available height
- **WHEN** the viewport is < 900px
- **THEN** `DayTimelineView` is `Expanded` within the home body column, using the full remaining height below `DashboardMetrics`

### Requirement: Loading and error states are displayed
The timeline SHALL use `Skeletonizer` during data load and a retry-capable error widget on failure, consistent with the existing design system.

#### Scenario: Loading state shows skeleton
- **WHEN** the day data is loading
- **THEN** `Skeletonizer` wraps placeholder time slots of realistic height

#### Scenario: Error state shows retry
- **WHEN** loading fails
- **THEN** an error widget with a "Reintentar" button is shown; tapping it invalidates the provider
