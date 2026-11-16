import 'package:apni_factory/config/api_config.dart';

class AppAssetImage {
  static const String signUpCurve = "assets/images/Isolation_Mode.png";
  static const String logo = "assets/images/Apni Factory-3.png";
  static const String googleIcon = "assets/images/google.png";
  static const String facebookIcon = "assets/images/Component 12.png";
  static const String homePageCurve = "assets/images/Vector.png";
  static const String gridImage = "assets/images/Isolation_Mode (3).png";
  // Resolves to https://cyan-eagle-893359.hostingersite.com/ in prod
  static String get imageBaseUrl => ApiConfig.webBaseUrl;

  /// Builds a clean, deduplicated storage URL for network images
  static String buildStorageImageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    String clean = raw.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) return clean;
    while (clean.startsWith('/')) {
      clean = clean.substring(1);
    }
    if (clean.startsWith('storage/app/public/')) {
      clean = clean.substring('storage/app/public/'.length);
    } else if (clean.startsWith('storage/')) {
      clean = clean.substring('storage/'.length);
    } else if (clean.startsWith('app/public/')) {
      clean = clean.substring('app/public/'.length);
    }
    String base = imageBaseUrl;
    if (!base.endsWith('/')) base += '/';
    return "${base}storage/app/public/$clean";
  }
}
