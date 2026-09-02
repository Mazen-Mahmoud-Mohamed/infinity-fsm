import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';

abstract class AppUpdateRepository {
  Future<({String version, int build})> getInstalledVersion();

  Future<AppReleaseManifest?> getCachedRelease();

  Future<DateTime?> getLastCheckedAt();

  Future<AppReleaseManifest?> checkForUpdates({
    required String channel,
  });

  Future<String> downloadUpdate({
    required AppReleaseArtifact artifact,
    required String platformKey,
    required String version,
    required int build,
    void Function(int received, int? total)? onProgress,
  });

  Future<void> installDownloadedUpdate({
    required String filePath,
    required String platformKey,
  });

  Future<String?> resolveVerifiedDownloadedPath({
    required AppReleaseManifest manifest,
    required String platformKey,
  });

  Future<void> clearDownloadedArtifact();

  Future<String?> getDownloadedArtifactPath();

  Future<String?> getDownloadedArtifactVersion();

  Future<int?> getDownloadedArtifactBuild();

  Future<String?> getLastNotifiedUpdateVersion();

  Future<void> writeLastNotifiedUpdateVersion(String version);

  Future<String?> getDismissedBannerVersion();

  Future<void> writeDismissedBannerVersion(String version);

  Future<DateTime?> getLastAutoCheckAt();

  Future<void> writeLastAutoCheckAt(DateTime value);

  bool get isDownloadInProgress;

  Future<bool> isAutoUpdateEnabled();

  Future<void> writeAutoUpdateEnabled(bool enabled);

  Future<String?> getAutoUpdateProcessingVersion();

  Future<void> writeAutoUpdateProcessingVersion(String version);

  Future<void> clearAutoUpdateProcessingVersion();

  Future<String?> getAutoUpdateFailedLock();

  Future<void> writeAutoUpdateFailedLock(String lock);

  Future<DateTime?> getAutoUpdateFailedAt();

  Future<void> writeAutoUpdateFailedAt(DateTime value);

  Future<String?> getAutoUpdateInstallAttemptedLock();

  Future<void> writeAutoUpdateInstallAttemptedLock(String lock);

  String get currentPlatformKey;
}
