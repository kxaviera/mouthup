class ApiConfig {
  /// Production: flutter build web --dart-define=API_URL=https://api.yourdomain.com/api/v1
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  static bool get isProduction => !baseUrl.contains('localhost');
}
