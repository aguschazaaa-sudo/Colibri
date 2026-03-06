// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dashboardReportHash() => r'e2d83733e659d73ea1f3592ba5d538829b067cff';

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

/// See also [dashboardReport].
@ProviderFor(dashboardReport)
const dashboardReportProvider = DashboardReportFamily();

/// See also [dashboardReport].
class DashboardReportFamily extends Family<AsyncValue<DashboardReport>> {
  /// See also [dashboardReport].
  const DashboardReportFamily();

  /// See also [dashboardReport].
  DashboardReportProvider call(String providerId) {
    return DashboardReportProvider(providerId);
  }

  @override
  DashboardReportProvider getProviderOverride(
    covariant DashboardReportProvider provider,
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
  String? get name => r'dashboardReportProvider';
}

/// See also [dashboardReport].
class DashboardReportProvider
    extends AutoDisposeStreamProvider<DashboardReport> {
  /// See also [dashboardReport].
  DashboardReportProvider(String providerId)
    : this._internal(
        (ref) => dashboardReport(ref as DashboardReportRef, providerId),
        from: dashboardReportProvider,
        name: r'dashboardReportProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$dashboardReportHash,
        dependencies: DashboardReportFamily._dependencies,
        allTransitiveDependencies:
            DashboardReportFamily._allTransitiveDependencies,
        providerId: providerId,
      );

  DashboardReportProvider._internal(
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
    Stream<DashboardReport> Function(DashboardReportRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DashboardReportProvider._internal(
        (ref) => create(ref as DashboardReportRef),
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
  AutoDisposeStreamProviderElement<DashboardReport> createElement() {
    return _DashboardReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DashboardReportProvider && other.providerId == providerId;
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
mixin DashboardReportRef on AutoDisposeStreamProviderRef<DashboardReport> {
  /// The parameter `providerId` of this provider.
  String get providerId;
}

class _DashboardReportProviderElement
    extends AutoDisposeStreamProviderElement<DashboardReport>
    with DashboardReportRef {
  _DashboardReportProviderElement(super.provider);

  @override
  String get providerId => (origin as DashboardReportProvider).providerId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
