import 'package:cobrador/data/datasources/firebase_auth_data_source.dart';
import 'package:cobrador/data/repositories/auth_repository_impl.dart';
import 'package:cobrador/data/repositories/communication_log_repository_impl.dart';
import 'package:cobrador/data/repositories/ledger_repository_impl.dart';
import 'package:cobrador/data/repositories/patient_repository_impl.dart';
import 'package:cobrador/data/repositories/provider_repository_impl.dart';
import 'package:cobrador/domain/auth_repository.dart';
import 'package:cobrador/domain/communication_log_repository.dart';
import 'package:cobrador/domain/ledger_repository.dart';
import 'package:cobrador/domain/patient_repository.dart';
import 'package:cobrador/domain/provider_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'firebase_providers.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final firebaseAuthInstance = ref.watch(firebaseAuthProvider);
  final dataSource = FirebaseAuthDataSource(firebaseAuth: firebaseAuthInstance);
  return AuthRepositoryImpl(dataSource);
}

@Riverpod(keepAlive: true)
LedgerRepository ledgerRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final functions = ref.watch(firebaseFunctionsProvider);
  return LedgerRepositoryImpl(firestore, functions);
}

@Riverpod(keepAlive: true)
PatientRepository patientRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return PatientRepositoryImpl(firestore);
}

@Riverpod(keepAlive: true)
ProviderRepository providerRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return ProviderRepositoryImpl(firestore);
}

@Riverpod(keepAlive: true)
CommunicationLogRepository communicationLogRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return CommunicationLogRepositoryImpl(firestore);
}
