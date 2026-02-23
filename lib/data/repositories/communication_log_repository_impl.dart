import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cobrador/domain/communication_log.dart';
import 'package:cobrador/domain/communication_log_repository.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:fpdart/fpdart.dart';

class CommunicationLogRepositoryImpl implements CommunicationLogRepository {
  final FirebaseFirestore _firestore;

  CommunicationLogRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, CommunicationLog>> enqueueWhatsAppReminder({
    required String providerId,
    required String patientId,
    required double totalDebtAtThatTime,
  }) async {
    try {
      final docRef = _firestore.collection('communications').doc();
      final now = DateTime.now();

      final data = {
        'providerId': providerId,
        'patientId': patientId,
        'type': 'whatsapp_reminder',
        'status': 'pending',
        'totalDebtAtThatTime': totalDebtAtThatTime,
        'messageId': '',
        'sentAt': Timestamp.fromDate(now),
      };

      await docRef.set(data);

      final log = CommunicationLog(
        id: docRef.id,
        providerId: providerId,
        patientId: patientId,
        messageId: '',
        sentAt: now,
        status: 'pending',
        totalDebtAtThatTime: totalDebtAtThatTime,
      );

      return Right(log);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message ?? 'Firebase Error'));
    } catch (e) {
      return Left(Failure.serverError(e.toString()));
    }
  }
}
