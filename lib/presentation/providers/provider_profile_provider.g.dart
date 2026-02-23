// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$providerProfileHash() => r'd46c9a803391bf7ac8ecb495f8e303293afc8bef';

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

abstract class _$ProviderProfile
    extends BuildlessAutoDisposeStreamNotifier<Provider?> {
  late final String providerId;

  Stream<Provider?> build(String providerId);
}

/// See also [ProviderProfile].
@ProviderFor(ProviderProfile)
const providerProfileProvider = ProviderProfileFamily();

/// See also [ProviderProfile].
class ProviderProfileFamily extends Family<AsyncValue<Provider?>> {
  /// See also [ProviderProfile].
  const ProviderProfileFamily();

  /// See also [ProviderProfile].
  ProviderProfileProvider call(String providerId) {
    return ProviderProfileProvider(providerId);
  }

  @override
  ProviderProfileProvider getProviderOverride(
    covariant ProviderProfileProvider provider,
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
  String? get name => r'providerProfileProvider';
}

/// See also [ProviderProfile].
class ProviderProfileProvider
    extends AutoDisposeStreamNotifierProviderImpl<ProviderProfile, Provider?> {
  /// See also [ProviderProfile].
  ProviderProfileProvider(String providerId)
    : this._internal(
        () => ProviderProfile()..providerId = providerId,
        from: providerProfileProvider,
        name: r'providerProfileProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$providerProfileHash,
        dependencies: ProviderProfileFamily._dependencies,
        allTransitiveDependencies:
            ProviderProfileFamily._allTransitiveDependencies,
        providerId: providerId,
      );

  ProviderProfileProvider._internal(
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
  Stream<Provider?> runNotifierBuild(covariant ProviderProfile notifier) {
    return notifier.build(providerId);
  }

  @override
  Override overrideWith(ProviderProfile Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProviderProfileProvider._internal(
        () => create()..providerId = providerId,
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
  AutoDisposeStreamNotifierProviderElement<ProviderProfile, Provider?>
  createElement() {
    return _ProviderProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProviderProfileProvider && other.providerId == providerId;
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
mixin ProviderProfileRef on AutoDisposeStreamNotifierProviderRef<Provider?> {
  /// The parameter `providerId` of this provider.
  String get providerId;
}

class _ProviderProfileProviderElement
    extends AutoDisposeStreamNotifierProviderElement<ProviderProfile, Provider?>
    with ProviderProfileRef {
  _ProviderProfileProviderElement(super.provider);

  @override
  String get providerId => (origin as ProviderProfileProvider).providerId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
