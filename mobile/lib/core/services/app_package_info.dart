import 'package:package_info_plus/package_info_plus.dart';

/// Cached installed app version/build from the platform package metadata.
///
/// Prefer this over hardcoded [AppConfig] version constants so Settings and
/// diagnostics always match the installed release (e.g. 1.0.4+5).
class AppPackageInfo {
  AppPackageInfo._();

  static PackageInfo? _cached;

  static Future<PackageInfo> load() async {
    final existing = _cached;
    if (existing != null) return existing;
    final info = await PackageInfo.fromPlatform();
    _cached = info;
    return info;
  }

  /// Test/reset helper — do not use in production UI.
  static void debugResetCache() {
    _cached = null;
  }
}
