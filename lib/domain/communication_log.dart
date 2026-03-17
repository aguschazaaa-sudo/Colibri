import 'package:freezed_annotation/freezed_annotation.dart';

part 'communication_log.freezed.dart';

@freezed
abstract class CommunicationLog with _$CommunicationLog {
  const factory CommunicationLog({
    required String id,
    required String patientId,
    required String providerId,
    required String messageId,
    required DateTime sentAt,
    required String status,
    required double totalDebtAtThatTime,
    String? patientName,
  }) = _CommunicationLog;
}
