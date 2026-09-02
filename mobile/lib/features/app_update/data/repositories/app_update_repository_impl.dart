import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/features/app_update/data/datasources/app_update_local_datasource.dart';
import 'package:mobile/features/app_update/data/datasources/app_update_remote_datasource.dart';
import 'package:mobile/features/app_update/data/services/app_update_download_service.dart';
import 'package:mobile/features/app_update/data/services/app_update_install_service.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';
import 'package:mobile/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  AppUpdateRepositoryImpl({
    required AppUpdateRemoteDataSource remote,
    required AppUpdateLocalDataSource local,
    required AppUpdateDownloadService downloadService,
    required AppUpdateInstallService installService,
    required ConnectivityService connectivityService,
  })  : _remote = remote,
        _local = local,
        _downloadService = downloadService,
        _installService = installService,
        _connectivityService = connectivityService;

  final AppUpdateRemoteDataSource _remote;
  final AppUpdateLocalDataSource _local;
  final AppUpdateDownloadService _downloadService;
  final AppUpdateInstallService _installService;
  final ConnectivityService _connectivityService;

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
    void Function(int received, int? total)? onProgress,
  }) async {
    if (!_connectivityService.currentSnapshot.canSync) {
      throw const AppUpdateDownloadException('offline');
    }

    final file = await _downloadService.downloadArtifact(
      artifact: artifact,
      platformKey: platformKey,
      version: version,
      onProgress: onProgress,
    );

    await _local.writeDownloadedArtifact(
      path: file.path,
      version: version,
    );
    return file.path;
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
}

class AppUpdateCheckException implements Exception {
  const AppUpdateCheckException(this.code);

  final String code;

  @override
  String toString() => 'AppUpdateCheckException($code)';
}
