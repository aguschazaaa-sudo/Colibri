// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Payment {
  String get id => throw _privateConstructorUsedError;
  String get patientId => throw _privateConstructorUsedError;
  String get providerId => throw _privateConstructorUsedError;
  String? get appointmentId => throw _privateConstructorUsedError;
  String? get idempotencyKey => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentCopyWith<Payment> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) then) =
      _$PaymentCopyWithImpl<$Res, Payment>;
  @useResult
  $Res call({
    String id,
    String patientId,
    String providerId,
    String? appointmentId,
    String? idempotencyKey,
    double amount,
    DateTime date,
  });
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res, $Val extends Payment>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientId = null,
    Object? providerId = null,
    Object? appointmentId = freezed,
    Object? idempotencyKey = freezed,
    Object? amount = null,
    Object? date = null,
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
            appointmentId:
                freezed == appointmentId
                    ? _value.appointmentId
                    : appointmentId // ignore: cast_nullable_to_non_nullable
                        as String?,
            idempotencyKey:
                freezed == idempotencyKey
                    ? _value.idempotencyKey
                    : idempotencyKey // ignore: cast_nullable_to_non_nullable
                        as String?,
            amount:
                null == amount
                    ? _value.amount
                    : amount // ignore: cast_nullable_to_non_nullable
                        as double,
            date:
                null == date
                    ? _value.date
                    : date // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentImplCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$$PaymentImplCopyWith(
    _$PaymentImpl value,
    $Res Function(_$PaymentImpl) then,
  ) = __$$PaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String patientId,
    String providerId,
    String? appointmentId,
    String? idempotencyKey,
    double amount,
    DateTime date,
  });
}

/// @nodoc
class __$$PaymentImplCopyWithImpl<$Res>
    extends _$PaymentCopyWithImpl<$Res, _$PaymentImpl>
    implements _$$PaymentImplCopyWith<$Res> {
  __$$PaymentImplCopyWithImpl(
    _$PaymentImpl _value,
    $Res Function(_$PaymentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientId = null,
    Object? providerId = null,
    Object? appointmentId = freezed,
    Object? idempotencyKey = freezed,
    Object? amount = null,
    Object? date = null,
  }) {
    return _then(
      _$PaymentImpl(
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
        appointmentId:
            freezed == appointmentId
                ? _value.appointmentId
                : appointmentId // ignore: cast_nullable_to_non_nullable
                    as String?,
        idempotencyKey:
            freezed == idempotencyKey
                ? _value.idempotencyKey
                : idempotencyKey // ignore: cast_nullable_to_non_nullable
                    as String?,
        amount:
            null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                    as double,
        date:
            null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                    as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$PaymentImpl implements _Payment {
  const _$PaymentImpl({
    required this.id,
    required this.patientId,
    required this.providerId,
    this.appointmentId,
    this.idempotencyKey,
    required this.amount,
    required this.date,
  });

  @override
  final String id;
  @override
  final String patientId;
  @override
  final String providerId;
  @override
  final String? appointmentId;
  @override
  final String? idempotencyKey;
  @override
  final double amount;
  @override
  final DateTime date;

  @override
  String toString() {
    return 'Payment(id: $id, patientId: $patientId, providerId: $providerId, appointmentId: $appointmentId, idempotencyKey: $idempotencyKey, amount: $amount, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.patientId, patientId) ||
                other.patientId == patientId) &&
            (identical(other.providerId, providerId) ||
                other.providerId == providerId) &&
            (identical(other.appointmentId, appointmentId) ||
                other.appointmentId == appointmentId) &&
            (identical(other.idempotencyKey, idempotencyKey) ||
                other.idempotencyKey == idempotencyKey) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.date, date) || other.date == date));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    patientId,
    providerId,
    appointmentId,
    idempotencyKey,
    amount,
    date,
  );

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      __$$PaymentImplCopyWithImpl<_$PaymentImpl>(this, _$identity);
}

abstract class _Payment implements Payment {
  const factory _Payment({
    required final String id,
    required final String patientId,
    required final String providerId,
    final String? appointmentId,
    final String? idempotencyKey,
    required final double amount,
    required final DateTime date,
  }) = _$PaymentImpl;

  @override
  String get id;
  @override
  String get patientId;
  @override
  String get providerId;
  @override
  String? get appointmentId;
  @override
  String? get idempotencyKey;
  @override
  double get amount;
  @override
  DateTime get date;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
