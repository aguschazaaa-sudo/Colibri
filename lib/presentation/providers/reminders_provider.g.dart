// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$communicationLogsHash() => r'9baeaa49c09d937f2c22d8d586ff71c2621c7250';

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

/// See also [communicationLogs].
@ProviderFor(communicationLogs)
const communicationLogsProvider = CommunicationLogsFamily();

/// See also [communicationLogs].
class CommunicationLogsFamily
    extends Family<AsyncValue<List<CommunicationLog>>> {
  /// See also [communicationLogs].
  const CommunicationLogsFamily();

  /// See also [communicationLogs].
  CommunicationLogsProvider call(String providerId) {
    return CommunicationLogsProvider(providerId);
  }

  @override
  CommunicationLogsProvider getProviderOverride(
    covariant CommunicationLogsProvider provider,
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
  String? get name => r'communicationLogsProvider';
}

/// See also [communicationLogs].
class CommunicationLogsProvider
    extends AutoDisposeStreamProvider<List<CommunicationLog>> {
  /// See also [communicationLogs].
  CommunicationLogsProvider(String providerId)
    : this._internal(
        (ref) => communicationLogs(ref as CommunicationLogsRef, providerId),
        from: communicationLogsProvider,
        name: r'communicationLogsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$communicationLogsHash,
        dependencies: CommunicationLogsFamily._dependencies,
        allTransitiveDependencies:
            CommunicationLogsFamily._allTransitiveDependencies,
        providerId: providerId,
      );

  CommunicationLogsProvider._internal(
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
    Stream<List<CommunicationLog>> Function(CommunicationLogsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommunicationLogsProvider._internal(
        (ref) => create(ref as CommunicationLogsRef),
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
  AutoDisposeStreamProviderElement<List<CommunicationLog>> createElement() {
    return _CommunicationLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommunicationLogsProvider && other.providerId == providerId;
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
mixin CommunicationLogsRef
    on AutoDisposeStreamProviderRef<List<CommunicationLog>> {
  /// The parameter `providerId` of this provider.
  String get providerId;
}

class _CommunicationLogsProviderElement
    extends AutoDisposeStreamProviderElement<List<CommunicationLog>>
    with CommunicationLogsRef {
  _CommunicationLogsProviderElement(super.provider);

  @override
  String get providerId => (origin as CommunicationLogsProvider).providerId;
}

String _$remindersStatsHash() => r'a76df3e1c821e33e95bbdf596990cd3dd46934ba';

/// See also [remindersStats].
@ProviderFor(remindersStats)
const remindersStatsProvider = RemindersStatsFamily();

/// See also [remindersStats].
class RemindersStatsFamily extends Family<RemindersStats> {
  /// See also [remindersStats].
  const RemindersStatsFamily();

  /// See also [remindersStats].
  RemindersStatsProvider call(String providerId) {
    return RemindersStatsProvider(providerId);
  }

  @override
  RemindersStatsProvider getProviderOverride(
    covariant RemindersStatsProvider provider,
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
  String? get name => r'remindersStatsProvider';
}

/// See also [remindersStats].
class RemindersStatsProvider extends AutoDisposeProvider<RemindersStats> {
  /// See also [remindersStats].
  RemindersStatsProvider(String providerId)
    : this._internal(
        (ref) => remindersStats(ref as RemindersStatsRef, providerId),
        from: remindersStatsProvider,
        name: r'remindersStatsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$remindersStatsHash,
        dependencies: RemindersStatsFamily._dependencies,
        allTransitiveDependencies:
            RemindersStatsFamily._allTransitiveDependencies,
        providerId: providerId,
      );

  RemindersStatsProvider._internal(
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
    RemindersStats Function(RemindersStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RemindersStatsProvider._internal(
        (ref) => create(ref as RemindersStatsRef),
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
  AutoDisposeProviderElement<RemindersStats> createElement() {
    return _RemindersStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RemindersStatsProvider && other.providerId == providerId;
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
mixin RemindersStatsRef on AutoDisposeProviderRef<RemindersStats> {
  /// The parameter `providerId` of this provider.
  String get providerId;
}

class _RemindersStatsProviderElement
    extends AutoDisposeProviderElement<RemindersStats>
    with RemindersStatsRef {
  _RemindersStatsProviderElement(super.provider);

  @override
  String get providerId => (origin as RemindersStatsProvider).providerId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
