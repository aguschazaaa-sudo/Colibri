// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_pricing_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlanPricingModel _$PlanPricingModelFromJson(Map<String, dynamic> json) {
  return _PlanPricingModel.fromJson(json);
}

/// @nodoc
mixin _$PlanPricingModel {
  double get priceUsd => throw _privateConstructorUsedError;
  double get exchangeRate => throw _privateConstructorUsedError;
  double get priceArs => throw _privateConstructorUsedError;

  /// Serializes this PlanPricingModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlanPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlanPricingModelCopyWith<PlanPricingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlanPricingModelCopyWith<$Res> {
  factory $PlanPricingModelCopyWith(
    PlanPricingModel value,
    $Res Function(PlanPricingModel) then,
  ) = _$PlanPricingModelCopyWithImpl<$Res, PlanPricingModel>;
  @useResult
  $Res call({double priceUsd, double exchangeRate, double priceArs});
}

/// @nodoc
class _$PlanPricingModelCopyWithImpl<$Res, $Val extends PlanPricingModel>
    implements $PlanPricingModelCopyWith<$Res> {
  _$PlanPricingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlanPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? priceUsd = null,
    Object? exchangeRate = null,
    Object? priceArs = null,
  }) {
    return _then(
      _value.copyWith(
            priceUsd:
                null == priceUsd
                    ? _value.priceUsd
                    : priceUsd // ignore: cast_nullable_to_non_nullable
                        as double,
            exchangeRate:
                null == exchangeRate
                    ? _value.exchangeRate
                    : exchangeRate // ignore: cast_nullable_to_non_nullable
                        as double,
            priceArs:
                null == priceArs
                    ? _value.priceArs
                    : priceArs // ignore: cast_nullable_to_non_nullable
                        as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlanPricingModelImplCopyWith<$Res>
    implements $PlanPricingModelCopyWith<$Res> {
  factory _$$PlanPricingModelImplCopyWith(
    _$PlanPricingModelImpl value,
    $Res Function(_$PlanPricingModelImpl) then,
  ) = __$$PlanPricingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double priceUsd, double exchangeRate, double priceArs});
}

/// @nodoc
class __$$PlanPricingModelImplCopyWithImpl<$Res>
    extends _$PlanPricingModelCopyWithImpl<$Res, _$PlanPricingModelImpl>
    implements _$$PlanPricingModelImplCopyWith<$Res> {
  __$$PlanPricingModelImplCopyWithImpl(
    _$PlanPricingModelImpl _value,
    $Res Function(_$PlanPricingModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlanPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? priceUsd = null,
    Object? exchangeRate = null,
    Object? priceArs = null,
  }) {
    return _then(
      _$PlanPricingModelImpl(
        priceUsd:
            null == priceUsd
                ? _value.priceUsd
                : priceUsd // ignore: cast_nullable_to_non_nullable
                    as double,
        exchangeRate:
            null == exchangeRate
                ? _value.exchangeRate
                : exchangeRate // ignore: cast_nullable_to_non_nullable
                    as double,
        priceArs:
            null == priceArs
                ? _value.priceArs
                : priceArs // ignore: cast_nullable_to_non_nullable
                    as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlanPricingModelImpl extends _PlanPricingModel {
  const _$PlanPricingModelImpl({
    required this.priceUsd,
    required this.exchangeRate,
    required this.priceArs,
  }) : super._();

  factory _$PlanPricingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlanPricingModelImplFromJson(json);

  @override
  final double priceUsd;
  @override
  final double exchangeRate;
  @override
  final double priceArs;

  @override
  String toString() {
    return 'PlanPricingModel(priceUsd: $priceUsd, exchangeRate: $exchangeRate, priceArs: $priceArs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlanPricingModelImpl &&
            (identical(other.priceUsd, priceUsd) ||
                other.priceUsd == priceUsd) &&
            (identical(other.exchangeRate, exchangeRate) ||
                other.exchangeRate == exchangeRate) &&
            (identical(other.priceArs, priceArs) ||
                other.priceArs == priceArs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, priceUsd, exchangeRate, priceArs);

  /// Create a copy of PlanPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlanPricingModelImplCopyWith<_$PlanPricingModelImpl> get copyWith =>
      __$$PlanPricingModelImplCopyWithImpl<_$PlanPricingModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlanPricingModelImplToJson(this);
  }
}

abstract class _PlanPricingModel extends PlanPricingModel {
  const factory _PlanPricingModel({
    required final double priceUsd,
    required final double exchangeRate,
    required final double priceArs,
  }) = _$PlanPricingModelImpl;
  const _PlanPricingModel._() : super._();

  factory _PlanPricingModel.fromJson(Map<String, dynamic> json) =
      _$PlanPricingModelImpl.fromJson;

  @override
  double get priceUsd;
  @override
  double get exchangeRate;
  @override
  double get priceArs;

  /// Create a copy of PlanPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlanPricingModelImplCopyWith<_$PlanPricingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SubscriptionPricingModel _$SubscriptionPricingModelFromJson(
  Map<String, dynamic> json,
) {
  return _SubscriptionPricingModel.fromJson(json);
}

/// @nodoc
mixin _$SubscriptionPricingModel {
  PlanPricingModel get basic => throw _privateConstructorUsedError;
  PlanPricingModel get premium => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get lastUpdated => throw _privateConstructorUsedError;

  /// Serializes this SubscriptionPricingModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubscriptionPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubscriptionPricingModelCopyWith<SubscriptionPricingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionPricingModelCopyWith<$Res> {
  factory $SubscriptionPricingModelCopyWith(
    SubscriptionPricingModel value,
    $Res Function(SubscriptionPricingModel) then,
  ) = _$SubscriptionPricingModelCopyWithImpl<$Res, SubscriptionPricingModel>;
  @useResult
  $Res call({
    PlanPricingModel basic,
    PlanPricingModel premium,
    @TimestampConverter() DateTime lastUpdated,
  });

  $PlanPricingModelCopyWith<$Res> get basic;
  $PlanPricingModelCopyWith<$Res> get premium;
}

/// @nodoc
class _$SubscriptionPricingModelCopyWithImpl<
  $Res,
  $Val extends SubscriptionPricingModel
>
    implements $SubscriptionPricingModelCopyWith<$Res> {
  _$SubscriptionPricingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubscriptionPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? basic = null,
    Object? premium = null,
    Object? lastUpdated = null,
  }) {
    return _then(
      _value.copyWith(
            basic:
                null == basic
                    ? _value.basic
                    : basic // ignore: cast_nullable_to_non_nullable
                        as PlanPricingModel,
            premium:
                null == premium
                    ? _value.premium
                    : premium // ignore: cast_nullable_to_non_nullable
                        as PlanPricingModel,
            lastUpdated:
                null == lastUpdated
                    ? _value.lastUpdated
                    : lastUpdated // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }

  /// Create a copy of SubscriptionPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlanPricingModelCopyWith<$Res> get basic {
    return $PlanPricingModelCopyWith<$Res>(_value.basic, (value) {
      return _then(_value.copyWith(basic: value) as $Val);
    });
  }

  /// Create a copy of SubscriptionPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlanPricingModelCopyWith<$Res> get premium {
    return $PlanPricingModelCopyWith<$Res>(_value.premium, (value) {
      return _then(_value.copyWith(premium: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SubscriptionPricingModelImplCopyWith<$Res>
    implements $SubscriptionPricingModelCopyWith<$Res> {
  factory _$$SubscriptionPricingModelImplCopyWith(
    _$SubscriptionPricingModelImpl value,
    $Res Function(_$SubscriptionPricingModelImpl) then,
  ) = __$$SubscriptionPricingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PlanPricingModel basic,
    PlanPricingModel premium,
    @TimestampConverter() DateTime lastUpdated,
  });

  @override
  $PlanPricingModelCopyWith<$Res> get basic;
  @override
  $PlanPricingModelCopyWith<$Res> get premium;
}

/// @nodoc
class __$$SubscriptionPricingModelImplCopyWithImpl<$Res>
    extends
        _$SubscriptionPricingModelCopyWithImpl<
          $Res,
          _$SubscriptionPricingModelImpl
        >
    implements _$$SubscriptionPricingModelImplCopyWith<$Res> {
  __$$SubscriptionPricingModelImplCopyWithImpl(
    _$SubscriptionPricingModelImpl _value,
    $Res Function(_$SubscriptionPricingModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubscriptionPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? basic = null,
    Object? premium = null,
    Object? lastUpdated = null,
  }) {
    return _then(
      _$SubscriptionPricingModelImpl(
        basic:
            null == basic
                ? _value.basic
                : basic // ignore: cast_nullable_to_non_nullable
                    as PlanPricingModel,
        premium:
            null == premium
                ? _value.premium
                : premium // ignore: cast_nullable_to_non_nullable
                    as PlanPricingModel,
        lastUpdated:
            null == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                    as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionPricingModelImpl extends _SubscriptionPricingModel {
  const _$SubscriptionPricingModelImpl({
    required this.basic,
    required this.premium,
    @TimestampConverter() required this.lastUpdated,
  }) : super._();

  factory _$SubscriptionPricingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionPricingModelImplFromJson(json);

  @override
  final PlanPricingModel basic;
  @override
  final PlanPricingModel premium;
  @override
  @TimestampConverter()
  final DateTime lastUpdated;

  @override
  String toString() {
    return 'SubscriptionPricingModel(basic: $basic, premium: $premium, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionPricingModelImpl &&
            (identical(other.basic, basic) || other.basic == basic) &&
            (identical(other.premium, premium) || other.premium == premium) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, basic, premium, lastUpdated);

  /// Create a copy of SubscriptionPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionPricingModelImplCopyWith<_$SubscriptionPricingModelImpl>
  get copyWith => __$$SubscriptionPricingModelImplCopyWithImpl<
    _$SubscriptionPricingModelImpl
  >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionPricingModelImplToJson(this);
  }
}

abstract class _SubscriptionPricingModel extends SubscriptionPricingModel {
  const factory _SubscriptionPricingModel({
    required final PlanPricingModel basic,
    required final PlanPricingModel premium,
    @TimestampConverter() required final DateTime lastUpdated,
  }) = _$SubscriptionPricingModelImpl;
  const _SubscriptionPricingModel._() : super._();

  factory _SubscriptionPricingModel.fromJson(Map<String, dynamic> json) =
      _$SubscriptionPricingModelImpl.fromJson;

  @override
  PlanPricingModel get basic;
  @override
  PlanPricingModel get premium;
  @override
  @TimestampConverter()
  DateTime get lastUpdated;

  /// Create a copy of SubscriptionPricingModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionPricingModelImplCopyWith<_$SubscriptionPricingModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
