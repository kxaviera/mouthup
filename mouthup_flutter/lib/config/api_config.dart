import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Override: flutter run --dart-define=API_URL=https://api.yourdomain.com/api/v1
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb || kReleaseMode) return 'https://api.ogmario64.fun/api/v1';
    return 'http://localhost:3000/api/v1';
  }

  /// Optional: flutter build apk --dart-define=APP_URL=https://app.yourdomain.com
  static const appUrl = String.fromEnvironment('APP_URL', defaultValue: '');

  static bool get isProduction => !baseUrl.contains('localhost');

  static String get appBaseUrl {
    if (appUrl.isNotEmpty) {
      return appUrl.replaceAll(RegExp(r'/$'), '');
    }
    final apiRoot = baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    if (apiRoot.contains('localhost')) {
      return 'http://localhost:8080';
    }
    final uri = Uri.parse(apiRoot);
    var host = uri.host;
    if (host.startsWith('api.')) {
      host = 'app.${host.substring(4)}';
    }
    return uri.replace(host: host).toString().replaceAll(RegExp(r'/$'), '');
  }

  static String postShareUrl(String postId) => '$appBaseUrl/post/$postId';
}
