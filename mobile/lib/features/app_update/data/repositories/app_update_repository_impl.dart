import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutter/foundation.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/features/app_update/data/datasources/app_update_local_datasource.dart';
import 'package:mobile/features/app_update/data/datasources/app_update_remote_datasource.dart';
import 'package:mobile/features/app_update/data/services/app_update_download_coordinator.dart';
import 'package:mobile/features/app_update/data/services/app_update_download_service.dart';
import 'package:mobile/features/app_update/data/services/app_update_install_service.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';
import 'package:mobile/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_artifact_verifier.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_release_identity.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  AppUpdateRepositoryImpl({
    required AppUpdateRemoteDataSource remote,
    required AppUpdateLocalDataSource local,
    required AppUpdateDownloadCoordinator downloadCoordinator,
    required AppUpdateDownloadService downloadService,
    required AppUpdateInstallService installService,
    required ConnectivityService connectivityService,
    AppUpdateArtifactVerifier? artifactVerifier,
  })  : _remote = remote,
        _local = local,
        _downloadCoordinator = downloadCoordinator,
        _downloadService = downloadService,
        _installService = installService,
        _connectivityService = connectivityService,
        _artifactVerifier = artifactVerifier ?? const AppUpdateArtifactVerifier();

  final AppUpdateRemoteDataSource _remote;
  final AppUpdateLocalDataSource _local;
  final AppUpdateDownloadCoordinator _downloadCoordinator;
  final AppUpdateDownloadService _downloadService;
  final AppUpdateInstallService _installService;
  final ConnectivityService _connectivityService;
  final AppUpdateArtifactVerifier _artifactVerifier;

  PackageInfo? _packageInfo;

  @override
  String get currentPlatformKey {
    if (kIsWeb) return 'web';
    if (Platform.isWindows) return 'windows';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }

  @override
  bool get isDownloadInProgress => _downloadCoordinator.isDownloading;

  @override
  Future<({String version, int build})> getInstalledVersion() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    final build = int.tryParse(_packageInfo!.buildNumber) ?? 0;
    return (version: _packageInfo!.version, build: build);
  }

  @override
  Future<AppReleaseManifest?> getCachedRelease() async {
    return _local.readCachedRelease();
  }

  @override
  Future<DateTime?> getLastCheckedAt() async {
    return _local.readLastCheckedAt();
  }

  @override
  Future<DateTime?> getLastAutoCheckAt() async {
    return _local.readLastAutoCheckAt();
  }

  @override
  Future<void> writeLastAutoCheckAt(DateTime value) async {
    await _local.writeLastAutoCheckAt(value);
  }

  @override
  Future<String?> getLastNotifiedUpdateVersion() async {
    return _local.readLastNotifiedUpdateVersion();
  }

  @override
  Future<void> writeLastNotifiedUpdateVersion(String version) async {
    await _local.writeLastNotifiedUpdateVersion(version);
  }

  @override
  Future<String?> getDismissedBannerVersion() async {
    return _local.readDismissedBannerVersion();
  }

  @override
  Future<void> writeDismissedBannerVersion(String version) async {
    await _local.writeDismissedBannerVersion(version);
  }

  @override
  Future<AppReleaseManifest?> checkForUpdates({
    required String channel,
  }) async {
    if (!_connectivityService.currentSnapshot.canSync) {
      throw const AppUpdateCheckException('offline');
    }

    final manifest = await _remote.fetchLatestRelease(channel: channel);
    await _local.writeLastCheckedAt(DateTime.now().toUtc());
    if (manifest != null) {
      await _local.writeCachedRelease(manifest);
    }
    return manifest;
  }

  @override
  Future<String> downloadUpdate({
    required AppReleaseArtifact artifact,
    required String platformKey,
    required String version,
    required int build,
    void Function(int received, int? total)? onProgress,
  }) async {
    if (!_connectivityService.currentSnapshot.canSync) {
      throw const AppUpdateDownloadException('offline');
    }

    final path = await _downloadCoordinator.downloadArtifact(
      artifact: artifact,
      platformKey: platformKey,
      version: version,
      build: build,
      onProgress: onProgress,
    );

    await _local.writeDownloadedArtifact(
      path: path,
      version: version,
      build: build,
    );
    final installed = await getInstalledVersion();
    await _downloadService.cleanupStaleArtifacts(
      installedVersion: installed.version,
      installedBuild: installed.build,
      keepPath: path,
    );
    return path;
  }

  @override
  Future<String?> resolveVerifiedDownloadedPath({
    required AppReleaseManifest manifest,
    required String platformKey,
  }) async {
    final artifact = manifest.artifactForPlatform(platformKey);
    if (!artifact.available) {
      await _local.clearDownloadedArtifact();
      return null;
    }

    final storedPath = _local.readDownloadedPath();
    final storedVersion = _local.readDownloadedVersion();
    final storedBuild = _local.readDownloadedBuild();
    final identity = AppUpdateReleaseIdentity(
      version: manifest.version,
      build: manifest.build,
    );

    if (!identity.matchesVersionAndBuild(
      storedVersion: storedVersion,
      storedBuild: storedBuild,
    )) {
      await _local.clearDownloadedArtifact();
      return null;
    }

    final expectedFileName = identity.fileName(platformKey: platformKey);
    if (storedPath == null || p.basename(storedPath) != expectedFileName) {
      await _local.clearDownloadedArtifact();
      return null;
    }

    final file = File(storedPath);
    if (!await file.exists()) {
      await _local.clearDownloadedArtifact();
      return null;
    }

    final valid = await _artifactVerifier.verify(file: file, artifact: artifact);
    if (!valid) {
      await _local.clearDownloadedArtifact();
      if (await file.exists()) {
        await file.delete();
      }
      return null;
    }

    return storedPath;
  }

  @override
  Future<void> clearDownloadedArtifact() async {
    final path = _local.readDownloadedPath();
    await _local.clearDownloadedArtifact();
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } on Object {
      // Best-effort; package installer may still hold the file briefly.
    }
  }

  @override
  Future<int> cleanupStaleUpdateArtifacts({
    required String installedVersion,
    required int installedBuild,
    String? keepPath,
  }) {
    return _downloadService.cleanupStaleArtifacts(
      installedVersion: installedVersion,
      installedBuild: installedBuild,
      keepPath: keepPath,
    );
  }

  @override
  Future<void> installDownloadedUpdate({
    required String filePath,
    required String platformKey,
  }) {
    return _installService.install(
      filePath: filePath,
      platformKey: platformKey,
    );
  }

  @override
  Future<String?> getDownloadedArtifactPath() async {
    return _local.readDownloadedPath();
  }

  @override
  Future<String?> getDownloadedArtifactVersion() async {
    return _local.readDownloadedVersion();
  }

  @override
  Future<int?> getDownloadedArtifactBuild() async {
    return _local.readDownloadedBuild();
  }

  @override
  Future<bool> isAutoUpdateEnabled() async => _local.readAutoUpdateEnabled();

  @override
  Future<void> writeAutoUpdateEnabled(bool enabled) async {
    await _local.writeAutoUpdateEnabled(enabled);
  }

  @override
  Future<String?> getAutoUpdateProcessingVersion() async {
    return _local.readAutoUpdateProcessingVersion();
  }

  @override
  Future<void> writeAutoUpdateProcessingVersion(String version) async {
    await _local.writeAutoUpdateProcessingVersion(version);
  }

  @override
  Future<void> clearAutoUpdateProcessingVersion() async {
    await _local.clearAutoUpdateProcessingVersion();
  }

  @override
  Future<String?> getAutoUpdateFailedLock() async {
    return _local.readAutoUpdateFailedLock();
  }

  @override
  Future<void> writeAutoUpdateFailedLock(String lock) async {
    await _local.writeAutoUpdateFailedLock(lock);
  }

  @override
  Future<DateTime?> getAutoUpdateFailedAt() async {
    return _local.readAutoUpdateFailedAt();
  }

  @override
  Future<void> writeAutoUpdateFailedAt(DateTime value) async {
    await _local.writeAutoUpdateFailedAt(value);
  }

  @override
  Future<String?> getAutoUpdateInstallAttemptedLock() async {
    return _local.readAutoUpdateInstallAttemptedLock();
  }

  @override
  Future<void> writeAutoUpdateInstallAttemptedLock(String lock) async {
    await _local.writeAutoUpdateInstallAttemptedLock(lock);
  }

  @override
  Future<void> clearAutoUpdateInstallAttemptedLock() async {
    await _local.clearAutoUpdateInstallAttemptedLock();
  }
}

class AppUpdateCheckException implements Exception {
  const AppUpdateCheckException(this.code);

  final String code;

  @override
  String toString() => 'AppUpdateCheckException($code)';
}
