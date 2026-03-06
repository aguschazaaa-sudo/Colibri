// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payments_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PaymentsState {
  List<Payment> get payments => throw _privateConstructorUsedError;
  dynamic get cursor => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  bool get isLoadingMore => throw _privateConstructorUsedError;
  AsyncValue<void> get status => throw _privateConstructorUsedError;

  /// Create a copy of PaymentsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentsStateCopyWith<PaymentsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentsStateCopyWith<$Res> {
  factory $PaymentsStateCopyWith(
    PaymentsState value,
    $Res Function(PaymentsState) then,
  ) = _$PaymentsStateCopyWithImpl<$Res, PaymentsState>;
  @useResult
  $Res call({
    List<Payment> payments,
    dynamic cursor,
    bool hasMore,
    bool isLoadingMore,
    AsyncValue<void> status,
  });
}

/// @nodoc
class _$PaymentsStateCopyWithImpl<$Res, $Val extends PaymentsState>
    implements $PaymentsStateCopyWith<$Res> {
  _$PaymentsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payments = null,
    Object? cursor = freezed,
    Object? hasMore = null,
    Object? isLoadingMore = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            payments:
                null == payments
                    ? _value.payments
                    : payments // ignore: cast_nullable_to_non_nullable
                        as List<Payment>,
            cursor:
                freezed == cursor
                    ? _value.cursor
                    : cursor // ignore: cast_nullable_to_non_nullable
                        as dynamic,
            hasMore:
                null == hasMore
                    ? _value.hasMore
                    : hasMore // ignore: cast_nullable_to_non_nullable
                        as bool,
            isLoadingMore:
                null == isLoadingMore
                    ? _value.isLoadingMore
                    : isLoadingMore // ignore: cast_nullable_to_non_nullable
                        as bool,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as AsyncValue<void>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentsStateImplCopyWith<$Res>
    implements $PaymentsStateCopyWith<$Res> {
  factory _$$PaymentsStateImplCopyWith(
    _$PaymentsStateImpl value,
    $Res Function(_$PaymentsStateImpl) then,
  ) = __$$PaymentsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Payment> payments,
    dynamic cursor,
    bool hasMore,
    bool isLoadingMore,
    AsyncValue<void> status,
  });
}

/// @nodoc
class __$$PaymentsStateImplCopyWithImpl<$Res>
    extends _$PaymentsStateCopyWithImpl<$Res, _$PaymentsStateImpl>
    implements _$$PaymentsStateImplCopyWith<$Res> {
  __$$PaymentsStateImplCopyWithImpl(
    _$PaymentsStateImpl _value,
    $Res Function(_$PaymentsStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PaymentsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payments = null,
    Object? cursor = freezed,
    Object? hasMore = null,
    Object? isLoadingMore = null,
    Object? status = null,
  }) {
    return _then(
      _$PaymentsStateImpl(
        payments:
            null == payments
                ? _value._payments
                : payments // ignore: cast_nullable_to_non_nullable
                    as List<Payment>,
        cursor:
            freezed == cursor
                ? _value.cursor
                : cursor // ignore: cast_nullable_to_non_nullable
                    as dynamic,
        hasMore:
            null == hasMore
                ? _value.hasMore
                : hasMore // ignore: cast_nullable_to_non_nullable
                    as bool,
        isLoadingMore:
            null == isLoadingMore
                ? _value.isLoadingMore
                : isLoadingMore // ignore: cast_nullable_to_non_nullable
                    as bool,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as AsyncValue<void>,
      ),
    );
  }
}

/// @nodoc

class _$PaymentsStateImpl implements _PaymentsState {
  const _$PaymentsStateImpl({
    final List<Payment> payments = const [],
    this.cursor = null,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.status = const AsyncValue.loading(),
  }) : _payments = payments;

  final List<Payment> _payments;
  @override
  @JsonKey()
  List<Payment> get payments {
    if (_payments is EqualUnmodifiableListView) return _payments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_payments);
  }

  @override
  @JsonKey()
  final dynamic cursor;
  @override
  @JsonKey()
  final bool hasMore;
  @override
  @JsonKey()
  final bool isLoadingMore;
  @override
  @JsonKey()
  final AsyncValue<void> status;

  @override
  String toString() {
    return 'PaymentsState(payments: $payments, cursor: $cursor, hasMore: $hasMore, isLoadingMore: $isLoadingMore, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentsStateImpl &&
            const DeepCollectionEquality().equals(other._payments, _payments) &&
            const DeepCollectionEquality().equals(other.cursor, cursor) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_payments),
    const DeepCollectionEquality().hash(cursor),
    hasMore,
    isLoadingMore,
    status,
  );

  /// Create a copy of PaymentsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentsStateImplCopyWith<_$PaymentsStateImpl> get copyWith =>
      __$$PaymentsStateImplCopyWithImpl<_$PaymentsStateImpl>(this, _$identity);
}

abstract class _PaymentsState implements PaymentsState {
  const factory _PaymentsState({
    final List<Payment> payments,
    final dynamic cursor,
    final bool hasMore,
    final bool isLoadingMore,
    final AsyncValue<void> status,
  }) = _$PaymentsStateImpl;

  @override
  List<Payment> get payments;
  @override
  dynamic get cursor;
  @override
  bool get hasMore;
  @override
  bool get isLoadingMore;
  @override
  AsyncValue<void> get status;

  /// Create a copy of PaymentsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentsStateImplCopyWith<_$PaymentsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
