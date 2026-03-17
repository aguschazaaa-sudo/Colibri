// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_pricing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PlanPricing {
  double get priceUsd => throw _privateConstructorUsedError;
  double get exchangeRate => throw _privateConstructorUsedError;
  double get priceArs => throw _privateConstructorUsedError;

  /// Create a copy of PlanPricing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlanPricingCopyWith<PlanPricing> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlanPricingCopyWith<$Res> {
  factory $PlanPricingCopyWith(
    PlanPricing value,
    $Res Function(PlanPricing) then,
  ) = _$PlanPricingCopyWithImpl<$Res, PlanPricing>;
  @useResult
  $Res call({double priceUsd, double exchangeRate, double priceArs});
}

/// @nodoc
class _$PlanPricingCopyWithImpl<$Res, $Val extends PlanPricing>
    implements $PlanPricingCopyWith<$Res> {
  _$PlanPricingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlanPricing
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
abstract class _$$PlanPricingImplCopyWith<$Res>
    implements $PlanPricingCopyWith<$Res> {
  factory _$$PlanPricingImplCopyWith(
    _$PlanPricingImpl value,
    $Res Function(_$PlanPricingImpl) then,
  ) = __$$PlanPricingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double priceUsd, double exchangeRate, double priceArs});
}

/// @nodoc
class __$$PlanPricingImplCopyWithImpl<$Res>
    extends _$PlanPricingCopyWithImpl<$Res, _$PlanPricingImpl>
    implements _$$PlanPricingImplCopyWith<$Res> {
  __$$PlanPricingImplCopyWithImpl(
    _$PlanPricingImpl _value,
    $Res Function(_$PlanPricingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlanPricing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? priceUsd = null,
    Object? exchangeRate = null,
    Object? priceArs = null,
  }) {
    return _then(
      _$PlanPricingImpl(
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

class _$PlanPricingImpl implements _PlanPricing {
  const _$PlanPricingImpl({
    required this.priceUsd,
    required this.exchangeRate,
    required this.priceArs,
  });

  @override
  final double priceUsd;
  @override
  final double exchangeRate;
  @override
  final double priceArs;

  @override
  String toString() {
    return 'PlanPricing(priceUsd: $priceUsd, exchangeRate: $exchangeRate, priceArs: $priceArs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlanPricingImpl &&
            (identical(other.priceUsd, priceUsd) ||
                other.priceUsd == priceUsd) &&
            (identical(other.exchangeRate, exchangeRate) ||
                other.exchangeRate == exchangeRate) &&
            (identical(other.priceArs, priceArs) ||
                other.priceArs == priceArs));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, priceUsd, exchangeRate, priceArs);

  /// Create a copy of PlanPricing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlanPricingImplCopyWith<_$PlanPricingImpl> get copyWith =>
      __$$PlanPricingImplCopyWithImpl<_$PlanPricingImpl>(this, _$identity);
}

abstract class _PlanPricing implements PlanPricing {
  const factory _PlanPricing({
    required final double priceUsd,
    required final double exchangeRate,
    required final double priceArs,
  }) = _$PlanPricingImpl;

  @override
  double get priceUsd;
  @override
  double get exchangeRate;
  @override
  double get priceArs;

  /// Create a copy of PlanPricing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlanPricingImplCopyWith<_$PlanPricingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SubscriptionPricing {
  PlanPricing get basic => throw _privateConstructorUsedError;
  PlanPricing get premium => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;

  /// Create a copy of SubscriptionPricing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubscriptionPricingCopyWith<SubscriptionPricing> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionPricingCopyWith<$Res> {
  factory $SubscriptionPricingCopyWith(
    SubscriptionPricing value,
    $Res Function(SubscriptionPricing) then,
  ) = _$SubscriptionPricingCopyWithImpl<$Res, SubscriptionPricing>;
  @useResult
  $Res call({PlanPricing basic, PlanPricing premium, DateTime lastUpdated});

  $PlanPricingCopyWith<$Res> get basic;
  $PlanPricingCopyWith<$Res> get premium;
}

/// @nodoc
class _$SubscriptionPricingCopyWithImpl<$Res, $Val extends SubscriptionPricing>
    implements $SubscriptionPricingCopyWith<$Res> {
  _$SubscriptionPricingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubscriptionPricing
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
                        as PlanPricing,
            premium:
                null == premium
                    ? _value.premium
                    : premium // ignore: cast_nullable_to_non_nullable
                        as PlanPricing,
            lastUpdated:
                null == lastUpdated
                    ? _value.lastUpdated
                    : lastUpdated // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }

  /// Create a copy of SubscriptionPricing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlanPricingCopyWith<$Res> get basic {
    return $PlanPricingCopyWith<$Res>(_value.basic, (value) {
      return _then(_value.copyWith(basic: value) as $Val);
    });
  }

  /// Create a copy of SubscriptionPricing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlanPricingCopyWith<$Res> get premium {
    return $PlanPricingCopyWith<$Res>(_value.premium, (value) {
      return _then(_value.copyWith(premium: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SubscriptionPricingImplCopyWith<$Res>
    implements $SubscriptionPricingCopyWith<$Res> {
  factory _$$SubscriptionPricingImplCopyWith(
    _$SubscriptionPricingImpl value,
    $Res Function(_$SubscriptionPricingImpl) then,
  ) = __$$SubscriptionPricingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PlanPricing basic, PlanPricing premium, DateTime lastUpdated});

  @override
  $PlanPricingCopyWith<$Res> get basic;
  @override
  $PlanPricingCopyWith<$Res> get premium;
}

/// @nodoc
class __$$SubscriptionPricingImplCopyWithImpl<$Res>
    extends _$SubscriptionPricingCopyWithImpl<$Res, _$SubscriptionPricingImpl>
    implements _$$SubscriptionPricingImplCopyWith<$Res> {
  __$$SubscriptionPricingImplCopyWithImpl(
    _$SubscriptionPricingImpl _value,
    $Res Function(_$SubscriptionPricingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubscriptionPricing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? basic = null,
    Object? premium = null,
    Object? lastUpdated = null,
  }) {
    return _then(
      _$SubscriptionPricingImpl(
        basic:
            null == basic
                ? _value.basic
                : basic // ignore: cast_nullable_to_non_nullable
                    as PlanPricing,
        premium:
            null == premium
                ? _value.premium
                : premium // ignore: cast_nullable_to_non_nullable
                    as PlanPricing,
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

class _$SubscriptionPricingImpl implements _SubscriptionPricing {
  const _$SubscriptionPricingImpl({
    required this.basic,
    required this.premium,
    required this.lastUpdated,
  });

  @override
  final PlanPricing basic;
  @override
  final PlanPricing premium;
  @override
  final DateTime lastUpdated;

  @override
  String toString() {
    return 'SubscriptionPricing(basic: $basic, premium: $premium, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionPricingImpl &&
            (identical(other.basic, basic) || other.basic == basic) &&
            (identical(other.premium, premium) || other.premium == premium) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @override
  int get hashCode => Object.hash(runtimeType, basic, premium, lastUpdated);

  /// Create a copy of SubscriptionPricing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionPricingImplCopyWith<_$SubscriptionPricingImpl> get copyWith =>
      __$$SubscriptionPricingImplCopyWithImpl<_$SubscriptionPricingImpl>(
        this,
        _$identity,
      );
}

abstract class _SubscriptionPricing implements SubscriptionPricing {
  const factory _SubscriptionPricing({
    required final PlanPricing basic,
    required final PlanPricing premium,
    required final DateTime lastUpdated,
  }) = _$SubscriptionPricingImpl;

  @override
  PlanPricing get basic;
  @override
  PlanPricing get premium;
  @override
  DateTime get lastUpdated;

  /// Create a copy of SubscriptionPricing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionPricingImplCopyWith<_$SubscriptionPricingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
