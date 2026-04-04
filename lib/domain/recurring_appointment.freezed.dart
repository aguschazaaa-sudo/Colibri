// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_appointment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RecurringAppointment {
  String get id => throw _privateConstructorUsedError;
  String get patientId => throw _privateConstructorUsedError;
  String get providerId => throw _privateConstructorUsedError;
  String get concept => throw _privateConstructorUsedError;
  double get defaultAmount => throw _privateConstructorUsedError;
  Frequency get frequency => throw _privateConstructorUsedError;
  DateTime get baseDate => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;

  /// Optional session duration in minutes. When null the Cloud Function falls
  /// back to the provider's [defaultSessionDurationMinutes], then to 45 min.
  int? get defaultSessionDurationMinutes => throw _privateConstructorUsedError;

  /// List of dateKey strings (e.g. "2026-04-10") for occurrences that have
  /// been individually cancelled by the provider. The cron skips these dates
  /// and the timeline suppresses ghost cards for them.
  List<String> get cancelledDates => throw _privateConstructorUsedError;

  /// Create a copy of RecurringAppointment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecurringAppointmentCopyWith<RecurringAppointment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecurringAppointmentCopyWith<$Res> {
  factory $RecurringAppointmentCopyWith(
    RecurringAppointment value,
    $Res Function(RecurringAppointment) then,
  ) = _$RecurringAppointmentCopyWithImpl<$Res, RecurringAppointment>;
  @useResult
  $Res call({
    String id,
    String patientId,
    String providerId,
    String concept,
    double defaultAmount,
    Frequency frequency,
    DateTime baseDate,
    bool active,
    DateTime? endDate,
    int? defaultSessionDurationMinutes,
    List<String> cancelledDates,
  });
}

/// @nodoc
class _$RecurringAppointmentCopyWithImpl<
  $Res,
  $Val extends RecurringAppointment
>
    implements $RecurringAppointmentCopyWith<$Res> {
  _$RecurringAppointmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecurringAppointment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientId = null,
    Object? providerId = null,
    Object? concept = null,
    Object? defaultAmount = null,
    Object? frequency = null,
    Object? baseDate = null,
    Object? active = null,
    Object? endDate = freezed,
    Object? defaultSessionDurationMinutes = freezed,
    Object? cancelledDates = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            patientId:
                null == patientId
                    ? _value.patientId
                    : patientId // ignore: cast_nullable_to_non_nullable
                        as String,
            providerId:
                null == providerId
                    ? _value.providerId
                    : providerId // ignore: cast_nullable_to_non_nullable
                        as String,
            concept:
                null == concept
                    ? _value.concept
                    : concept // ignore: cast_nullable_to_non_nullable
                        as String,
            defaultAmount:
                null == defaultAmount
                    ? _value.defaultAmount
                    : defaultAmount // ignore: cast_nullable_to_non_nullable
                        as double,
            frequency:
                null == frequency
                    ? _value.frequency
                    : frequency // ignore: cast_nullable_to_non_nullable
                        as Frequency,
            baseDate:
                null == baseDate
                    ? _value.baseDate
                    : baseDate // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            active:
                null == active
                    ? _value.active
                    : active // ignore: cast_nullable_to_non_nullable
                        as bool,
            endDate:
                freezed == endDate
                    ? _value.endDate
                    : endDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            defaultSessionDurationMinutes:
                freezed == defaultSessionDurationMinutes
                    ? _value.defaultSessionDurationMinutes
                    : defaultSessionDurationMinutes // ignore: cast_nullable_to_non_nullable
                        as int?,
            cancelledDates:
                null == cancelledDates
                    ? _value.cancelledDates
                    : cancelledDates // ignore: cast_nullable_to_non_nullable
                        as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecurringAppointmentImplCopyWith<$Res>
    implements $RecurringAppointmentCopyWith<$Res> {
  factory _$$RecurringAppointmentImplCopyWith(
    _$RecurringAppointmentImpl value,
    $Res Function(_$RecurringAppointmentImpl) then,
  ) = __$$RecurringAppointmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String patientId,
    String providerId,
    String concept,
    double defaultAmount,
    Frequency frequency,
    DateTime baseDate,
    bool active,
    DateTime? endDate,
    int? defaultSessionDurationMinutes,
    List<String> cancelledDates,
  });
}

/// @nodoc
class __$$RecurringAppointmentImplCopyWithImpl<$Res>
    extends _$RecurringAppointmentCopyWithImpl<$Res, _$RecurringAppointmentImpl>
    implements _$$RecurringAppointmentImplCopyWith<$Res> {
  __$$RecurringAppointmentImplCopyWithImpl(
    _$RecurringAppointmentImpl _value,
    $Res Function(_$RecurringAppointmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecurringAppointment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientId = null,
    Object? providerId = null,
    Object? concept = null,
    Object? defaultAmount = null,
    Object? frequency = null,
    Object? baseDate = null,
    Object? active = null,
    Object? endDate = freezed,
    Object? defaultSessionDurationMinutes = freezed,
    Object? cancelledDates = null,
  }) {
    return _then(
      _$RecurringAppointmentImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        patientId:
            null == patientId
                ? _value.patientId
                : patientId // ignore: cast_nullable_to_non_nullable
                    as String,
        providerId:
            null == providerId
                ? _value.providerId
                : providerId // ignore: cast_nullable_to_non_nullable
                    as String,
        concept:
            null == concept
                ? _value.concept
                : concept // ignore: cast_nullable_to_non_nullable
                    as String,
        defaultAmount:
            null == defaultAmount
                ? _value.defaultAmount
                : defaultAmount // ignore: cast_nullable_to_non_nullable
                    as double,
        frequency:
            null == frequency
                ? _value.frequency
                : frequency // ignore: cast_nullable_to_non_nullable
                    as Frequency,
        baseDate:
            null == baseDate
                ? _value.baseDate
                : baseDate // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        active:
            null == active
                ? _value.active
                : active // ignore: cast_nullable_to_non_nullable
                    as bool,
        endDate:
            freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        defaultSessionDurationMinutes:
            freezed == defaultSessionDurationMinutes
                ? _value.defaultSessionDurationMinutes
                : defaultSessionDurationMinutes // ignore: cast_nullable_to_non_nullable
                    as int?,
        cancelledDates:
            null == cancelledDates
                ? _value._cancelledDates
                : cancelledDates // ignore: cast_nullable_to_non_nullable
                    as List<String>,
      ),
    );
  }
}

/// @nodoc

class _$RecurringAppointmentImpl implements _RecurringAppointment {
  const _$RecurringAppointmentImpl({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.concept,
    required this.defaultAmount,
    required this.frequency,
    required this.baseDate,
    this.active = true,
    this.endDate,
    this.defaultSessionDurationMinutes,
    final List<String> cancelledDates = const [],
  }) : _cancelledDates = cancelledDates;

  @override
  final String id;
  @override
  final String patientId;
  @override
  final String providerId;
  @override
  final String concept;
  @override
  final double defaultAmount;
  @override
  final Frequency frequency;
  @override
  final DateTime baseDate;
  @override
  @JsonKey()
  final bool active;
  @override
  final DateTime? endDate;

  /// Optional session duration in minutes. When null the Cloud Function falls
  /// back to the provider's [defaultSessionDurationMinutes], then to 45 min.
  @override
  final int? defaultSessionDurationMinutes;

  /// List of dateKey strings (e.g. "2026-04-10") for occurrences that have
  /// been individually cancelled by the provider. The cron skips these dates
  /// and the timeline suppresses ghost cards for them.
  final List<String> _cancelledDates;

  /// List of dateKey strings (e.g. "2026-04-10") for occurrences that have
  /// been individually cancelled by the provider. The cron skips these dates
  /// and the timeline suppresses ghost cards for them.
  @override
  @JsonKey()
  List<String> get cancelledDates {
    if (_cancelledDates is EqualUnmodifiableListView) return _cancelledDates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cancelledDates);
  }

  @override
  String toString() {
    return 'RecurringAppointment(id: $id, patientId: $patientId, providerId: $providerId, concept: $concept, defaultAmount: $defaultAmount, frequency: $frequency, baseDate: $baseDate, active: $active, endDate: $endDate, defaultSessionDurationMinutes: $defaultSessionDurationMinutes, cancelledDates: $cancelledDates)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecurringAppointmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.patientId, patientId) ||
                other.patientId == patientId) &&
            (identical(other.providerId, providerId) ||
                other.providerId == providerId) &&
            (identical(other.concept, concept) || other.concept == concept) &&
            (identical(other.defaultAmount, defaultAmount) ||
                other.defaultAmount == defaultAmount) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.baseDate, baseDate) ||
                other.baseDate == baseDate) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(
                  other.defaultSessionDurationMinutes,
                  defaultSessionDurationMinutes,
                ) ||
                other.defaultSessionDurationMinutes ==
                    defaultSessionDurationMinutes) &&
            const DeepCollectionEquality().equals(
              other._cancelledDates,
              _cancelledDates,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    patientId,
    providerId,
    concept,
    defaultAmount,
    frequency,
    baseDate,
    active,
    endDate,
    defaultSessionDurationMinutes,
    const DeepCollectionEquality().hash(_cancelledDates),
  );

  /// Create a copy of RecurringAppointment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecurringAppointmentImplCopyWith<_$RecurringAppointmentImpl>
  get copyWith =>
      __$$RecurringAppointmentImplCopyWithImpl<_$RecurringAppointmentImpl>(
        this,
        _$identity,
      );
}

abstract class _RecurringAppointment implements RecurringAppointment {
  const factory _RecurringAppointment({
    required final String id,
    required final String patientId,
    required final String providerId,
    required final String concept,
    required final double defaultAmount,
    required final Frequency frequency,
    required final DateTime baseDate,
    final bool active,
    final DateTime? endDate,
    final int? defaultSessionDurationMinutes,
    final List<String> cancelledDates,
  }) = _$RecurringAppointmentImpl;

  @override
  String get id;
  @override
  String get patientId;
  @override
  String get providerId;
  @override
  String get concept;
  @override
  double get defaultAmount;
  @override
  Frequency get frequency;
  @override
  DateTime get baseDate;
  @override
  bool get active;
  @override
  DateTime? get endDate;

  /// Optional session duration in minutes. When null the Cloud Function falls
  /// back to the provider's [defaultSessionDurationMinutes], then to 45 min.
  @override
  int? get defaultSessionDurationMinutes;

  /// List of dateKey strings (e.g. "2026-04-10") for occurrences that have
  /// been individually cancelled by the provider. The cron skips these dates
  /// and the timeline suppresses ghost cards for them.
  @override
  List<String> get cancelledDates;

  /// Create a copy of RecurringAppointment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecurringAppointmentImplCopyWith<_$RecurringAppointmentImpl>
  get copyWith => throw _privateConstructorUsedError;
}
