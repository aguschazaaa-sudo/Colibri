// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appointment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Appointment {
  String get id => throw _privateConstructorUsedError;
  String get patientId => throw _privateConstructorUsedError;
  String get providerId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get concept => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  double get amountPaid => throw _privateConstructorUsedError;
  AppointmentStatus get status => throw _privateConstructorUsedError;
  String? get recurringAppointmentId => throw _privateConstructorUsedError;

  /// Create a copy of Appointment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppointmentCopyWith<Appointment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppointmentCopyWith<$Res> {
  factory $AppointmentCopyWith(
    Appointment value,
    $Res Function(Appointment) then,
  ) = _$AppointmentCopyWithImpl<$Res, Appointment>;
  @useResult
  $Res call({
    String id,
    String patientId,
    String providerId,
    DateTime date,
    String concept,
    double totalAmount,
    double amountPaid,
    AppointmentStatus status,
    String? recurringAppointmentId,
  });
}

/// @nodoc
class _$AppointmentCopyWithImpl<$Res, $Val extends Appointment>
    implements $AppointmentCopyWith<$Res> {
  _$AppointmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Appointment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientId = null,
    Object? providerId = null,
    Object? date = null,
    Object? concept = null,
    Object? totalAmount = null,
    Object? amountPaid = null,
    Object? status = null,
    Object? recurringAppointmentId = freezed,
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
            date:
                null == date
                    ? _value.date
                    : date // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            concept:
                null == concept
                    ? _value.concept
                    : concept // ignore: cast_nullable_to_non_nullable
                        as String,
            totalAmount:
                null == totalAmount
                    ? _value.totalAmount
                    : totalAmount // ignore: cast_nullable_to_non_nullable
                        as double,
            amountPaid:
                null == amountPaid
                    ? _value.amountPaid
                    : amountPaid // ignore: cast_nullable_to_non_nullable
                        as double,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as AppointmentStatus,
            recurringAppointmentId:
                freezed == recurringAppointmentId
                    ? _value.recurringAppointmentId
                    : recurringAppointmentId // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppointmentImplCopyWith<$Res>
    implements $AppointmentCopyWith<$Res> {
  factory _$$AppointmentImplCopyWith(
    _$AppointmentImpl value,
    $Res Function(_$AppointmentImpl) then,
  ) = __$$AppointmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String patientId,
    String providerId,
    DateTime date,
    String concept,
    double totalAmount,
    double amountPaid,
    AppointmentStatus status,
    String? recurringAppointmentId,
  });
}

/// @nodoc
class __$$AppointmentImplCopyWithImpl<$Res>
    extends _$AppointmentCopyWithImpl<$Res, _$AppointmentImpl>
    implements _$$AppointmentImplCopyWith<$Res> {
  __$$AppointmentImplCopyWithImpl(
    _$AppointmentImpl _value,
    $Res Function(_$AppointmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Appointment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientId = null,
    Object? providerId = null,
    Object? date = null,
    Object? concept = null,
    Object? totalAmount = null,
    Object? amountPaid = null,
    Object? status = null,
    Object? recurringAppointmentId = freezed,
  }) {
    return _then(
      _$AppointmentImpl(
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
        date:
            null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        concept:
            null == concept
                ? _value.concept
                : concept // ignore: cast_nullable_to_non_nullable
                    as String,
        totalAmount:
            null == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                    as double,
        amountPaid:
            null == amountPaid
                ? _value.amountPaid
                : amountPaid // ignore: cast_nullable_to_non_nullable
                    as double,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as AppointmentStatus,
        recurringAppointmentId:
            freezed == recurringAppointmentId
                ? _value.recurringAppointmentId
                : recurringAppointmentId // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc

class _$AppointmentImpl extends _Appointment {
  const _$AppointmentImpl({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.date,
    required this.concept,
    required this.totalAmount,
    this.amountPaid = 0.0,
    this.status = AppointmentStatus.unpaid,
    this.recurringAppointmentId,
  }) : super._();

  @override
  final String id;
  @override
  final String patientId;
  @override
  final String providerId;
  @override
  final DateTime date;
  @override
  final String concept;
  @override
  final double totalAmount;
  @override
  @JsonKey()
  final double amountPaid;
  @override
  @JsonKey()
  final AppointmentStatus status;
  @override
  final String? recurringAppointmentId;

  @override
  String toString() {
    return 'Appointment(id: $id, patientId: $patientId, providerId: $providerId, date: $date, concept: $concept, totalAmount: $totalAmount, amountPaid: $amountPaid, status: $status, recurringAppointmentId: $recurringAppointmentId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppointmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.patientId, patientId) ||
                other.patientId == patientId) &&
            (identical(other.providerId, providerId) ||
                other.providerId == providerId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.concept, concept) || other.concept == concept) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.amountPaid, amountPaid) ||
                other.amountPaid == amountPaid) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.recurringAppointmentId, recurringAppointmentId) ||
                other.recurringAppointmentId == recurringAppointmentId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    patientId,
    providerId,
    date,
    concept,
    totalAmount,
    amountPaid,
    status,
    recurringAppointmentId,
  );

  /// Create a copy of Appointment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppointmentImplCopyWith<_$AppointmentImpl> get copyWith =>
      __$$AppointmentImplCopyWithImpl<_$AppointmentImpl>(this, _$identity);
}

abstract class _Appointment extends Appointment {
  const factory _Appointment({
    required final String id,
    required final String patientId,
    required final String providerId,
    required final DateTime date,
    required final String concept,
    required final double totalAmount,
    final double amountPaid,
    final AppointmentStatus status,
    final String? recurringAppointmentId,
  }) = _$AppointmentImpl;
  const _Appointment._() : super._();

  @override
  String get id;
  @override
  String get patientId;
  @override
  String get providerId;
  @override
  DateTime get date;
  @override
  String get concept;
  @override
  double get totalAmount;
  @override
  double get amountPaid;
  @override
  AppointmentStatus get status;
  @override
  String? get recurringAppointmentId;

  /// Create a copy of Appointment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppointmentImplCopyWith<_$AppointmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
