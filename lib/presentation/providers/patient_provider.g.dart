// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$patientsHash() => r'49791bd423e9fe37ee3e1e49f4cd90d60d5cb82d';

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

abstract class _$Patients
    extends BuildlessAutoDisposeStreamNotifier<List<Patient>> {
  late final String providerId;

  Stream<List<Patient>> build(String providerId);
}

/// See also [Patients].
@ProviderFor(Patients)
const patientsProvider = PatientsFamily();

/// See also [Patients].
class PatientsFamily extends Family<AsyncValue<List<Patient>>> {
  /// See also [Patients].
  const PatientsFamily();

  /// See also [Patients].
  PatientsProvider call(String providerId) {
    return PatientsProvider(providerId);
  }

  @override
  PatientsProvider getProviderOverride(covariant PatientsProvider provider) {
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
  String? get name => r'patientsProvider';
}

/// See also [Patients].
class PatientsProvider
    extends AutoDisposeStreamNotifierProviderImpl<Patients, List<Patient>> {
  /// See also [Patients].
  PatientsProvider(String providerId)
    : this._internal(
        () => Patients()..providerId = providerId,
        from: patientsProvider,
        name: r'patientsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$patientsHash,
        dependencies: PatientsFamily._dependencies,
        allTransitiveDependencies: PatientsFamily._allTransitiveDependencies,
        providerId: providerId,
      );

  PatientsProvider._internal(
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
  Stream<List<Patient>> runNotifierBuild(covariant Patients notifier) {
    return notifier.build(providerId);
  }

  @override
  Override overrideWith(Patients Function() create) {
    return ProviderOverride(
      origin: this,
      override: PatientsProvider._internal(
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
  AutoDisposeStreamNotifierProviderElement<Patients, List<Patient>>
  createElement() {
    return _PatientsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientsProvider && other.providerId == providerId;
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
mixin PatientsRef on AutoDisposeStreamNotifierProviderRef<List<Patient>> {
  /// The parameter `providerId` of this provider.
  String get providerId;
}

class _PatientsProviderElement
    extends AutoDisposeStreamNotifierProviderElement<Patients, List<Patient>>
    with PatientsRef {
  _PatientsProviderElement(super.provider);

  @override
  String get providerId => (origin as PatientsProvider).providerId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
