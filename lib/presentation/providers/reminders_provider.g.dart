// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$remindersControllerHash() =>
    r'4510e1079692312b5494ac107524a1ca3d5845e0';

/// Notifier for the Reminders page.
///
/// State: `AsyncValue<int?>` — null = idle, int = queued count from last send.
///
/// Copied from [RemindersController].
@ProviderFor(RemindersController)
final remindersControllerProvider =
    AutoDisposeNotifierProvider<RemindersController, AsyncValue<int?>>.internal(
      RemindersController.new,
      name: r'remindersControllerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$remindersControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RemindersController = AutoDisposeNotifier<AsyncValue<int?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
