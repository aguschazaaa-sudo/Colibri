// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'communication_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CommunicationLog {
  String get id => throw _privateConstructorUsedError;
  String get patientId => throw _privateConstructorUsedError;
  String get providerId => throw _privateConstructorUsedError;
  String get messageId => throw _privateConstructorUsedError;
  DateTime get sentAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  double get totalDebtAtThatTime => throw _privateConstructorUsedError;
  String? get patientName => throw _privateConstructorUsedError;

  /// Create a copy of CommunicationLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommunicationLogCopyWith<CommunicationLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommunicationLogCopyWith<$Res> {
  factory $CommunicationLogCopyWith(
    CommunicationLog value,
    $Res Function(CommunicationLog) then,
  ) = _$CommunicationLogCopyWithImpl<$Res, CommunicationLog>;
  @useResult
  $Res call({
    String id,
    String patientId,
    String providerId,
    String messageId,
    DateTime sentAt,
    String status,
    double totalDebtAtThatTime,
    String? patientName,
  });
}

/// @nodoc
class _$CommunicationLogCopyWithImpl<$Res, $Val extends CommunicationLog>
    implements $CommunicationLogCopyWith<$Res> {
  _$CommunicationLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommunicationLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientId = null,
    Object? providerId = null,
    Object? messageId = null,
    Object? sentAt = null,
    Object? status = null,
    Object? totalDebtAtThatTime = null,
    Object? patientName = freezed,
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
            messageId:
                null == messageId
                    ? _value.messageId
                    : messageId // ignore: cast_nullable_to_non_nullable
                        as String,
            sentAt:
                null == sentAt
                    ? _value.sentAt
                    : sentAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            totalDebtAtThatTime:
                null == totalDebtAtThatTime
                    ? _value.totalDebtAtThatTime
                    : totalDebtAtThatTime // ignore: cast_nullable_to_non_nullable
                        as double,
            patientName:
                freezed == patientName
                    ? _value.patientName
                    : patientName // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CommunicationLogImplCopyWith<$Res>
    implements $CommunicationLogCopyWith<$Res> {
  factory _$$CommunicationLogImplCopyWith(
    _$CommunicationLogImpl value,
    $Res Function(_$CommunicationLogImpl) then,
  ) = __$$CommunicationLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String patientId,
    String providerId,
    String messageId,
    DateTime sentAt,
    String status,
    double totalDebtAtThatTime,
    String? patientName,
  });
}

/// @nodoc
class __$$CommunicationLogImplCopyWithImpl<$Res>
    extends _$CommunicationLogCopyWithImpl<$Res, _$CommunicationLogImpl>
    implements _$$CommunicationLogImplCopyWith<$Res> {
  __$$CommunicationLogImplCopyWithImpl(
    _$CommunicationLogImpl _value,
    $Res Function(_$CommunicationLogImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommunicationLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientId = null,
    Object? providerId = null,
    Object? messageId = null,
    Object? sentAt = null,
    Object? status = null,
    Object? totalDebtAtThatTime = null,
    Object? patientName = freezed,
  }) {
    return _then(
      _$CommunicationLogImpl(
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
        messageId:
            null == messageId
                ? _value.messageId
                : messageId // ignore: cast_nullable_to_non_nullable
                    as String,
        sentAt:
            null == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        totalDebtAtThatTime:
            null == totalDebtAtThatTime
                ? _value.totalDebtAtThatTime
                : totalDebtAtThatTime // ignore: cast_nullable_to_non_nullable
                    as double,
        patientName:
            freezed == patientName
                ? _value.patientName
                : patientName // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc

class _$CommunicationLogImpl implements _CommunicationLog {
  const _$CommunicationLogImpl({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.messageId,
    required this.sentAt,
    required this.status,
    required this.totalDebtAtThatTime,
    this.patientName,
  });

  @override
  final String id;
  @override
  final String patientId;
  @override
  final String providerId;
  @override
  final String messageId;
  @override
  final DateTime sentAt;
  @override
  final String status;
  @override
  final double totalDebtAtThatTime;
  @override
  final String? patientName;

  @override
  String toString() {
    return 'CommunicationLog(id: $id, patientId: $patientId, providerId: $providerId, messageId: $messageId, sentAt: $sentAt, status: $status, totalDebtAtThatTime: $totalDebtAtThatTime, patientName: $patientName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommunicationLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.patientId, patientId) ||
                other.patientId == patientId) &&
            (identical(other.providerId, providerId) ||
                other.providerId == providerId) &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalDebtAtThatTime, totalDebtAtThatTime) ||
                other.totalDebtAtThatTime == totalDebtAtThatTime) &&
            (identical(other.patientName, patientName) ||
                other.patientName == patientName));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    patientId,
    providerId,
    messageId,
    sentAt,
    status,
    totalDebtAtThatTime,
    patientName,
  );

  /// Create a copy of CommunicationLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommunicationLogImplCopyWith<_$CommunicationLogImpl> get copyWith =>
      __$$CommunicationLogImplCopyWithImpl<_$CommunicationLogImpl>(
        this,
        _$identity,
      );
}

abstract class _CommunicationLog implements CommunicationLog {
  const factory _CommunicationLog({
    required final String id,
    required final String patientId,
    required final String providerId,
    required final String messageId,
    required final DateTime sentAt,
    required final String status,
    required final double totalDebtAtThatTime,
    final String? patientName,
  }) = _$CommunicationLogImpl;

  @override
  String get id;
  @override
  String get patientId;
  @override
  String get providerId;
  @override
  String get messageId;
  @override
  DateTime get sentAt;
  @override
  String get status;
  @override
  double get totalDebtAtThatTime;
  @override
  String? get patientName;

  /// Create a copy of CommunicationLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommunicationLogImplCopyWith<_$CommunicationLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
