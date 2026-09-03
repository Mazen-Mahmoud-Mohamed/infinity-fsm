/// Deterministic client/server-aligned identity for app update notifications.
String appUpdateNotificationDedupeKey({
  required String version,
  required int build,
}) {
  return 'app-update:v$version:$build';
}

bool isSameAppUpdateNotification({
  required String? storedKey,
  required String version,
  required int build,
}) {
  if (storedKey == null || storedKey.isEmpty) return false;
  final expected = appUpdateNotificationDedupeKey(
    version: version,
    build: build,
  );
  // Accept legacy version-only keys written before build was included.
  return storedKey == expected || storedKey == version;
}
