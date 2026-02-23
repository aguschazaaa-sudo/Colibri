import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';

@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String patientId,
    required String providerId,
    String? appointmentId,
    required double amount,
    required DateTime date,
  }) = _Payment;
}
