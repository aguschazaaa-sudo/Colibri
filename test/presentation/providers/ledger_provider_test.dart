import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:cobrador/presentation/providers/ledger_provider.dart';
import 'package:cobrador/domain/ledger_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLedgerRepository extends Mock implements LedgerRepository {}

void main() {
  late MockLedgerRepository mockLedgerRepository;

  setUp(() {
    mockLedgerRepository = MockLedgerRepository();
  });

  ProviderContainer createContainer({
    ProviderContainer? parent,
    List<Override> overrides = const [],
    List<ProviderObserver>? observers,
  }) {
    final container = ProviderContainer(
      parent: parent,
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(mockLedgerRepository),
        ...overrides,
      ],
      observers: observers,
    );
    addTearDown(container.dispose);
    return container;
  }

  group('LedgerProvider Tests', () {
    test(
      'Build phase successfully streams appointments from Repository',
      () async {
        final container = createContainer();

        final mockAppointments = [
          Appointment(
            id: 'app_1',
            patientId: 'patient_1',
            providerId: 'prov_1',
            date: DateTime(2025, 1, 1),
            concept: 'Consulta',
            totalAmount: 100,
            amountPaid: 0,
            status: AppointmentStatus.unpaid,
          ),
        ];

        when(
          () => mockLedgerRepository.watchAppointments(
            providerId: 'prov_1',
            patientId: 'patient_1',
          ),
        ).thenAnswer((_) => Stream.value(mockAppointments));

        final provider = ledgerProvider(
          providerId: 'prov_1',
          patientId: 'patient_1',
        );

        // Add a listener to prevent the provider from being disposed
        final sub = container.listen(provider, (_, __) {});

        // We expect the AsyncLoading first, then AsyncData when the stream emits
        expect(sub.read(), const AsyncLoading<List<Appointment>>());

        // Wait for the stream to emit
        final data = await container.read(provider.future);
        expect(data, mockAppointments);

        verify(
          () => mockLedgerRepository.watchAppointments(
            providerId: 'prov_1',
            patientId: 'patient_1',
          ),
        ).called(1);
      },
    );
  });
}
