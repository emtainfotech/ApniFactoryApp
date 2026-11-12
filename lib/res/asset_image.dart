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
}
