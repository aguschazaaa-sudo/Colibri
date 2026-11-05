// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overlap_check_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$overlapCheckHash() => r'81c646a55306296cac8cd435c3c2fd95ec7eb952';

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

/// Returns all appointments on [params.selectedDate] for [params.providerId]
/// that overlap with the interval [params.selectedDate, params.endTime).
///
/// The result is split into:
/// - [OverlapResult.samePatient] — overlaps with the same patient (major warning)
/// - [OverlapResult.otherPatients] — overlaps with different patients (minor warning)
///
/// Returns [OverlapResult.empty] when no date/time is selected or no overlaps exist.
///
/// Copied from [overlapCheck].
@ProviderFor(overlapCheck)
const overlapCheckProvider = OverlapCheckFamily();

/// Returns all appointments on [params.selectedDate] for [params.providerId]
/// that overlap with the interval [params.selectedDate, params.endTime).
///
/// The result is split into:
/// - [OverlapResult.samePatient] — overlaps with the same patient (major warning)
/// - [OverlapResult.otherPatients] — overlaps with different patients (minor warning)
///
/// Returns [OverlapResult.empty] when no date/time is selected or no overlaps exist.
///
/// Copied from [overlapCheck].
class OverlapCheckFamily extends Family<AsyncValue<OverlapResult>> {
  /// Returns all appointments on [params.selectedDate] for [params.providerId]
  /// that overlap with the interval [params.selectedDate, params.endTime).
  ///
  /// The result is split into:
  /// - [OverlapResult.samePatient] — overlaps with the same patient (major warning)
  /// - [OverlapResult.otherPatients] — overlaps with different patients (minor warning)
  ///
  /// Returns [OverlapResult.empty] when no date/time is selected or no overlaps exist.
  ///
  /// Copied from [overlapCheck].
  const OverlapCheckFamily();

  /// Returns all appointments on [params.selectedDate] for [params.providerId]
  /// that overlap with the interval [params.selectedDate, params.endTime).
  ///
  /// The result is split into:
  /// - [OverlapResult.samePatient] — overlaps with the same patient (major warning)
  /// - [OverlapResult.otherPatients] — overlaps with different patients (minor warning)
  ///
  /// Returns [OverlapResult.empty] when no date/time is selected or no overlaps exist.
  ///
  /// Copied from [overlapCheck].
  OverlapCheckProvider call(
    ({
      DateTime? endTime,
      String? excludeAppointmentId,
      String patientId,
      String providerId,
      DateTime selectedDate,
    })
    params,
  ) {
    return OverlapCheckProvider(params);
  }

  @override
  OverlapCheckProvider getProviderOverride(
    covariant OverlapCheckProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'overlapCheckProvider';
}

/// Returns all appointments on [params.selectedDate] for [params.providerId]
/// that overlap with the interval [params.selectedDate, params.endTime).
///
/// The result is split into:
/// - [OverlapResult.samePatient] — overlaps with the same patient (major warning)
/// - [OverlapResult.otherPatients] — overlaps with different patients (minor warning)
///
/// Returns [OverlapResult.empty] when no date/time is selected or no overlaps exist.
///
/// Copied from [overlapCheck].
class OverlapCheckProvider extends AutoDisposeFutureProvider<OverlapResult> {
  /// Returns all appointments on [params.selectedDate] for [params.providerId]
  /// that overlap with the interval [params.selectedDate, params.endTime).
  ///
  /// The result is split into:
  /// - [OverlapResult.samePatient] — overlaps with the same patient (major warning)
  /// - [OverlapResult.otherPatients] — overlaps with different patients (minor warning)
  ///
  /// Returns [OverlapResult.empty] when no date/time is selected or no overlaps exist.
  ///
  /// Copied from [overlapCheck].
  OverlapCheckProvider(
    ({
      DateTime? endTime,
      String? excludeAppointmentId,
      String patientId,
      String providerId,
      DateTime selectedDate,
    })
    params,
  ) : this._internal(
        (ref) => overlapCheck(ref as OverlapCheckRef, params),
        from: overlapCheckProvider,
        name: r'overlapCheckProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$overlapCheckHash,
        dependencies: OverlapCheckFamily._dependencies,
        allTransitiveDependencies:
            OverlapCheckFamily._allTransitiveDependencies,
        params: params,
      );

  OverlapCheckProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({
    DateTime? endTime,
    String? excludeAppointmentId,
    String patientId,
    String providerId,
    DateTime selectedDate,
  })
  params;

  @override
  Override overrideWith(
    FutureOr<OverlapResult> Function(OverlapCheckRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OverlapCheckProvider._internal(
        (ref) => create(ref as OverlapCheckRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<OverlapResult> createElement() {
    return _OverlapCheckProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OverlapCheckProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OverlapCheckRef on AutoDisposeFutureProviderRef<OverlapResult> {
  /// The parameter `params` of this provider.
  ({
    DateTime? endTime,
    String? excludeAppointmentId,
    String patientId,
    String providerId,
    DateTime selectedDate,
  })
  get params;
}

class _OverlapCheckProviderElement
    extends AutoDisposeFutureProviderElement<OverlapResult>
    with OverlapCheckRef {
  _OverlapCheckProviderElement(super.provider);

  @override
  ({
    DateTime? endTime,
    String? excludeAppointmentId,
    String patientId,
    String providerId,
    DateTime selectedDate,
  })
  get params => (origin as OverlapCheckProvider).params;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
