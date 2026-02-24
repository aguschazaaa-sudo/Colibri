import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient.freezed.dart';

@freezed
abstract class Patient with _$Patient {
  const factory Patient({
    required String id,
    required String providerId,
    required String name,
    required String phoneNumber,
    String? email,
    @Default(0.0) double totalDebt,
    @Default(0.0) double balance, // Saldo a favor
    required DateTime createdAt,
  }) = _Patient;
}
