import 'package:cobrador/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cobrador/domain/payment.dart';

part 'payments_provider.freezed.dart';

@freezed
class PaymentsState with _$PaymentsState {
  const factory PaymentsState({
    @Default([]) List<Payment> payments,
    @Default(null) dynamic cursor,
    @Default(true) bool hasMore,
    @Default(false) bool isLoadingMore,
    @Default(AsyncValue.loading()) AsyncValue<void> status,
  }) = _PaymentsState;
}

class PaymentsNotifier extends StateNotifier<PaymentsState> {
  final Ref ref;
  final String providerId;

  PaymentsNotifier(this.ref, this.providerId) : super(const PaymentsState()) {
    fetchFirstPage();
  }

  Future<void> fetchFirstPage() async {
    state = state.copyWith(status: const AsyncValue.loading());

    print('🟢 [PaymentsNotifier] Iniciando fetchFirstPage (limit: 8)');
    final repo = ref.read(ledgerRepositoryProvider);
    final result = await repo.getPaymentsPage(providerId: providerId, limit: 8);

    result.fold(
      (failure) =>
          state = state.copyWith(
            status: AsyncValue.error(failure.message, StackTrace.current),
          ),
      (data) {
        state = state.copyWith(
          payments: data.items,
          cursor: data.cursor,
          hasMore: data.items.length == 8,
          status: const AsyncValue.data(null),
        );
      },
    );
  }

  /// Optimistically removes a payment from the local list by its ID.
  void removePayment(String paymentId) {
    state = state.copyWith(
      payments: state.payments.where((p) => p.id != paymentId).toList(),
    );
  }

  Future<void> fetchNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    print(
      '🟡 [PaymentsNotifier] fetchNextPage activado (Cursor: ${state.cursor != null ? "Válido" : "null"})',
    );
    final repo = ref.read(ledgerRepositoryProvider);
    final result = await repo.getPaymentsPage(
      providerId: providerId,
      cursor: state.cursor,
      limit: 8,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(
            isLoadingMore: false,
            // We don't set status to error here to avoid hiding existing data,
            // but a snackbar could be shown in the UI.
          ),
      (data) {
        state = state.copyWith(
          payments: [...state.payments, ...data.items],
          cursor: data.cursor,
          hasMore: data.items.length == 8,
          isLoadingMore: false,
        );
      },
    );
  }
}

final paymentsProvider = StateNotifierProvider.family
    .autoDispose<PaymentsNotifier, PaymentsState, String>((ref, providerId) {
      return PaymentsNotifier(ref, providerId);
    });
