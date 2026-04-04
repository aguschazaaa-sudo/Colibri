// ignore_for_file: avoid_redundant_argument_values
import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/home/widgets/day_timeline_view.dart';
import 'package:cobrador/presentation/home/widgets/today_appointment_card.dart';
import 'package:cobrador/presentation/providers/day_schedule_provider.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake patients notifier ────────────────────────────────────────────────────

/// Fake [Patients] notifier that emits an empty list immediately, preventing
/// any real Firestore query from being executed during widget tests.
class _FakePatients extends Patients {
  @override
  Stream<List<Patient>> build(String providerId) => Stream.value([]);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// The provider ID used throughout all tests. Every `patientsProvider` override
/// must target this exact ID because [TodayAppointmentCard] calls
/// `patientsProvider(appointment.providerId)`.
const _kProviderId = 'provider-1';

/// Creates an [Appointment] with the given [start] and optional [end].
Appointment _makeAppointment({
  required String id,
  required DateTime start,
  DateTime? end,
}) {
  return Appointment(
    id: id,
    patientId: 'patient-1',
    providerId: _kProviderId,
    date: start,
    concept: 'Consulta',
    totalAmount: 1000,
    endTime: end,
  );
}

/// Creates a [RealDayItem] whose start/end are fully controlled via [start] and
/// [end].
RealDayItem _makeRealItem({
  required String id,
  required DateTime start,
  required DateTime end,
}) {
  return RealDayItem(
    appointment: _makeAppointment(id: id, start: start, end: end),
    fallbackDurationMinutes: 45,
  );
}

/// Wraps [DayTimelineView] in the minimal widget tree required by tests.
///
/// Overrides `patientsProvider(_kProviderId)` with [_FakePatients] so that
/// [TodayAppointmentCard] never attempts a real Firestore query.
Widget _buildHarness({
  required List<DayScheduleItem> items,
  required DateTime selectedDate,
  bool isToday = false,
}) {
  return ProviderScope(
    overrides: [
      // Override only the specific family member for _kProviderId.
      // PatientsProvider (the concrete instance) exposes overrideWith(factory).
      patientsProvider(_kProviderId).overrideWith(() => _FakePatients()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 800,
          child: DayTimelineView(
            items: items,
            selectedDate: selectedDate,
            isToday: isToday,
            providerId: _kProviderId,
          ),
        ),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // A fixed date that is never "today" so auto-scroll logic is never triggered.
  final date = DateTime(2025, 6, 10);

  group('DayTimelineView', () {
    // ── Empty list ───────────────────────────────────────────────────────────

    group('empty items list', () {
      testWidgets('renders no TodayAppointmentCard when items is empty',
          (tester) async {
        await tester.pumpWidget(
          _buildHarness(items: const [], selectedDate: date),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TodayAppointmentCard), findsNothing);
      });
    });

    // ── Two non-overlapping appointments ─────────────────────────────────────

    group('two non-overlapping appointments', () {
      testWidgets('renders two TodayAppointmentCards', (tester) async {
        final item1 = _makeRealItem(
          id: 'a1',
          start: DateTime(2025, 6, 10, 9, 0),
          end: DateTime(2025, 6, 10, 10, 0),
        );
        final item2 = _makeRealItem(
          id: 'a2',
          start: DateTime(2025, 6, 10, 11, 0),
          end: DateTime(2025, 6, 10, 12, 0),
        );

        await tester.pumpWidget(
          _buildHarness(items: [item1, item2], selectedDate: date),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TodayAppointmentCard), findsNWidgets(2));
      });

      testWidgets('cards are positioned at different vertical offsets',
          (tester) async {
        final item1 = _makeRealItem(
          id: 'a1',
          start: DateTime(2025, 6, 10, 9, 0),
          end: DateTime(2025, 6, 10, 10, 0),
        );
        final item2 = _makeRealItem(
          id: 'a2',
          start: DateTime(2025, 6, 10, 11, 0),
          end: DateTime(2025, 6, 10, 12, 0),
        );

        await tester.pumpWidget(
          _buildHarness(items: [item1, item2], selectedDate: date),
        );
        await tester.pumpAndSettle();

        final cards = tester
            .widgetList<TodayAppointmentCard>(find.byType(TodayAppointmentCard))
            .toList();
        expect(cards, hasLength(2));

        final topLeft1 = tester.getTopLeft(find.byWidget(cards[0]));
        final topLeft2 = tester.getTopLeft(find.byWidget(cards[1]));

        // Cards must differ vertically — item1 (09:00) is above item2 (11:00).
        expect(
          topLeft1.dy,
          isNot(closeTo(topLeft2.dy, 1.0)),
          reason: 'Non-overlapping appointments must be at different vertical '
              'positions on the timeline',
        );
        expect(
          topLeft1.dy,
          lessThan(topLeft2.dy),
          reason: 'item1 (09:00) must appear above item2 (11:00)',
        );
      });
    });

    // ── Two overlapping appointments ─────────────────────────────────────────

    group('two overlapping appointments', () {
      testWidgets('renders two TodayAppointmentCards', (tester) async {
        final item1 = _makeRealItem(
          id: 'b1',
          start: DateTime(2025, 6, 10, 9, 0),
          end: DateTime(2025, 6, 10, 10, 0),
        );
        final item2 = _makeRealItem(
          id: 'b2',
          start: DateTime(2025, 6, 10, 9, 0),
          end: DateTime(2025, 6, 10, 10, 0),
        );

        await tester.pumpWidget(
          _buildHarness(items: [item1, item2], selectedDate: date),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TodayAppointmentCard), findsNWidgets(2));
      });

      testWidgets(
          'each overlapping card occupies approximately half the available width',
          (tester) async {
        const viewportWidth = 400.0;

        final item1 = _makeRealItem(
          id: 'b1',
          start: DateTime(2025, 6, 10, 9, 0),
          end: DateTime(2025, 6, 10, 10, 0),
        );
        final item2 = _makeRealItem(
          id: 'b2',
          start: DateTime(2025, 6, 10, 9, 0),
          end: DateTime(2025, 6, 10, 10, 0),
        );

        await tester.pumpWidget(
          _buildHarness(items: [item1, item2], selectedDate: date),
        );
        await tester.pumpAndSettle();

        final cards = tester
            .widgetList<TodayAppointmentCard>(find.byType(TodayAppointmentCard))
            .toList();
        expect(cards, hasLength(2));

        final size1 = tester.getSize(find.byWidget(cards[0]));
        final size2 = tester.getSize(find.byWidget(cards[1]));

        // With two overlapping items assignColumns sets cols=2, so each
        // Positioned gets colWidth = availableWidth / 2.
        // We verify each card is clearly narrower than the full viewport and
        // both cards have the same width (symmetric split).
        expect(
          size1.width,
          lessThan(viewportWidth * 0.8),
          reason: 'Each card in a 2-column overlap must be narrower than '
              'the full timeline width',
        );
        expect(
          size2.width,
          lessThan(viewportWidth * 0.8),
          reason: 'Each card in a 2-column overlap must be narrower than '
              'the full timeline width',
        );

        // Widths should match within AppSpacing.xs (4 px) gap tolerance.
        expect(
          (size1.width - size2.width).abs(),
          lessThanOrEqualTo(4.0),
          reason: 'Both overlapping cards must share equal column widths '
              '(symmetric layout)',
        );
      });

      testWidgets(
          'overlapping cards share the same vertical offset but differ horizontally',
          (tester) async {
        final item1 = _makeRealItem(
          id: 'b1',
          start: DateTime(2025, 6, 10, 9, 0),
          end: DateTime(2025, 6, 10, 10, 0),
        );
        final item2 = _makeRealItem(
          id: 'b2',
          start: DateTime(2025, 6, 10, 9, 0),
          end: DateTime(2025, 6, 10, 10, 0),
        );

        await tester.pumpWidget(
          _buildHarness(items: [item1, item2], selectedDate: date),
        );
        await tester.pumpAndSettle();

        final cards = tester
            .widgetList<TodayAppointmentCard>(find.byType(TodayAppointmentCard))
            .toList();

        final topLeft1 = tester.getTopLeft(find.byWidget(cards[0]));
        final topLeft2 = tester.getTopLeft(find.byWidget(cards[1]));

        // Same start time → same top position.
        expect(
          topLeft1.dy,
          closeTo(topLeft2.dy, 1.0),
          reason: 'Appointments starting at the same time must share the same '
              'vertical position on the timeline',
        );

        // Different horizontal positions (side by side in separate columns).
        expect(
          topLeft1.dx,
          isNot(closeTo(topLeft2.dx, 1.0)),
          reason: 'Overlapping appointments must be rendered in separate '
              'horizontal columns',
        );
      });
    });
  });
}
