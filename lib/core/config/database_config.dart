class DatabaseConfig {
  /// Backend local accesible desde teléfono físico en la misma red Wi-Fi.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.18.19:3000',
  );

  /// Render Free puede tardar más de 50 segundos en despertar. El valor
  /// predeterminado de producción sigue siendo 30 segundos.
  static const int connectionTimeout = int.fromEnvironment(
    'API_TIMEOUT_MS',
    defaultValue: 30000,
  );
  static const int receiveTimeout = connectionTimeout;

  static String getServerUrl() {
    return baseUrl;
  }
}
