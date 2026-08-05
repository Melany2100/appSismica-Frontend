class DatabaseConfig {
  /// Usa Render por defecto. Para probar el backend local:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-vinculacionsismica.onrender.com',
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
