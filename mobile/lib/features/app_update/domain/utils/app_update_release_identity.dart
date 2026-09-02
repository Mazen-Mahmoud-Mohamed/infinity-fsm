/// Stable identity for a downloaded release artifact on disk.
class AppUpdateReleaseIdentity {
  const AppUpdateReleaseIdentity({
    required this.version,
    required this.build,
  });

  final String version;
  final int build;

  String fileName({required String platformKey}) {
    final safeVersion = version.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '_');
    final extension = platformKey == 'android' ? 'apk' : 'exe';
    return 'infinity-$platformKey-$safeVersion-b$build.$extension';
  }

  bool matchesVersionAndBuild({
    required String? storedVersion,
    required int? storedBuild,
  }) {
    return storedVersion == version && storedBuild == build;
  }
}
