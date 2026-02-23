import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
abstract class Failure with _$Failure {
  const Failure._(); // Required for custom getters
  String get message => map(
    serverError: (f) => f.message,
    validationError: (f) => f.message,
    unauthorized: (f) => f.message,
    notFound: (f) => f.message,
    unknown: (f) => f.message,
    emailAlreadyInUse: (_) => 'Email ya registrado',
    invalidCredentials: (_) => 'Credenciales inválidas',
    weakPassword: (_) => 'Contraseña insegura',
    networkError: (_) => 'Error de red',
  );

  // General
  const factory Failure.serverError(String message) = _ServerError;
  const factory Failure.validationError(String message) = _ValidationError;
  const factory Failure.unauthorized(String message) = _Unauthorized;
  const factory Failure.notFound(String message) = _NotFound;
  const factory Failure.unknown(String message) = _Unknown;

  // Auth-specific
  const factory Failure.emailAlreadyInUse() = _EmailAlreadyInUse;
  const factory Failure.invalidCredentials() = _InvalidCredentials;
  const factory Failure.weakPassword() = _WeakPassword;
  const factory Failure.networkError() = _NetworkError;
}
