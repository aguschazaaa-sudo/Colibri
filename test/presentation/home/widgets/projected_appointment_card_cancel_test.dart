import 'dart:async';

import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:cobrador/presentation/home/widgets/atoms/projected_appointment_card.dart';
import 'package:cobrador/presentation/home/widgets/today_appointment_card.dart';
import 'package:cobrador/presentation/providers/cancel_recurring_occurrence_controller.dart';
import 'package:cobrador/presentation/providers/patient_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake notifiers ────────────────────────────────────────────────────────────

class _FakePatients extends Patients {
  @override
  Stream<List<Patient>> build(String providerId) => Stream.value([]);
}

class _FakeCancelController extends CancelRecurringOccurrenceController {
  @override
  FutureOr<void> build() {}

  @override
  Future<void> cancelOccurrence({
    required String providerId,
    required String patientId,
    required String recurringAppointmentId,
    required String dateKey,
    String? existingAppointmentId,
  }) async {
    // no-op for tests
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _kProviderId = 'prov1';
const _kPatientId = 'pat1';
const _kDateKey = '2026-04-10';

RecurringAppointment _makeRule({String id = 'rec1'}) {
  return RecurringAppointment(
    id: id,
    patientId: _kPatientId,
    providerId: _kProviderId,
    concept: 'Consulta',
    defaultAmount: 5000,
    frequency: Frequency.weekly,
    baseDate: DateTime(2026, 3, 13, 9, 0),
    active: true,
  );
}

Appointment _makeRecurringAppointment({String? recurringId = 'rec1'}) {
  return Appointment(
    id: 'apt1',
    patientId: _kPatientId,
    providerId: _kProviderId,
    concept: 'Consulta',
    totalAmount: 5000,
    date: DateTime(2026, 4, 10, 9, 0),
    recurringAppointmentId: recurringId,
  );
}

List<Override> _overrides() => [
  patientsProvider(_kProviderId).overrideWith(() => _FakePatients()),
  cancelRecurringOccurrenceControllerProvider
      .overrideWith(() => _FakeCancelController()),
];

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: _overrides(),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ProjectedAppointmentCard — trash button', () {
    testWidgets('shows trash icon button', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProjectedAppointmentCard(
            rule: _makeRule(),
            providerId: _kProviderId,
            dateKey: _kDateKey,
            patientName: 'Ana',
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('tapping trash shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProjectedAppointmentCard(
            rule: _makeRule(),
            providerId: _kProviderId,
            dateKey: _kDateKey,
            patientName: 'Ana',
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('¿Cancelar esta sesión?'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
      expect(find.text('Cancelar'), findsAtLeastNWidgets(1));
    });

    testWidgets('dismissing dialog with Cancelar closes it', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProjectedAppointmentCard(
            rule: _makeRule(),
            providerId: _kProviderId,
            dateKey: _kDateKey,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Tap the "Cancelar" action button in the dialog
      final cancelButtons = find.text('Cancelar');
      await tester.tap(cancelButtons.last);
      await tester.pumpAndSettle();

      expect(find.text('¿Cancelar esta sesión?'), findsNothing);
    });
  });

  group('TodayAppointmentCard — trash button', () {
    testWidgets(
      'shows trash button in timeline mode when appointment is recurring',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              height: 100,
              child: TodayAppointmentCard(
                appointment: _makeRecurringAppointment(recurringId: 'rec1'),
                inTimeline: true,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'hides trash button when appointment is NOT recurring',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              height: 100,
              child: TodayAppointmentCard(
                appointment: _makeRecurringAppointment(recurringId: null),
                inTimeline: true,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      },
    );

    testWidgets(
      'hides trash button when not in timeline mode even if recurring',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              height: 200,
              width: 220,
              child: TodayAppointmentCard(
                appointment: _makeRecurringAppointment(recurringId: 'rec1'),
                inTimeline: false,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      },
    );

    testWidgets(
      'tapping trash on recurring timeline card shows confirmation dialog',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              height: 100,
              child: TodayAppointmentCard(
                appointment: _makeRecurringAppointment(recurringId: 'rec1'),
                inTimeline: true,
              ),
            ),
          ),
        );

        await tester.pump();

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();

        expect(find.text('¿Cancelar esta sesión?'), findsOneWidget);
        expect(find.text('Confirmar'), findsOneWidget);
      },
    );
  });
}
