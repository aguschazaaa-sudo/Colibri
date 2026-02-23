// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$patientPaymentsHash() => r'991c0ba2d1f1d6b70e880a35f558ffc7d84247ed';

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

/// Provider extra para observar solo los pagos de un paciente
///
/// Copied from [patientPayments].
@ProviderFor(patientPayments)
const patientPaymentsProvider = PatientPaymentsFamily();

/// Provider extra para observar solo los pagos de un paciente
///
/// Copied from [patientPayments].
class PatientPaymentsFamily extends Family<AsyncValue<List<Payment>>> {
  /// Provider extra para observar solo los pagos de un paciente
  ///
  /// Copied from [patientPayments].
  const PatientPaymentsFamily();

  /// Provider extra para observar solo los pagos de un paciente
  ///
  /// Copied from [patientPayments].
  PatientPaymentsProvider call({
    required String providerId,
    required String patientId,
  }) {
    return PatientPaymentsProvider(
      providerId: providerId,
      patientId: patientId,
    );
  }

  @override
  PatientPaymentsProvider getProviderOverride(
    covariant PatientPaymentsProvider provider,
  ) {
    return call(providerId: provider.providerId, patientId: provider.patientId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'patientPaymentsProvider';
}

/// Provider extra para observar solo los pagos de un paciente
///
/// Copied from [patientPayments].
class PatientPaymentsProvider extends AutoDisposeStreamProvider<List<Payment>> {
  /// Provider extra para observar solo los pagos de un paciente
  ///
  /// Copied from [patientPayments].
  PatientPaymentsProvider({
    required String providerId,
    required String patientId,
  }) : this._internal(
         (ref) => patientPayments(
           ref as PatientPaymentsRef,
           providerId: providerId,
           patientId: patientId,
         ),
         from: patientPaymentsProvider,
         name: r'patientPaymentsProvider',
         debugGetCreateSourceHash:
             const bool.fromEnvironment('dart.vm.product')
                 ? null
                 : _$patientPaymentsHash,
         dependencies: PatientPaymentsFamily._dependencies,
         allTransitiveDependencies:
             PatientPaymentsFamily._allTransitiveDependencies,
         providerId: providerId,
         patientId: patientId,
       );

  PatientPaymentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.providerId,
    required this.patientId,
  }) : super.internal();

  final String providerId;
  final String patientId;

  @override
  Override overrideWith(
    Stream<List<Payment>> Function(PatientPaymentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PatientPaymentsProvider._internal(
        (ref) => create(ref as PatientPaymentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        providerId: providerId,
        patientId: patientId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Payment>> createElement() {
    return _PatientPaymentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientPaymentsProvider &&
        other.providerId == providerId &&
        other.patientId == patientId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, providerId.hashCode);
    hash = _SystemHash.combine(hash, patientId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PatientPaymentsRef on AutoDisposeStreamProviderRef<List<Payment>> {
  /// The parameter `providerId` of this provider.
  String get providerId;

  /// The parameter `patientId` of this provider.
  String get patientId;
}

class _PatientPaymentsProviderElement
    extends AutoDisposeStreamProviderElement<List<Payment>>
    with PatientPaymentsRef {
  _PatientPaymentsProviderElement(super.provider);

  @override
  String get providerId => (origin as PatientPaymentsProvider).providerId;
  @override
  String get patientId => (origin as PatientPaymentsProvider).patientId;
}

String _$ledgerHash() => r'eca4151fff8e2fcb82892e87ae4623af7d558f9b';

abstract class _$Ledger
    extends BuildlessAutoDisposeStreamNotifier<List<Appointment>> {
  late final String providerId;
  late final String patientId;

  Stream<List<Appointment>> build({
    required String providerId,
    required String patientId,
  });
}

/// See also [Ledger].
@ProviderFor(Ledger)
const ledgerProvider = LedgerFamily();

/// See also [Ledger].
class LedgerFamily extends Family<AsyncValue<List<Appointment>>> {
  /// See also [Ledger].
  const LedgerFamily();

  /// See also [Ledger].
  LedgerProvider call({required String providerId, required String patientId}) {
    return LedgerProvider(providerId: providerId, patientId: patientId);
  }

  @override
  LedgerProvider getProviderOverride(covariant LedgerProvider provider) {
    return call(providerId: provider.providerId, patientId: provider.patientId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'ledgerProvider';
}

/// See also [Ledger].
class LedgerProvider
    extends AutoDisposeStreamNotifierProviderImpl<Ledger, List<Appointment>> {
  /// See also [Ledger].
  LedgerProvider({required String providerId, required String patientId})
    : this._internal(
        () =>
            Ledger()
              ..providerId = providerId
              ..patientId = patientId,
        from: ledgerProvider,
        name: r'ledgerProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product') ? null : _$ledgerHash,
        dependencies: LedgerFamily._dependencies,
        allTransitiveDependencies: LedgerFamily._allTransitiveDependencies,
        providerId: providerId,
        patientId: patientId,
      );

  LedgerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.providerId,
    required this.patientId,
  }) : super.internal();

  final String providerId;
  final String patientId;

  @override
  Stream<List<Appointment>> runNotifierBuild(covariant Ledger notifier) {
    return notifier.build(providerId: providerId, patientId: patientId);
  }

  @override
  Override overrideWith(Ledger Function() create) {
    return ProviderOverride(
      origin: this,
      override: LedgerProvider._internal(
        () =>
            create()
              ..providerId = providerId
              ..patientId = patientId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        providerId: providerId,
        patientId: patientId,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<Ledger, List<Appointment>>
  createElement() {
    return _LedgerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LedgerProvider &&
        other.providerId == providerId &&
        other.patientId == patientId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, providerId.hashCode);
    hash = _SystemHash.combine(hash, patientId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LedgerRef on AutoDisposeStreamNotifierProviderRef<List<Appointment>> {
  /// The parameter `providerId` of this provider.
  String get providerId;

  /// The parameter `patientId` of this provider.
  String get patientId;
}

class _LedgerProviderElement
    extends AutoDisposeStreamNotifierProviderElement<Ledger, List<Appointment>>
    with LedgerRef {
  _LedgerProviderElement(super.provider);

  @override
  String get providerId => (origin as LedgerProvider).providerId;
  @override
  String get patientId => (origin as LedgerProvider).patientId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
