/// Stable identity for a downloaded release artifact on disk.
class AppUpdateReleaseIdentity {
  const AppUpdateReleaseIdentity({
    required this.version,
    required this.build,
  });

  final String version;
  final int build;

  static final RegExp _fileNamePattern = RegExp(
    r'^infinity-(android|windows)-([0-9A-Za-z._-]+)-b(\d+)\.(apk|exe)$',
  );

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

  /// Parses [fileName] produced by [fileName]. Returns null when unrecognized.
  static AppUpdateReleaseIdentity? tryParseFileName(String fileName) {
    final match = _fileNamePattern.firstMatch(fileName);
    if (match == null) return null;
    final version = match.group(2);
    final build = int.tryParse(match.group(3) ?? '');
    if (version == null || version.isEmpty || build == null) return null;
    return AppUpdateReleaseIdentity(version: version, build: build);
  }
}
