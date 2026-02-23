import 'package:flutter_test/flutter_test.dart';
import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/domain/payment.dart';
import 'package:cobrador/domain/use_cases/ledger_use_cases.dart';

void main() {
  group('CalculateInterestUseCase', () {
    late CalculateInterestUseCase useCase;

    setUp(() {
      useCase = CalculateInterestUseCase();
    });

    test('should not apply interest if appointment is liquidated', () {
      final appt = Appointment(
        id: '1',
        patientId: 'p1',
        providerId: 'pr1',
        date: DateTime.now().subtract(const Duration(days: 90)),
        concept: 'Consulta',
        totalAmount: 100.0,
        amountPaid: 100.0,
        status: AppointmentStatus.liquidated,
      );

      final result = useCase.execute(appt, 0.10);
      expect(result.totalAmount, 100.0);
    });

    test('should apply 10% compound interest for 2 full months elapsed', () {
      // 100 ARS -> 1st month: 110 ARS -> 2nd month: 121 ARS
      final now = DateTime.now();
      final twoMonthsAgo = DateTime(
        now.year,
        now.month - 2,
        now.day - 1,
      ); // 2 full months guarantees

      final appt = Appointment(
        id: '1',
        patientId: 'p1',
        providerId: 'pr1',
        date: twoMonthsAgo,
        concept: 'Consulta',
        totalAmount: 100.0,
      );

      final result = useCase.execute(appt, 0.10);
      expect(result.totalAmount, 121.0); // 100 * 1.10 = 110 -> 110 * 1.10 = 121
    });

    test('should not apply interest if less than a full month elapsed', () {
      final now = DateTime.now();
      final threeWeeksAgo = now.subtract(const Duration(days: 20));

      final appt = Appointment(
        id: '1',
        patientId: 'p1',
        providerId: 'pr1',
        date: threeWeeksAgo,
        concept: 'Consulta',
        totalAmount: 100.0,
      );

      final result = useCase.execute(appt, 0.10);
      expect(result.totalAmount, 100.0);
    });
  });

  group('ApplyPaymentUseCase', () {
    late ApplyPaymentUseCase useCase;
    late Patient patient;

    setUp(() {
      useCase = ApplyPaymentUseCase();
      patient = Patient(
        id: 'p1',
        providerId: 'pr1',
        name: 'John Doe',
        phoneNumber: '12345678',
        createdAt: DateTime.now(),
      );
    });

    test(
      'should liquidate exactly one appointment when payment matches debt',
      () {
        final appt = Appointment(
          id: 'a1',
          patientId: 'p1',
          providerId: 'pr1',
          date: DateTime.now(),
          concept: 'Consulta',
          totalAmount: 200.0,
        );

        final payment = Payment(
          id: 'pay1',
          patientId: 'p1',
          providerId: 'pr1',
          amount: 200.0,
          date: DateTime.now(),
        );

        final result = useCase.execute(payment, [appt], patient);

        expect(result.updatedAppointments.length, 1);
        expect(
          result.updatedAppointments.first.status,
          AppointmentStatus.liquidated,
        );
      },
    );

    test(
      'should distribute payment across multiple appointments using FIFO logic',
      () {
        final apptOld = Appointment(
          id: 'a1',
          patientId: 'p1',
          providerId: 'pr1',
          date: DateTime(2023, 1, 1),
          concept: 'Consulta Vieja',
          totalAmount: 100.0,
        );

        final apptNew = Appointment(
          id: 'a2',
          patientId: 'p1',
          providerId: 'pr1',
          date: DateTime(2023, 2, 1),
          concept: 'Consulta Nueva',
          totalAmount: 200.0,
        );

        // Pago de 150: cubre toda la vieja (100) y deja la nueva a la mitad (se pagaron 50, faltan 150)
        final payment = Payment(
          id: 'pay1',
          patientId: 'p1',
          providerId: 'pr1',
          amount: 150.0,
          date: DateTime.now(),
        );

        final result = useCase.execute(payment, [apptOld, apptNew], patient);

        final liquidatedOld = result.updatedAppointments.firstWhere(
          (a) => a.id == 'a1',
        );
        final partialNew = result.updatedAppointments.firstWhere(
          (a) => a.id == 'a2',
        );

        expect(liquidatedOld.status, AppointmentStatus.liquidated);
        expect(liquidatedOld.amountPaid, 100.0);

        expect(partialNew.status, AppointmentStatus.unpaid);
        expect(partialNew.amountPaid, 50.0);

        // La deuda total del paciente debe ser lo que falta (150 de la nueva)
        expect(result.updatedPatient.totalDebt, 150.0);
      },
    );

    test('should add remaining money to patient balance if overpaying', () {
      final appt = Appointment(
        id: 'a1',
        patientId: 'p1',
        providerId: 'pr1',
        date: DateTime.now(),
        concept: 'Consulta',
        totalAmount: 200.0,
      );

      // Paga $300 para una deuda de $200
      final payment = Payment(
        id: 'pay1',
        patientId: 'p1',
        providerId: 'pr1',
        amount: 300.0,
        date: DateTime.now(),
      );

      final result = useCase.execute(payment, [appt], patient);

      expect(
        result.updatedAppointments.first.status,
        AppointmentStatus.liquidated,
      );
      expect(result.updatedPatient.balance, 100.0); // Sobró 100
      expect(result.updatedPatient.totalDebt, 0.0);
    });
  });
}
