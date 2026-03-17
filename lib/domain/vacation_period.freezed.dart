// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vacation_period.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VacationPeriod _$VacationPeriodFromJson(Map<String, dynamic> json) {
  return _VacationPeriod.fromJson(json);
}

/// @nodoc
mixin _$VacationPeriod {
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;

  /// Serializes this VacationPeriod to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VacationPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VacationPeriodCopyWith<VacationPeriod> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VacationPeriodCopyWith<$Res> {
  factory $VacationPeriodCopyWith(
    VacationPeriod value,
    $Res Function(VacationPeriod) then,
  ) = _$VacationPeriodCopyWithImpl<$Res, VacationPeriod>;
  @useResult
  $Res call({DateTime startDate, DateTime endDate});
}

/// @nodoc
class _$VacationPeriodCopyWithImpl<$Res, $Val extends VacationPeriod>
    implements $VacationPeriodCopyWith<$Res> {
  _$VacationPeriodCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VacationPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? startDate = null, Object? endDate = null}) {
    return _then(
      _value.copyWith(
            startDate:
                null == startDate
                    ? _value.startDate
                    : startDate // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            endDate:
                null == endDate
                    ? _value.endDate
                    : endDate // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VacationPeriodImplCopyWith<$Res>
    implements $VacationPeriodCopyWith<$Res> {
  factory _$$VacationPeriodImplCopyWith(
    _$VacationPeriodImpl value,
    $Res Function(_$VacationPeriodImpl) then,
  ) = __$$VacationPeriodImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime startDate, DateTime endDate});
}

/// @nodoc
class __$$VacationPeriodImplCopyWithImpl<$Res>
    extends _$VacationPeriodCopyWithImpl<$Res, _$VacationPeriodImpl>
    implements _$$VacationPeriodImplCopyWith<$Res> {
  __$$VacationPeriodImplCopyWithImpl(
    _$VacationPeriodImpl _value,
    $Res Function(_$VacationPeriodImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VacationPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? startDate = null, Object? endDate = null}) {
    return _then(
      _$VacationPeriodImpl(
        startDate:
            null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        endDate:
            null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                    as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VacationPeriodImpl implements _VacationPeriod {
  const _$VacationPeriodImpl({required this.startDate, required this.endDate});

  factory _$VacationPeriodImpl.fromJson(Map<String, dynamic> json) =>
      _$$VacationPeriodImplFromJson(json);

  @override
  final DateTime startDate;
  @override
  final DateTime endDate;

  @override
  String toString() {
    return 'VacationPeriod(startDate: $startDate, endDate: $endDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VacationPeriodImpl &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, startDate, endDate);

  /// Create a copy of VacationPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VacationPeriodImplCopyWith<_$VacationPeriodImpl> get copyWith =>
      __$$VacationPeriodImplCopyWithImpl<_$VacationPeriodImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VacationPeriodImplToJson(this);
  }
}

abstract class _VacationPeriod implements VacationPeriod {
  const factory _VacationPeriod({
    required final DateTime startDate,
    required final DateTime endDate,
  }) = _$VacationPeriodImpl;

  factory _VacationPeriod.fromJson(Map<String, dynamic> json) =
      _$VacationPeriodImpl.fromJson;

  @override
  DateTime get startDate;
  @override
  DateTime get endDate;

  /// Create a copy of VacationPeriod
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VacationPeriodImplCopyWith<_$VacationPeriodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
