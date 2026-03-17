class MercadoPagoConfig {
  static const String publicKey = String.fromEnvironment(
    'MP_PUBLIC_KEY',
    defaultValue: '',
  );
}
