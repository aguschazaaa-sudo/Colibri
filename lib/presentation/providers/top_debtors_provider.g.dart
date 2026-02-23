// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_debtors_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$topDebtorsHash() => r'62045e6c9b87e6c4b67cb9dbf7d38d6f4724fea0';

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

/// See also [topDebtors].
@ProviderFor(topDebtors)
const topDebtorsProvider = TopDebtorsFamily();

/// See also [topDebtors].
class TopDebtorsFamily extends Family<AsyncValue<List<Patient>>> {
  /// See also [topDebtors].
  const TopDebtorsFamily();

  /// See also [topDebtors].
  TopDebtorsProvider call(String providerId) {
    return TopDebtorsProvider(providerId);
  }

  @override
  TopDebtorsProvider getProviderOverride(
    covariant TopDebtorsProvider provider,
  ) {
    return call(provider.providerId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'topDebtorsProvider';
}

/// See also [topDebtors].
class TopDebtorsProvider extends AutoDisposeFutureProvider<List<Patient>> {
  /// See also [topDebtors].
  TopDebtorsProvider(String providerId)
    : this._internal(
        (ref) => topDebtors(ref as TopDebtorsRef, providerId),
        from: topDebtorsProvider,
        name: r'topDebtorsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$topDebtorsHash,
        dependencies: TopDebtorsFamily._dependencies,
        allTransitiveDependencies: TopDebtorsFamily._allTransitiveDependencies,
        providerId: providerId,
      );

  TopDebtorsProvider._internal(
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
    FutureOr<List<Patient>> Function(TopDebtorsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TopDebtorsProvider._internal(
        (ref) => create(ref as TopDebtorsRef),
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
  AutoDisposeFutureProviderElement<List<Patient>> createElement() {
    return _TopDebtorsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TopDebtorsProvider && other.providerId == providerId;
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
mixin TopDebtorsRef on AutoDisposeFutureProviderRef<List<Patient>> {
  /// The parameter `providerId` of this provider.
  String get providerId;
}

class _TopDebtorsProviderElement
    extends AutoDisposeFutureProviderElement<List<Patient>>
    with TopDebtorsRef {
  _TopDebtorsProviderElement(super.provider);

  @override
  String get providerId => (origin as TopDebtorsProvider).providerId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
