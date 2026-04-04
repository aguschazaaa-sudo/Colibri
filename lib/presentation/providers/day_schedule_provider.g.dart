// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_schedule_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allRecurringAppointmentsHash() =>
    r'c4ab3c30729e94fd40f3f6511af4aa48bc91b6f8';

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

/// Watches all [RecurringAppointment]s for a provider across all patients.
///
/// Copied from [allRecurringAppointments].
@ProviderFor(allRecurringAppointments)
const allRecurringAppointmentsProvider = AllRecurringAppointmentsFamily();

/// Watches all [RecurringAppointment]s for a provider across all patients.
///
/// Copied from [allRecurringAppointments].
class AllRecurringAppointmentsFamily
    extends Family<AsyncValue<List<RecurringAppointment>>> {
  /// Watches all [RecurringAppointment]s for a provider across all patients.
  ///
  /// Copied from [allRecurringAppointments].
  const AllRecurringAppointmentsFamily();

  /// Watches all [RecurringAppointment]s for a provider across all patients.
  ///
  /// Copied from [allRecurringAppointments].
  AllRecurringAppointmentsProvider call(String providerId) {
    return AllRecurringAppointmentsProvider(providerId);
  }

  @override
  AllRecurringAppointmentsProvider getProviderOverride(
    covariant AllRecurringAppointmentsProvider provider,
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
  String? get name => r'allRecurringAppointmentsProvider';
}

/// Watches all [RecurringAppointment]s for a provider across all patients.
///
/// Copied from [allRecurringAppointments].
class AllRecurringAppointmentsProvider
    extends AutoDisposeStreamProvider<List<RecurringAppointment>> {
  /// Watches all [RecurringAppointment]s for a provider across all patients.
  ///
  /// Copied from [allRecurringAppointments].
  AllRecurringAppointmentsProvider(String providerId)
    : this._internal(
        (ref) => allRecurringAppointments(
          ref as AllRecurringAppointmentsRef,
          providerId,
        ),
        from: allRecurringAppointmentsProvider,
        name: r'allRecurringAppointmentsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$allRecurringAppointmentsHash,
        dependencies: AllRecurringAppointmentsFamily._dependencies,
        allTransitiveDependencies:
            AllRecurringAppointmentsFamily._allTransitiveDependencies,
        providerId: providerId,
      );

  AllRecurringAppointmentsProvider._internal(
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
    Stream<List<RecurringAppointment>> Function(
      AllRecurringAppointmentsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AllRecurringAppointmentsProvider._internal(
        (ref) => create(ref as AllRecurringAppointmentsRef),
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
  AutoDisposeStreamProviderElement<List<RecurringAppointment>> createElement() {
    return _AllRecurringAppointmentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AllRecurringAppointmentsProvider &&
        other.providerId == providerId;
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
mixin AllRecurringAppointmentsRef
    on AutoDisposeStreamProviderRef<List<RecurringAppointment>> {
  /// The parameter `providerId` of this provider.
  String get providerId;
}

class _AllRecurringAppointmentsProviderElement
    extends AutoDisposeStreamProviderElement<List<RecurringAppointment>>
    with AllRecurringAppointmentsRef {
  _AllRecurringAppointmentsProviderElement(super.provider);

  @override
  String get providerId =>
      (origin as AllRecurringAppointmentsProvider).providerId;
}

String _$dayScheduleHash() => r'86807162424a6785d15e1bf001674c0d7e914879';

/// Combines all appointments and recurring rules for [providerId] on [date],
/// returning a unified list of [DayScheduleItem]s.
///
/// Deduplicates projected items that already have a confirmed appointment.
///
/// Copied from [daySchedule].
@ProviderFor(daySchedule)
const dayScheduleProvider = DayScheduleFamily();

/// Combines all appointments and recurring rules for [providerId] on [date],
/// returning a unified list of [DayScheduleItem]s.
///
/// Deduplicates projected items that already have a confirmed appointment.
///
/// Copied from [daySchedule].
class DayScheduleFamily extends Family<AsyncValue<List<DayScheduleItem>>> {
  /// Combines all appointments and recurring rules for [providerId] on [date],
  /// returning a unified list of [DayScheduleItem]s.
  ///
  /// Deduplicates projected items that already have a confirmed appointment.
  ///
  /// Copied from [daySchedule].
  const DayScheduleFamily();

  /// Combines all appointments and recurring rules for [providerId] on [date],
  /// returning a unified list of [DayScheduleItem]s.
  ///
  /// Deduplicates projected items that already have a confirmed appointment.
  ///
  /// Copied from [daySchedule].
  DayScheduleProvider call({
    required String providerId,
    required DateTime date,
  }) {
    return DayScheduleProvider(providerId: providerId, date: date);
  }

  @override
  DayScheduleProvider getProviderOverride(
    covariant DayScheduleProvider provider,
  ) {
    return call(providerId: provider.providerId, date: provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dayScheduleProvider';
}

/// Combines all appointments and recurring rules for [providerId] on [date],
/// returning a unified list of [DayScheduleItem]s.
///
/// Deduplicates projected items that already have a confirmed appointment.
///
/// Copied from [daySchedule].
class DayScheduleProvider
    extends AutoDisposeProvider<AsyncValue<List<DayScheduleItem>>> {
  /// Combines all appointments and recurring rules for [providerId] on [date],
  /// returning a unified list of [DayScheduleItem]s.
  ///
  /// Deduplicates projected items that already have a confirmed appointment.
  ///
  /// Copied from [daySchedule].
  DayScheduleProvider({required String providerId, required DateTime date})
    : this._internal(
        (ref) => daySchedule(
          ref as DayScheduleRef,
          providerId: providerId,
          date: date,
        ),
        from: dayScheduleProvider,
        name: r'dayScheduleProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$dayScheduleHash,
        dependencies: DayScheduleFamily._dependencies,
        allTransitiveDependencies: DayScheduleFamily._allTransitiveDependencies,
        providerId: providerId,
        date: date,
      );

  DayScheduleProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.providerId,
    required this.date,
  }) : super.internal();

  final String providerId;
  final DateTime date;

  @override
  Override overrideWith(
    AsyncValue<List<DayScheduleItem>> Function(DayScheduleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DayScheduleProvider._internal(
        (ref) => create(ref as DayScheduleRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        providerId: providerId,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<AsyncValue<List<DayScheduleItem>>>
  createElement() {
    return _DayScheduleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DayScheduleProvider &&
        other.providerId == providerId &&
        other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, providerId.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DayScheduleRef
    on AutoDisposeProviderRef<AsyncValue<List<DayScheduleItem>>> {
  /// The parameter `providerId` of this provider.
  String get providerId;

  /// The parameter `date` of this provider.
  DateTime get date;
}

class _DayScheduleProviderElement
    extends AutoDisposeProviderElement<AsyncValue<List<DayScheduleItem>>>
    with DayScheduleRef {
  _DayScheduleProviderElement(super.provider);

  @override
  String get providerId => (origin as DayScheduleProvider).providerId;
  @override
  DateTime get date => (origin as DayScheduleProvider).date;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
