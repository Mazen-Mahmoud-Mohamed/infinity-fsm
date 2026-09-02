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
    void Function(int received, int? total)? onProgress,
  });

  Future<void> installDownloadedUpdate({
    required String filePath,
    required String platformKey,
  });

  Future<String?> getDownloadedArtifactPath();

  Future<String?> getDownloadedArtifactVersion();

  String get currentPlatformKey;
}
