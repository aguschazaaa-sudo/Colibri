// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Failure {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) serverError,
    required TResult Function(String message) validationError,
    required TResult Function(String message) unauthorized,
    required TResult Function(String message) notFound,
    required TResult Function(String message) unknown,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() invalidCredentials,
    required TResult Function() weakPassword,
    required TResult Function() networkError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? serverError,
    TResult? Function(String message)? validationError,
    TResult? Function(String message)? unauthorized,
    TResult? Function(String message)? notFound,
    TResult? Function(String message)? unknown,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? invalidCredentials,
    TResult? Function()? weakPassword,
    TResult? Function()? networkError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? serverError,
    TResult Function(String message)? validationError,
    TResult Function(String message)? unauthorized,
    TResult Function(String message)? notFound,
    TResult Function(String message)? unknown,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? invalidCredentials,
    TResult Function()? weakPassword,
    TResult Function()? networkError,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ServerError value) serverError,
    required TResult Function(_ValidationError value) validationError,
    required TResult Function(_Unauthorized value) unauthorized,
    required TResult Function(_NotFound value) notFound,
    required TResult Function(_Unknown value) unknown,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_NetworkError value) networkError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ServerError value)? serverError,
    TResult? Function(_ValidationError value)? validationError,
    TResult? Function(_Unauthorized value)? unauthorized,
    TResult? Function(_NotFound value)? notFound,
    TResult? Function(_Unknown value)? unknown,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_NetworkError value)? networkError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ServerError value)? serverError,
    TResult Function(_ValidationError value)? validationError,
    TResult Function(_Unauthorized value)? unauthorized,
    TResult Function(_NotFound value)? notFound,
    TResult Function(_Unknown value)? unknown,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_NetworkError value)? networkError,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FailureCopyWith<$Res> {
  factory $FailureCopyWith(Failure value, $Res Function(Failure) then) =
      _$FailureCopyWithImpl<$Res, Failure>;
}

/// @nodoc
class _$FailureCopyWithImpl<$Res, $Val extends Failure>
    implements $FailureCopyWith<$Res> {
  _$FailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ServerErrorImplCopyWith<$Res> {
  factory _$$ServerErrorImplCopyWith(
    _$ServerErrorImpl value,
    $Res Function(_$ServerErrorImpl) then,
  ) = __$$ServerErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ServerErrorImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ServerErrorImpl>
    implements _$$ServerErrorImplCopyWith<$Res> {
  __$$ServerErrorImplCopyWithImpl(
    _$ServerErrorImpl _value,
    $Res Function(_$ServerErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$ServerErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                as String,
      ),
    );
  }
}

/// @nodoc

class _$ServerErrorImpl extends _ServerError {
  const _$ServerErrorImpl(this.message) : super._();

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.serverError(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServerErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServerErrorImplCopyWith<_$ServerErrorImpl> get copyWith =>
      __$$ServerErrorImplCopyWithImpl<_$ServerErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) serverError,
    required TResult Function(String message) validationError,
    required TResult Function(String message) unauthorized,
    required TResult Function(String message) notFound,
    required TResult Function(String message) unknown,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() invalidCredentials,
    required TResult Function() weakPassword,
    required TResult Function() networkError,
  }) {
    return serverError(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? serverError,
    TResult? Function(String message)? validationError,
    TResult? Function(String message)? unauthorized,
    TResult? Function(String message)? notFound,
    TResult? Function(String message)? unknown,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? invalidCredentials,
    TResult? Function()? weakPassword,
    TResult? Function()? networkError,
  }) {
    return serverError?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? serverError,
    TResult Function(String message)? validationError,
    TResult Function(String message)? unauthorized,
    TResult Function(String message)? notFound,
    TResult Function(String message)? unknown,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? invalidCredentials,
    TResult Function()? weakPassword,
    TResult Function()? networkError,
    required TResult orElse(),
  }) {
    if (serverError != null) {
      return serverError(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ServerError value) serverError,
    required TResult Function(_ValidationError value) validationError,
    required TResult Function(_Unauthorized value) unauthorized,
    required TResult Function(_NotFound value) notFound,
    required TResult Function(_Unknown value) unknown,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_NetworkError value) networkError,
  }) {
    return serverError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ServerError value)? serverError,
    TResult? Function(_ValidationError value)? validationError,
    TResult? Function(_Unauthorized value)? unauthorized,
    TResult? Function(_NotFound value)? notFound,
    TResult? Function(_Unknown value)? unknown,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_NetworkError value)? networkError,
  }) {
    return serverError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ServerError value)? serverError,
    TResult Function(_ValidationError value)? validationError,
    TResult Function(_Unauthorized value)? unauthorized,
    TResult Function(_NotFound value)? notFound,
    TResult Function(_Unknown value)? unknown,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_NetworkError value)? networkError,
    required TResult orElse(),
  }) {
    if (serverError != null) {
      return serverError(this);
    }
    return orElse();
  }
}

abstract class _ServerError extends Failure {
  const factory _ServerError(final String message) = _$ServerErrorImpl;
  const _ServerError._() : super._();

  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServerErrorImplCopyWith<_$ServerErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ValidationErrorImplCopyWith<$Res> {
  factory _$$ValidationErrorImplCopyWith(
    _$ValidationErrorImpl value,
    $Res Function(_$ValidationErrorImpl) then,
  ) = __$$ValidationErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ValidationErrorImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ValidationErrorImpl>
    implements _$$ValidationErrorImplCopyWith<$Res> {
  __$$ValidationErrorImplCopyWithImpl(
    _$ValidationErrorImpl _value,
    $Res Function(_$ValidationErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$ValidationErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                as String,
      ),
    );
  }
}

/// @nodoc

class _$ValidationErrorImpl extends _ValidationError {
  const _$ValidationErrorImpl(this.message) : super._();

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.validationError(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ValidationErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ValidationErrorImplCopyWith<_$ValidationErrorImpl> get copyWith =>
      __$$ValidationErrorImplCopyWithImpl<_$ValidationErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) serverError,
    required TResult Function(String message) validationError,
    required TResult Function(String message) unauthorized,
    required TResult Function(String message) notFound,
    required TResult Function(String message) unknown,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() invalidCredentials,
    required TResult Function() weakPassword,
    required TResult Function() networkError,
  }) {
    return validationError(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? serverError,
    TResult? Function(String message)? validationError,
    TResult? Function(String message)? unauthorized,
    TResult? Function(String message)? notFound,
    TResult? Function(String message)? unknown,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? invalidCredentials,
    TResult? Function()? weakPassword,
    TResult? Function()? networkError,
  }) {
    return validationError?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? serverError,
    TResult Function(String message)? validationError,
    TResult Function(String message)? unauthorized,
    TResult Function(String message)? notFound,
    TResult Function(String message)? unknown,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? invalidCredentials,
    TResult Function()? weakPassword,
    TResult Function()? networkError,
    required TResult orElse(),
  }) {
    if (validationError != null) {
      return validationError(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ServerError value) serverError,
    required TResult Function(_ValidationError value) validationError,
    required TResult Function(_Unauthorized value) unauthorized,
    required TResult Function(_NotFound value) notFound,
    required TResult Function(_Unknown value) unknown,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_NetworkError value) networkError,
  }) {
    return validationError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ServerError value)? serverError,
    TResult? Function(_ValidationError value)? validationError,
    TResult? Function(_Unauthorized value)? unauthorized,
    TResult? Function(_NotFound value)? notFound,
    TResult? Function(_Unknown value)? unknown,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_NetworkError value)? networkError,
  }) {
    return validationError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ServerError value)? serverError,
    TResult Function(_ValidationError value)? validationError,
    TResult Function(_Unauthorized value)? unauthorized,
    TResult Function(_NotFound value)? notFound,
    TResult Function(_Unknown value)? unknown,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_NetworkError value)? networkError,
    required TResult orElse(),
  }) {
    if (validationError != null) {
      return validationError(this);
    }
    return orElse();
  }
}

abstract class _ValidationError extends Failure {
  const factory _ValidationError(final String message) = _$ValidationErrorImpl;
  const _ValidationError._() : super._();

  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ValidationErrorImplCopyWith<_$ValidationErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnauthorizedImplCopyWith<$Res> {
  factory _$$UnauthorizedImplCopyWith(
    _$UnauthorizedImpl value,
    $Res Function(_$UnauthorizedImpl) then,
  ) = __$$UnauthorizedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$UnauthorizedImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$UnauthorizedImpl>
    implements _$$UnauthorizedImplCopyWith<$Res> {
  __$$UnauthorizedImplCopyWithImpl(
    _$UnauthorizedImpl _value,
    $Res Function(_$UnauthorizedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$UnauthorizedImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                as String,
      ),
    );
  }
}

/// @nodoc

class _$UnauthorizedImpl extends _Unauthorized {
  const _$UnauthorizedImpl(this.message) : super._();

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.unauthorized(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnauthorizedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnauthorizedImplCopyWith<_$UnauthorizedImpl> get copyWith =>
      __$$UnauthorizedImplCopyWithImpl<_$UnauthorizedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) serverError,
    required TResult Function(String message) validationError,
    required TResult Function(String message) unauthorized,
    required TResult Function(String message) notFound,
    required TResult Function(String message) unknown,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() invalidCredentials,
    required TResult Function() weakPassword,
    required TResult Function() networkError,
  }) {
    return unauthorized(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? serverError,
    TResult? Function(String message)? validationError,
    TResult? Function(String message)? unauthorized,
    TResult? Function(String message)? notFound,
    TResult? Function(String message)? unknown,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? invalidCredentials,
    TResult? Function()? weakPassword,
    TResult? Function()? networkError,
  }) {
    return unauthorized?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? serverError,
    TResult Function(String message)? validationError,
    TResult Function(String message)? unauthorized,
    TResult Function(String message)? notFound,
    TResult Function(String message)? unknown,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? invalidCredentials,
    TResult Function()? weakPassword,
    TResult Function()? networkError,
    required TResult orElse(),
  }) {
    if (unauthorized != null) {
      return unauthorized(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ServerError value) serverError,
    required TResult Function(_ValidationError value) validationError,
    required TResult Function(_Unauthorized value) unauthorized,
    required TResult Function(_NotFound value) notFound,
    required TResult Function(_Unknown value) unknown,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_NetworkError value) networkError,
  }) {
    return unauthorized(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ServerError value)? serverError,
    TResult? Function(_ValidationError value)? validationError,
    TResult? Function(_Unauthorized value)? unauthorized,
    TResult? Function(_NotFound value)? notFound,
    TResult? Function(_Unknown value)? unknown,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_NetworkError value)? networkError,
  }) {
    return unauthorized?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ServerError value)? serverError,
    TResult Function(_ValidationError value)? validationError,
    TResult Function(_Unauthorized value)? unauthorized,
    TResult Function(_NotFound value)? notFound,
    TResult Function(_Unknown value)? unknown,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_NetworkError value)? networkError,
    required TResult orElse(),
  }) {
    if (unauthorized != null) {
      return unauthorized(this);
    }
    return orElse();
  }
}

abstract class _Unauthorized extends Failure {
  const factory _Unauthorized(final String message) = _$UnauthorizedImpl;
  const _Unauthorized._() : super._();

  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnauthorizedImplCopyWith<_$UnauthorizedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NotFoundImplCopyWith<$Res> {
  factory _$$NotFoundImplCopyWith(
    _$NotFoundImpl value,
    $Res Function(_$NotFoundImpl) then,
  ) = __$$NotFoundImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$NotFoundImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$NotFoundImpl>
    implements _$$NotFoundImplCopyWith<$Res> {
  __$$NotFoundImplCopyWithImpl(
    _$NotFoundImpl _value,
    $Res Function(_$NotFoundImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$NotFoundImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                as String,
      ),
    );
  }
}

/// @nodoc

class _$NotFoundImpl extends _NotFound {
  const _$NotFoundImpl(this.message) : super._();

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.notFound(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotFoundImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotFoundImplCopyWith<_$NotFoundImpl> get copyWith =>
      __$$NotFoundImplCopyWithImpl<_$NotFoundImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) serverError,
    required TResult Function(String message) validationError,
    required TResult Function(String message) unauthorized,
    required TResult Function(String message) notFound,
    required TResult Function(String message) unknown,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() invalidCredentials,
    required TResult Function() weakPassword,
    required TResult Function() networkError,
  }) {
    return notFound(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? serverError,
    TResult? Function(String message)? validationError,
    TResult? Function(String message)? unauthorized,
    TResult? Function(String message)? notFound,
    TResult? Function(String message)? unknown,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? invalidCredentials,
    TResult? Function()? weakPassword,
    TResult? Function()? networkError,
  }) {
    return notFound?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? serverError,
    TResult Function(String message)? validationError,
    TResult Function(String message)? unauthorized,
    TResult Function(String message)? notFound,
    TResult Function(String message)? unknown,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? invalidCredentials,
    TResult Function()? weakPassword,
    TResult Function()? networkError,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ServerError value) serverError,
    required TResult Function(_ValidationError value) validationError,
    required TResult Function(_Unauthorized value) unauthorized,
    required TResult Function(_NotFound value) notFound,
    required TResult Function(_Unknown value) unknown,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_NetworkError value) networkError,
  }) {
    return notFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ServerError value)? serverError,
    TResult? Function(_ValidationError value)? validationError,
    TResult? Function(_Unauthorized value)? unauthorized,
    TResult? Function(_NotFound value)? notFound,
    TResult? Function(_Unknown value)? unknown,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_NetworkError value)? networkError,
  }) {
    return notFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ServerError value)? serverError,
    TResult Function(_ValidationError value)? validationError,
    TResult Function(_Unauthorized value)? unauthorized,
    TResult Function(_NotFound value)? notFound,
    TResult Function(_Unknown value)? unknown,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_NetworkError value)? networkError,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(this);
    }
    return orElse();
  }
}

abstract class _NotFound extends Failure {
  const factory _NotFound(final String message) = _$NotFoundImpl;
  const _NotFound._() : super._();

  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotFoundImplCopyWith<_$NotFoundImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnknownImplCopyWith<$Res> {
  factory _$$UnknownImplCopyWith(
    _$UnknownImpl value,
    $Res Function(_$UnknownImpl) then,
  ) = __$$UnknownImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$UnknownImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$UnknownImpl>
    implements _$$UnknownImplCopyWith<$Res> {
  __$$UnknownImplCopyWithImpl(
    _$UnknownImpl _value,
    $Res Function(_$UnknownImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$UnknownImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                as String,
      ),
    );
  }
}

/// @nodoc

class _$UnknownImpl extends _Unknown {
  const _$UnknownImpl(this.message) : super._();

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.unknown(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnknownImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnknownImplCopyWith<_$UnknownImpl> get copyWith =>
      __$$UnknownImplCopyWithImpl<_$UnknownImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) serverError,
    required TResult Function(String message) validationError,
    required TResult Function(String message) unauthorized,
    required TResult Function(String message) notFound,
    required TResult Function(String message) unknown,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() invalidCredentials,
    required TResult Function() weakPassword,
    required TResult Function() networkError,
  }) {
    return unknown(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? serverError,
    TResult? Function(String message)? validationError,
    TResult? Function(String message)? unauthorized,
    TResult? Function(String message)? notFound,
    TResult? Function(String message)? unknown,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? invalidCredentials,
    TResult? Function()? weakPassword,
    TResult? Function()? networkError,
  }) {
    return unknown?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? serverError,
    TResult Function(String message)? validationError,
    TResult Function(String message)? unauthorized,
    TResult Function(String message)? notFound,
    TResult Function(String message)? unknown,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? invalidCredentials,
    TResult Function()? weakPassword,
    TResult Function()? networkError,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ServerError value) serverError,
    required TResult Function(_ValidationError value) validationError,
    required TResult Function(_Unauthorized value) unauthorized,
    required TResult Function(_NotFound value) notFound,
    required TResult Function(_Unknown value) unknown,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_NetworkError value) networkError,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ServerError value)? serverError,
    TResult? Function(_ValidationError value)? validationError,
    TResult? Function(_Unauthorized value)? unauthorized,
    TResult? Function(_NotFound value)? notFound,
    TResult? Function(_Unknown value)? unknown,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_NetworkError value)? networkError,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ServerError value)? serverError,
    TResult Function(_ValidationError value)? validationError,
    TResult Function(_Unauthorized value)? unauthorized,
    TResult Function(_NotFound value)? notFound,
    TResult Function(_Unknown value)? unknown,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_NetworkError value)? networkError,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }
}

abstract class _Unknown extends Failure {
  const factory _Unknown(final String message) = _$UnknownImpl;
  const _Unknown._() : super._();

  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnknownImplCopyWith<_$UnknownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EmailAlreadyInUseImplCopyWith<$Res> {
  factory _$$EmailAlreadyInUseImplCopyWith(
    _$EmailAlreadyInUseImpl value,
    $Res Function(_$EmailAlreadyInUseImpl) then,
  ) = __$$EmailAlreadyInUseImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$EmailAlreadyInUseImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$EmailAlreadyInUseImpl>
    implements _$$EmailAlreadyInUseImplCopyWith<$Res> {
  __$$EmailAlreadyInUseImplCopyWithImpl(
    _$EmailAlreadyInUseImpl _value,
    $Res Function(_$EmailAlreadyInUseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$EmailAlreadyInUseImpl extends _EmailAlreadyInUse {
  const _$EmailAlreadyInUseImpl() : super._();

  @override
  String toString() {
    return 'Failure.emailAlreadyInUse()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$EmailAlreadyInUseImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) serverError,
    required TResult Function(String message) validationError,
    required TResult Function(String message) unauthorized,
    required TResult Function(String message) notFound,
    required TResult Function(String message) unknown,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() invalidCredentials,
    required TResult Function() weakPassword,
    required TResult Function() networkError,
  }) {
    return emailAlreadyInUse();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? serverError,
    TResult? Function(String message)? validationError,
    TResult? Function(String message)? unauthorized,
    TResult? Function(String message)? notFound,
    TResult? Function(String message)? unknown,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? invalidCredentials,
    TResult? Function()? weakPassword,
    TResult? Function()? networkError,
  }) {
    return emailAlreadyInUse?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? serverError,
    TResult Function(String message)? validationError,
    TResult Function(String message)? unauthorized,
    TResult Function(String message)? notFound,
    TResult Function(String message)? unknown,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? invalidCredentials,
    TResult Function()? weakPassword,
    TResult Function()? networkError,
    required TResult orElse(),
  }) {
    if (emailAlreadyInUse != null) {
      return emailAlreadyInUse();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ServerError value) serverError,
    required TResult Function(_ValidationError value) validationError,
    required TResult Function(_Unauthorized value) unauthorized,
    required TResult Function(_NotFound value) notFound,
    required TResult Function(_Unknown value) unknown,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_NetworkError value) networkError,
  }) {
    return emailAlreadyInUse(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ServerError value)? serverError,
    TResult? Function(_ValidationError value)? validationError,
    TResult? Function(_Unauthorized value)? unauthorized,
    TResult? Function(_NotFound value)? notFound,
    TResult? Function(_Unknown value)? unknown,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_NetworkError value)? networkError,
  }) {
    return emailAlreadyInUse?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ServerError value)? serverError,
    TResult Function(_ValidationError value)? validationError,
    TResult Function(_Unauthorized value)? unauthorized,
    TResult Function(_NotFound value)? notFound,
    TResult Function(_Unknown value)? unknown,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_NetworkError value)? networkError,
    required TResult orElse(),
  }) {
    if (emailAlreadyInUse != null) {
      return emailAlreadyInUse(this);
    }
    return orElse();
  }
}

abstract class _EmailAlreadyInUse extends Failure {
  const factory _EmailAlreadyInUse() = _$EmailAlreadyInUseImpl;
  const _EmailAlreadyInUse._() : super._();
}

/// @nodoc
abstract class _$$InvalidCredentialsImplCopyWith<$Res> {
  factory _$$InvalidCredentialsImplCopyWith(
    _$InvalidCredentialsImpl value,
    $Res Function(_$InvalidCredentialsImpl) then,
  ) = __$$InvalidCredentialsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InvalidCredentialsImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$InvalidCredentialsImpl>
    implements _$$InvalidCredentialsImplCopyWith<$Res> {
  __$$InvalidCredentialsImplCopyWithImpl(
    _$InvalidCredentialsImpl _value,
    $Res Function(_$InvalidCredentialsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InvalidCredentialsImpl extends _InvalidCredentials {
  const _$InvalidCredentialsImpl() : super._();

  @override
  String toString() {
    return 'Failure.invalidCredentials()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InvalidCredentialsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) serverError,
    required TResult Function(String message) validationError,
    required TResult Function(String message) unauthorized,
    required TResult Function(String message) notFound,
    required TResult Function(String message) unknown,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() invalidCredentials,
    required TResult Function() weakPassword,
    required TResult Function() networkError,
  }) {
    return invalidCredentials();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? serverError,
    TResult? Function(String message)? validationError,
    TResult? Function(String message)? unauthorized,
    TResult? Function(String message)? notFound,
    TResult? Function(String message)? unknown,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? invalidCredentials,
    TResult? Function()? weakPassword,
    TResult? Function()? networkError,
  }) {
    return invalidCredentials?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? serverError,
    TResult Function(String message)? validationError,
    TResult Function(String message)? unauthorized,
    TResult Function(String message)? notFound,
    TResult Function(String message)? unknown,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? invalidCredentials,
    TResult Function()? weakPassword,
    TResult Function()? networkError,
    required TResult orElse(),
  }) {
    if (invalidCredentials != null) {
      return invalidCredentials();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ServerError value) serverError,
    required TResult Function(_ValidationError value) validationError,
    required TResult Function(_Unauthorized value) unauthorized,
    required TResult Function(_NotFound value) notFound,
    required TResult Function(_Unknown value) unknown,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_NetworkError value) networkError,
  }) {
    return invalidCredentials(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ServerError value)? serverError,
    TResult? Function(_ValidationError value)? validationError,
    TResult? Function(_Unauthorized value)? unauthorized,
    TResult? Function(_NotFound value)? notFound,
    TResult? Function(_Unknown value)? unknown,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_NetworkError value)? networkError,
  }) {
    return invalidCredentials?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ServerError value)? serverError,
    TResult Function(_ValidationError value)? validationError,
    TResult Function(_Unauthorized value)? unauthorized,
    TResult Function(_NotFound value)? notFound,
    TResult Function(_Unknown value)? unknown,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_NetworkError value)? networkError,
    required TResult orElse(),
  }) {
    if (invalidCredentials != null) {
      return invalidCredentials(this);
    }
    return orElse();
  }
}

abstract class _InvalidCredentials extends Failure {
  const factory _InvalidCredentials() = _$InvalidCredentialsImpl;
  const _InvalidCredentials._() : super._();
}

/// @nodoc
abstract class _$$WeakPasswordImplCopyWith<$Res> {
  factory _$$WeakPasswordImplCopyWith(
    _$WeakPasswordImpl value,
    $Res Function(_$WeakPasswordImpl) then,
  ) = __$$WeakPasswordImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$WeakPasswordImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$WeakPasswordImpl>
    implements _$$WeakPasswordImplCopyWith<$Res> {
  __$$WeakPasswordImplCopyWithImpl(
    _$WeakPasswordImpl _value,
    $Res Function(_$WeakPasswordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$WeakPasswordImpl extends _WeakPassword {
  const _$WeakPasswordImpl() : super._();

  @override
  String toString() {
    return 'Failure.weakPassword()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$WeakPasswordImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) serverError,
    required TResult Function(String message) validationError,
    required TResult Function(String message) unauthorized,
    required TResult Function(String message) notFound,
    required TResult Function(String message) unknown,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() invalidCredentials,
    required TResult Function() weakPassword,
    required TResult Function() networkError,
  }) {
    return weakPassword();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? serverError,
    TResult? Function(String message)? validationError,
    TResult? Function(String message)? unauthorized,
    TResult? Function(String message)? notFound,
    TResult? Function(String message)? unknown,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? invalidCredentials,
    TResult? Function()? weakPassword,
    TResult? Function()? networkError,
  }) {
    return weakPassword?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? serverError,
    TResult Function(String message)? validationError,
    TResult Function(String message)? unauthorized,
    TResult Function(String message)? notFound,
    TResult Function(String message)? unknown,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? invalidCredentials,
    TResult Function()? weakPassword,
    TResult Function()? networkError,
    required TResult orElse(),
  }) {
    if (weakPassword != null) {
      return weakPassword();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ServerError value) serverError,
    required TResult Function(_ValidationError value) validationError,
    required TResult Function(_Unauthorized value) unauthorized,
    required TResult Function(_NotFound value) notFound,
    required TResult Function(_Unknown value) unknown,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_NetworkError value) networkError,
  }) {
    return weakPassword(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ServerError value)? serverError,
    TResult? Function(_ValidationError value)? validationError,
    TResult? Function(_Unauthorized value)? unauthorized,
    TResult? Function(_NotFound value)? notFound,
    TResult? Function(_Unknown value)? unknown,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_NetworkError value)? networkError,
  }) {
    return weakPassword?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ServerError value)? serverError,
    TResult Function(_ValidationError value)? validationError,
    TResult Function(_Unauthorized value)? unauthorized,
    TResult Function(_NotFound value)? notFound,
    TResult Function(_Unknown value)? unknown,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_NetworkError value)? networkError,
    required TResult orElse(),
  }) {
    if (weakPassword != null) {
      return weakPassword(this);
    }
    return orElse();
  }
}

abstract class _WeakPassword extends Failure {
  const factory _WeakPassword() = _$WeakPasswordImpl;
  const _WeakPassword._() : super._();
}

/// @nodoc
abstract class _$$NetworkErrorImplCopyWith<$Res> {
  factory _$$NetworkErrorImplCopyWith(
    _$NetworkErrorImpl value,
    $Res Function(_$NetworkErrorImpl) then,
  ) = __$$NetworkErrorImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NetworkErrorImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$NetworkErrorImpl>
    implements _$$NetworkErrorImplCopyWith<$Res> {
  __$$NetworkErrorImplCopyWithImpl(
    _$NetworkErrorImpl _value,
    $Res Function(_$NetworkErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NetworkErrorImpl extends _NetworkError {
  const _$NetworkErrorImpl() : super._();

  @override
  String toString() {
    return 'Failure.networkError()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NetworkErrorImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) serverError,
    required TResult Function(String message) validationError,
    required TResult Function(String message) unauthorized,
    required TResult Function(String message) notFound,
    required TResult Function(String message) unknown,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() invalidCredentials,
    required TResult Function() weakPassword,
    required TResult Function() networkError,
  }) {
    return networkError();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? serverError,
    TResult? Function(String message)? validationError,
    TResult? Function(String message)? unauthorized,
    TResult? Function(String message)? notFound,
    TResult? Function(String message)? unknown,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? invalidCredentials,
    TResult? Function()? weakPassword,
    TResult? Function()? networkError,
  }) {
    return networkError?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? serverError,
    TResult Function(String message)? validationError,
    TResult Function(String message)? unauthorized,
    TResult Function(String message)? notFound,
    TResult Function(String message)? unknown,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? invalidCredentials,
    TResult Function()? weakPassword,
    TResult Function()? networkError,
    required TResult orElse(),
  }) {
    if (networkError != null) {
      return networkError();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ServerError value) serverError,
    required TResult Function(_ValidationError value) validationError,
    required TResult Function(_Unauthorized value) unauthorized,
    required TResult Function(_NotFound value) notFound,
    required TResult Function(_Unknown value) unknown,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_NetworkError value) networkError,
  }) {
    return networkError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ServerError value)? serverError,
    TResult? Function(_ValidationError value)? validationError,
    TResult? Function(_Unauthorized value)? unauthorized,
    TResult? Function(_NotFound value)? notFound,
    TResult? Function(_Unknown value)? unknown,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_NetworkError value)? networkError,
  }) {
    return networkError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ServerError value)? serverError,
    TResult Function(_ValidationError value)? validationError,
    TResult Function(_Unauthorized value)? unauthorized,
    TResult Function(_NotFound value)? notFound,
    TResult Function(_Unknown value)? unknown,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_NetworkError value)? networkError,
    required TResult orElse(),
  }) {
    if (networkError != null) {
      return networkError(this);
    }
    return orElse();
  }
}

abstract class _NetworkError extends Failure {
  const factory _NetworkError() = _$NetworkErrorImpl;
  const _NetworkError._() : super._();
}
