// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_name_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$patientNameHash() => r'81803d2a4c18cbb92f469d6df27d5f14ac827d99';

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

/// See also [patientName].
@ProviderFor(patientName)
const patientNameProvider = PatientNameFamily();

/// See also [patientName].
class PatientNameFamily extends Family<AsyncValue<String>> {
  /// See also [patientName].
  const PatientNameFamily();

  /// See also [patientName].
  PatientNameProvider call(String patientId) {
    return PatientNameProvider(patientId);
  }

  @override
  PatientNameProvider getProviderOverride(
    covariant PatientNameProvider provider,
  ) {
    return call(provider.patientId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'patientNameProvider';
}

/// See also [patientName].
class PatientNameProvider extends AutoDisposeFutureProvider<String> {
  /// See also [patientName].
  PatientNameProvider(String patientId)
    : this._internal(
        (ref) => patientName(ref as PatientNameRef, patientId),
        from: patientNameProvider,
        name: r'patientNameProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$patientNameHash,
        dependencies: PatientNameFamily._dependencies,
        allTransitiveDependencies: PatientNameFamily._allTransitiveDependencies,
        patientId: patientId,
      );

  PatientNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.patientId,
  }) : super.internal();

  final String patientId;

  @override
  Override overrideWith(
    FutureOr<String> Function(PatientNameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PatientNameProvider._internal(
        (ref) => create(ref as PatientNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        patientId: patientId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String> createElement() {
    return _PatientNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientNameProvider && other.patientId == patientId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, patientId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PatientNameRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `patientId` of this provider.
  String get patientId;
}

class _PatientNameProviderElement
    extends AutoDisposeFutureProviderElement<String>
    with PatientNameRef {
  _PatientNameProviderElement(super.provider);

  @override
  String get patientId => (origin as PatientNameProvider).patientId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
