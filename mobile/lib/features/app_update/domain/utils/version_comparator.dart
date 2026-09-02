/// Semantic version + build comparison for Update Center.
enum VersionComparison {
  equal,
  updateAvailable,
  currentIsNewer,
}

VersionComparison compareAppVersions({
  required String currentVersion,
  required int currentBuild,
  required String latestVersion,
  required int latestBuild,
}) {
  final versionCmp = _compareSemver(currentVersion, latestVersion);
  if (versionCmp < 0) {
    return VersionComparison.updateAvailable;
  }
  if (versionCmp > 0) {
    return VersionComparison.currentIsNewer;
  }
  if (latestBuild > currentBuild) {
    return VersionComparison.updateAvailable;
  }
  if (latestBuild < currentBuild) {
    return VersionComparison.currentIsNewer;
  }
  return VersionComparison.equal;
}

int _compareSemver(String left, String right) {
  final leftParts = _parseSemver(left);
  final rightParts = _parseSemver(right);

  for (var i = 0; i < 3; i++) {
    if (leftParts[i] < rightParts[i]) return -1;
    if (leftParts[i] > rightParts[i]) return 1;
  }
  return 0;
}

List<int> _parseSemver(String raw) {
  final cleaned = raw.trim().split('+').first.split('-').first;
  final parts = cleaned.split('.');
  final values = <int>[];
  for (var i = 0; i < 3; i++) {
    if (i >= parts.length) {
      values.add(0);
      continue;
    }
    final parsed = int.tryParse(parts[i].replaceAll(RegExp(r'[^0-9]'), ''));
    values.add(parsed ?? 0);
  }
  return values;
}
