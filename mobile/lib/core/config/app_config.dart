class AppConfig {
  AppConfig._();

  /// Device / launcher display name and primary brand title.
  static const String appName = 'INFINITY';

  /// Company subtitle used on auth, splash, and about surfaces.
  static const String companyName = 'Total-Com Solutions';

  /// Keep in sync with `pubspec.yaml` version name.
  static const String appVersion = '1.0.0';

  /// Keep in sync with `pubspec.yaml` build number (+N).
  static const String buildNumber = '1';

  static const String apiVersion = 'v1';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
