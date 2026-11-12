class ApiConfig {
  static const String environment =
      String.fromEnvironment('APNI_ENV', defaultValue: 'prod');

  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Resolved API base URL preserving trailing slash.
  static String get baseUrl {
    if (_overrideBaseUrl.trim().isNotEmpty) {
      final cleaned = _overrideBaseUrl.trim();
      return cleaned.endsWith('/') ? cleaned : '$cleaned/';
    }
    switch (environment) {
      case 'local':
        return 'http://127.0.0.1:8000/api/';
      case 'staging':
        return 'https://panel.apnifactory.co.in/api/';
      case 'prod':
      default:
        return 'https://cyan-eagle-893359.hostingersite.com/api/';
    }
  }

  /// Resolved web/asset root URL matching [baseUrl] (with trailing slash).
  static String get webBaseUrl {
    final apiUrl = baseUrl;
    if (apiUrl.endsWith('/api/')) {
      return apiUrl.substring(0, apiUrl.length - 4);
    }
    return apiUrl.endsWith('/') ? apiUrl : '$apiUrl/';
  }

  static const String _overridePayuEnv =
      String.fromEnvironment('PAYU_ENV', defaultValue: '');

  /// Fallback PayU environment flag ('1' UAT/test, '0' production).
  /// Live CheckOutScreen prefers `orderModel.payuEnvironment` returned by Backend,
  /// so Backend credentials auto-switch UAT -> Production without rebuilding the APK.
  static String get payuEnvironment {
    if (_overridePayuEnv.isNotEmpty) {
      return (_overridePayuEnv == '0' || _overridePayuEnv.toLowerCase() == 'production')
          ? '0'
          : '1';
    }
    return '1';
  }
}

