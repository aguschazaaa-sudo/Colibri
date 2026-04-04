// ignore_for_file: avoid_redundant_argument_values
import 'dart:async';

import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/ledger_repository.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/domain/patient_repository.dart';
import 'package:cobrador/domain/payment.dart';
import 'package:cobrador/domain/recurring_appointment.dart';
import 'package:cobrador/presentation/home/home_page.dart';
import 'package:cobrador/presentation/home/widgets/top_debtors.dart';
import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockLedgerRepository extends Mock implements LedgerRepository {}

class _MockPatientRepository extends Mock implements PatientRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds the overrides shared across all test cases.
List<Override> _buildOverrides({
  required _MockFirebaseAuth auth,
  required _MockLedgerRepository ledger,
  required _MockPatientRepository patients,
}) {
  return [
    firebaseAuthProvider.overrideWithValue(auth),
    ledgerRepositoryProvider.overrideWithValue(ledger),
    patientRepositoryProvider.overrideWithValue(patients),
  ];
}

/// Wraps [HomePage] in a minimal widget tree with the given screen [size].
///
/// Uses a plain [MaterialApp] — the test does not exercise [AppShell]'s
/// AppBar rendering; it focuses on whether [TopDebtorsSection] is present
/// as a direct child of the body.
Widget _buildHarness({
  required List<Override> overrides,
  required Size size,
}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: HomePage()),
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _MockFirebaseAuth mockAuth;
  late _MockLedgerRepository mockLedger;
  late _MockPatientRepository mockPatients;

  setUp(() {
    mockAuth = _MockFirebaseAuth();
    mockLedger = _MockLedgerRepository();
    mockPatients = _MockPatientRepository();

    // Auth returns no logged-in user — every widget falls back to a safe state.
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockAuth.authStateChanges())
        .thenAnswer((_) => Stream.value(null));
    when(() => mockAuth.userChanges()).thenAnswer((_) => Stream.value(null));
    when(() => mockAuth.idTokenChanges()).thenAnswer((_) => Stream.value(null));

    // Repository stubs that return empty data without hitting Firestore.
    when(
      () => mockLedger.watchAppointments(
        providerId: any(named: 'providerId'),
        patientId: any(named: 'patientId'),
      ),
    ).thenAnswer((_) => Stream.value(<Appointment>[]));

    when(
      () => mockLedger.watchRecurringAppointments(
        providerId: any(named: 'providerId'),
        patientId: any(named: 'patientId'),
      ),
    ).thenAnswer((_) => Stream.value(<RecurringAppointment>[]));

    when(
      () => mockLedger.getPaymentsPage(
        providerId: any(named: 'providerId'),
        patientId: any(named: 'patientId'),
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => Right(
        (items: <Payment>[], cursor: null),
      ),
    );

    when(
      () => mockPatients.watchPatients(any()),
    ).thenAnswer((_) => Stream.value(<Patient>[]));
  });

  group('Responsive layout — TopDebtorsSection placement', () {
    /// On mobile (< 900px) the [TopDebtorsSection] is registered as an
    /// end-drawer in the shell and is NOT rendered as a direct body child.
    testWidgets(
      'mobile layout does NOT include TopDebtorsSection inline',
      (tester) async {
        const mobileSize = Size(390, 844); // iPhone 14 logical pixels

        await tester.pumpWidget(
          _buildHarness(
            overrides: _buildOverrides(
              auth: mockAuth,
              ledger: mockLedger,
              patients: mockPatients,
            ),
            size: mobileSize,
          ),
        );
        await tester.pump();

        // TopDebtorsSection should NOT be part of the main-body widget tree
        // on mobile — it lives behind the end-drawer.
        expect(
          find.byType(TopDebtorsSection),
          findsNothing,
          reason: 'TopDebtorsSection must not be rendered inline on mobile; '
              'it is accessible only via the end-drawer.',
        );
      },
    );

    /// On desktop (≥ 900px) the [TopDebtorsSection] is rendered as a fixed
    /// side column (300dp wide) in a [Row] alongside the timeline.
    testWidgets(
      'desktop layout includes TopDebtorsSection inline',
      (tester) async {
        const desktopSize = Size(1280, 800);

        await tester.pumpWidget(
          _buildHarness(
            overrides: _buildOverrides(
              auth: mockAuth,
              ledger: mockLedger,
              patients: mockPatients,
            ),
            size: desktopSize,
          ),
        );
        await tester.pump();

        // TopDebtorsSection IS in the widget tree as a direct body child on
        // desktop, even if it renders SizedBox.shrink() due to null auth.
        expect(
          find.byType(TopDebtorsSection),
          findsOneWidget,
          reason: 'TopDebtorsSection must be rendered inline as a side panel '
              'on desktop (≥ 900px).',
        );
      },
    );

    /// Changing the screen width from desktop to mobile should remove
    /// [TopDebtorsSection] from the inline body.
    testWidgets(
      'toggling from desktop to mobile removes TopDebtorsSection from body',
      (tester) async {
        final overrides = _buildOverrides(
          auth: mockAuth,
          ledger: mockLedger,
          patients: mockPatients,
        );

        // Start at desktop width.
        await tester.pumpWidget(
          _buildHarness(overrides: overrides, size: const Size(1280, 800)),
        );
        await tester.pump();
        expect(find.byType(TopDebtorsSection), findsOneWidget);

        // Shrink to mobile width.
        await tester.pumpWidget(
          _buildHarness(overrides: overrides, size: const Size(390, 844)),
        );
        await tester.pump();
        expect(find.byType(TopDebtorsSection), findsNothing);
      },
    );
  });
}
