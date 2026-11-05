// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_snapshots_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$monthlySnapshotsHash() => r'a5d83820e2edc8a53faafff912ab4040a545dac2';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Watches the last 12 monthly revenue snapshots for [providerId].
///
/// Emits an ordered list from most recent to oldest.
/// Returns an empty list when no snapshots exist yet (first month of use).
///
/// Copied from [monthlySnapshots].
@ProviderFor(monthlySnapshots)
const monthlySnapshotsProvider = MonthlySnapshotsFamily();

/// Watches the last 12 monthly revenue snapshots for [providerId].
///
/// Emits an ordered list from most recent to oldest.
/// Returns an empty list when no snapshots exist yet (first month of use).
///
/// Copied from [monthlySnapshots].
class MonthlySnapshotsFamily extends Family<AsyncValue<List<MonthlySnapshot>>> {
  /// Watches the last 12 monthly revenue snapshots for [providerId].
  ///
  /// Emits an ordered list from most recent to oldest.
  /// Returns an empty list when no snapshots exist yet (first month of use).
  ///
  /// Copied from [monthlySnapshots].
  const MonthlySnapshotsFamily();

  /// Watches the last 12 monthly revenue snapshots for [providerId].
  ///
  /// Emits an ordered list from most recent to oldest.
  /// Returns an empty list when no snapshots exist yet (first month of use).
  ///
  /// Copied from [monthlySnapshots].
  MonthlySnapshotsProvider call({required String providerId}) {
    return MonthlySnapshotsProvider(providerId: providerId);
  }

  @override
  MonthlySnapshotsProvider getProviderOverride(
    covariant MonthlySnapshotsProvider provider,
  ) {
    return call(providerId: provider.providerId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthlySnapshotsProvider';
}

/// Watches the last 12 monthly revenue snapshots for [providerId].
///
/// Emits an ordered list from most recent to oldest.
/// Returns an empty list when no snapshots exist yet (first month of use).
///
/// Copied from [monthlySnapshots].
class MonthlySnapshotsProvider
    extends AutoDisposeStreamProvider<List<MonthlySnapshot>> {
  /// Watches the last 12 monthly revenue snapshots for [providerId].
  ///
  /// Emits an ordered list from most recent to oldest.
  /// Returns an empty list when no snapshots exist yet (first month of use).
  ///
  /// Copied from [monthlySnapshots].
  MonthlySnapshotsProvider({required String providerId})
    : this._internal(
        (ref) => monthlySnapshots(
          ref as MonthlySnapshotsRef,
          providerId: providerId,
        ),
        from: monthlySnapshotsProvider,
        name: r'monthlySnapshotsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$monthlySnapshotsHash,
        dependencies: MonthlySnapshotsFamily._dependencies,
        allTransitiveDependencies:
            MonthlySnapshotsFamily._allTransitiveDependencies,
        providerId: providerId,
      );

  MonthlySnapshotsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.providerId,
  }) : super.internal();

  final String providerId;

  @override
  Override overrideWith(
    Stream<List<MonthlySnapshot>> Function(MonthlySnapshotsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlySnapshotsProvider._internal(
        (ref) => create(ref as MonthlySnapshotsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        providerId: providerId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MonthlySnapshot>> createElement() {
    return _MonthlySnapshotsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlySnapshotsProvider && other.providerId == providerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, providerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MonthlySnapshotsRef
    on AutoDisposeStreamProviderRef<List<MonthlySnapshot>> {
  /// The parameter `providerId` of this provider.
  String get providerId;
}

class _MonthlySnapshotsProviderElement
    extends AutoDisposeStreamProviderElement<List<MonthlySnapshot>>
    with MonthlySnapshotsRef {
  _MonthlySnapshotsProviderElement(super.provider);

  @override
  String get providerId => (origin as MonthlySnapshotsProvider).providerId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
