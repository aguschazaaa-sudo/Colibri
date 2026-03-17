import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cobrador/data/models/communication_log_model.dart';
import 'package:cobrador/domain/communication_log.dart';
import 'package:cobrador/domain/communication_log_repository.dart';
import 'package:cobrador/domain/failure.dart';
import 'package:fpdart/fpdart.dart';

class CommunicationLogRepositoryImpl implements CommunicationLogRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CommunicationLogRepositoryImpl(this._firestore, this._functions);

  /// Returns a reference to `providers/{providerId}/communications`.
  CollectionReference<Map<String, dynamic>> _commCollection(
    String providerId,
  ) {
    return _firestore
        .collection('providers')
        .doc(providerId)
        .collection('communications');
  }

  // ---------------------------------------------------------------------------
  // Stream
  // ---------------------------------------------------------------------------

  @override
  Stream<List<CommunicationLog>> watchCommunicationLogs(
    String providerId,
  ) {
    return _commCollection(providerId)
        .orderBy('sentAt', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    CommunicationLogModel.fromJson(doc.data(), doc.id)
                        .toEntity(),
              )
              .toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // Enqueue single reminder
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, CommunicationLog>> enqueueWhatsAppReminder({
    required String providerId,
    required String patientId,
    required double totalDebtAtThatTime,
    String? patientName,
  }) async {
    try {
      final docRef = _commCollection(providerId).doc();
      final now = DateTime.now();

      final data = {
        'providerId': providerId,
        'patientId': patientId,
        'type': 'whatsapp_reminder',
        'status': 'pending',
        'totalDebtAtThatTime': totalDebtAtThatTime,
        'messageId': '',
        'sentAt': Timestamp.fromDate(now),
        if (patientName != null) 'patientName': patientName,
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
        patientName: patientName,
      );

      return Right(log);
    } on FirebaseException catch (e) {
      return Left(Failure.serverError(e.message ?? 'Firebase Error'));
    } catch (e) {
      return Left(Failure.serverError(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Bulk trigger via Cloud Function (kept for backend compatibility)
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, int>> triggerBulkReminders() async {
    try {
      final callable = _functions.httpsCallable(
        'workers-triggerManualReminders',
      );
      final result = await callable.call<Map<String, dynamic>>();
      final queued = (result.data['queued'] as num).toInt();
      return Right(queued);
    } on FirebaseFunctionsException catch (e) {
      return Left(
        Failure.serverError(e.message ?? 'Error al enviar recordatorios'),
      );
    } catch (e) {
      return Left(Failure.serverError(e.toString()));
    }
  }
}
