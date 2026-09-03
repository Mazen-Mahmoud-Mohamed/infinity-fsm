class AppConfig {
  AppConfig._();

  /// Device / launcher display name and primary brand title.
  static const String appName = 'INFINITY';

  /// Company subtitle used on auth, splash, and about surfaces.
  static const String companyName = 'Total-Com Solutions';

  /// Prefer [AppPackageInfo.load] for installed version/build. These fallbacks
  /// remain only for rare sync contexts where PackageInfo is unavailable.
  static const String appVersionFallback = '0.0.0';
  static const String buildNumberFallback = '0';

  static const String apiVersion = 'v1';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
