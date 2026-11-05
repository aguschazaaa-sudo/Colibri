import 'package:cobrador/presentation/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_stats_provider.g.dart';

/// Reads `metadata/global.providerCount` — a single document read, no auth required.
/// Used by the landing page to show social proof without burning reads.
@riverpod
Future<int> providerCount(Ref ref) async {
  final firestore = ref.read(firebaseFirestoreProvider);
  final doc = await firestore.collection('metadata').doc('global').get();
  return (doc.data()?['providerCount'] as int?) ?? 0;
}
