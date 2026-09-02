import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/features/app_update/data/repositories/app_update_repository_impl.dart';
import 'package:mobile/features/app_update/data/services/app_update_download_service.dart';
import 'package:mobile/features/app_update/data/services/app_update_install_service.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';
import 'package:mobile/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_state.dart';

/// Application-level auto-update orchestration independent from Update Center UI.
class AppAutoUpdateManager {
  AppAutoUpdateManager(this._repository);

  static const _failureBackoff = Duration(hours: 1);

  final AppUpdateRepository _repository;

  String? _inFlightVersion;
  Future<void>? _inFlightOperation;

  static String lockKey({
    required String version,
    required String platformKey,
  }) {
    return 'auto-update:v$version:$platformKey';
  }

  Future<bool> isEnabled() => _repository.isAutoUpdateEnabled();

  Future<void> setEnabled(bool enabled) =>
      _repository.writeAutoUpdateEnabled(enabled);

  /// Returns `true` when auto-update owns the update (suppress manual prompts).
  Future<bool> tryHandleUpdateAvailable({
    required AppReleaseManifest manifest,
    required UpdateAvailability availability,
    required String platformKey,
    required AutoUpdateOrchestrationCallbacks callbacks,
  }) async {
    if (kIsWeb || !await isEnabled()) return false;
    if (availability != UpdateAvailability.updateAvailable) return false;

    final artifact = manifest.artifactForPlatform(platformKey);
    if (!artifact.available || artifact.downloadUrl == null) return false;

    if (_inFlightOperation != null || _inFlightVersion == manifest.version) {
      callbacks.onOwned(true);
      _attachExistingProgress(callbacks);
      return true;
    }

    if (await _isInFailureBackoff(manifest.version, platformKey)) {
      return true;
    }

    final installLock = lockKey(version: manifest.version, platformKey: platformKey);
    if (await _repository.getAutoUpdateInstallAttemptedLock() == installLock) {
      callbacks.onOwned(true);
      return true;
    }

    if (_repository.isDownloadInProgress) {
      callbacks.onOwned(true);
      _attachExistingProgress(callbacks);
      return true;
    }

    final downloadedPath = await _repository.resolveVerifiedDownloadedPath(
      manifest: manifest,
      platformKey: platformKey,
    );
    if (downloadedPath != null) {
      callbacks.onState(
        UpdateCenterStatus.downloadReady,
        downloadedPath: downloadedPath,
        autoUpdateOwned: true,
      );
      if (await _shouldAutoInstall(manifest.version, platformKey)) {
        unawaited(_installArtifact(
          path: downloadedPath,
          platformKey: platformKey,
          version: manifest.version,
          callbacks: callbacks,
        ));
      }
      return true;
    }

    final processingVersion = await _repository.getAutoUpdateProcessingVersion();
    if (processingVersion == manifest.version) {
      callbacks.onOwned(true);
      return true;
    }

    _inFlightVersion = manifest.version;
    await _repository.writeAutoUpdateProcessingVersion(manifest.version);

    callbacks.onOwned(true);
    callbacks.onState(
      UpdateCenterStatus.downloading,
      downloadProgress: 0,
      downloadReceivedBytes: 0,
      downloadTotalBytes: artifact.size,
      autoUpdateOwned: true,
      clearErrorCode: true,
    );

    _inFlightOperation = _downloadAndMaybeInstall(
      manifest: manifest,
      artifact: artifact,
      platformKey: platformKey,
      callbacks: callbacks,
    ).whenComplete(() {
      _inFlightOperation = null;
      _inFlightVersion = null;
    });

    unawaited(_inFlightOperation);
    return true;
  }

  Future<void> continueAfterManualDownload({
    required String version,
    required String path,
    required String platformKey,
    required AutoUpdateOrchestrationCallbacks callbacks,
  }) async {
    if (!await isEnabled()) return;
    callbacks.onState(
      UpdateCenterStatus.downloadReady,
      downloadedPath: path,
      autoUpdateOwned: true,
    );
    if (await _shouldAutoInstall(version, platformKey)) {
      await _installArtifact(
        path: path,
        platformKey: platformKey,
        version: version,
        callbacks: callbacks,
      );
    }
  }

  Future<void> _downloadAndMaybeInstall({
    required AppReleaseManifest manifest,
    required AppReleaseArtifact artifact,
    required String platformKey,
    required AutoUpdateOrchestrationCallbacks callbacks,
  }) async {
    try {
      final path = await _repository.downloadUpdate(
        artifact: artifact,
        platformKey: platformKey,
        version: manifest.version,
        build: manifest.build,
        onProgress: callbacks.onProgress,
      );

      callbacks.onState(
        UpdateCenterStatus.verifying,
        downloadedPath: path,
        autoUpdateOwned: true,
      );

      if (!await isEnabled()) {
        callbacks.onState(
          UpdateCenterStatus.downloadReady,
          downloadedPath: path,
          autoUpdateOwned: false,
        );
        await _repository.clearAutoUpdateProcessingVersion();
        return;
      }

      if (await _shouldAutoInstall(manifest.version, platformKey)) {
        await _installArtifact(
          path: path,
          platformKey: platformKey,
          version: manifest.version,
          callbacks: callbacks,
        );
      } else {
        callbacks.onState(
          UpdateCenterStatus.downloadReady,
          downloadedPath: path,
          autoUpdateOwned: true,
        );
      }
      await _repository.clearAutoUpdateProcessingVersion();
    } on AppUpdateDownloadException catch (error) {
      await _recordFailure(manifest.version, platformKey);
      callbacks.onState(
        UpdateCenterStatus.downloadFailed,
        errorCode: error.code,
        autoUpdateOwned: true,
        clearDownloadProgress: true,
        clearDownloadReceivedBytes: true,
        clearDownloadTotalBytes: true,
      );
      await _repository.clearAutoUpdateProcessingVersion();
    } on DioException {
      await _recordFailure(manifest.version, platformKey);
      callbacks.onState(
        UpdateCenterStatus.downloadFailed,
        errorCode: 'network',
        autoUpdateOwned: true,
        clearDownloadProgress: true,
        clearDownloadReceivedBytes: true,
        clearDownloadTotalBytes: true,
      );
      await _repository.clearAutoUpdateProcessingVersion();
    } on Object {
      await _recordFailure(manifest.version, platformKey);
      callbacks.onState(
        UpdateCenterStatus.downloadFailed,
        errorCode: 'unknown',
        autoUpdateOwned: true,
        clearDownloadProgress: true,
        clearDownloadReceivedBytes: true,
        clearDownloadTotalBytes: true,
      );
      await _repository.clearAutoUpdateProcessingVersion();
    }
  }

  Future<void> _installArtifact({
    required String path,
    required String platformKey,
    required String version,
    required AutoUpdateOrchestrationCallbacks callbacks,
  }) async {
    if (!await isEnabled()) {
      callbacks.onState(
        UpdateCenterStatus.downloadReady,
        downloadedPath: path,
        autoUpdateOwned: false,
      );
      return;
    }

    final installLock = AppAutoUpdateManager.lockKey(
      version: version,
      platformKey: platformKey,
    );
    final attempted = await _repository.getAutoUpdateInstallAttemptedLock();
    if (attempted == installLock) {
      callbacks.onState(
        UpdateCenterStatus.downloadReady,
        downloadedPath: path,
        autoUpdateOwned: true,
      );
      return;
    }

    await _repository.writeAutoUpdateInstallAttemptedLock(installLock);
    callbacks.onState(
      UpdateCenterStatus.installing,
      downloadedPath: path,
      autoUpdateOwned: true,
      clearErrorCode: true,
    );

    try {
      await _repository.installDownloadedUpdate(
        filePath: path,
        platformKey: platformKey,
      );
      callbacks.onState(
        UpdateCenterStatus.downloadReady,
        downloadedPath: path,
        autoUpdateOwned: true,
      );
    } on AppUpdateInstallException catch (error) {
      await _recordFailure(version, platformKey);
      callbacks.onState(
        UpdateCenterStatus.downloadReady,
        downloadedPath: path,
        errorCode: error.code,
        autoUpdateOwned: true,
      );
    } on Object {
      await _recordFailure(version, platformKey);
      callbacks.onState(
        UpdateCenterStatus.downloadReady,
        downloadedPath: path,
        errorCode: 'install_failed',
        autoUpdateOwned: true,
      );
    }
  }

  Future<bool> _shouldAutoInstall(String version, String platformKey) async {
    if (!await isEnabled()) return false;
    final lockKey = AppAutoUpdateManager.lockKey(
      version: version,
      platformKey: platformKey,
    );
    final attempted = await _repository.getAutoUpdateInstallAttemptedLock();
    return attempted != lockKey;
  }

  Future<bool> _isInFailureBackoff(String version, String platformKey) async {
    final failedLock = await _repository.getAutoUpdateFailedLock();
    final failedAt = await _repository.getAutoUpdateFailedAt();
    if (failedLock == null || failedAt == null) return false;
    if (failedLock != lockKey(version: version, platformKey: platformKey)) {
      return false;
    }
    return DateTime.now().toUtc().difference(failedAt) < _failureBackoff;
  }

  Future<void> _recordFailure(String version, String platformKey) async {
    await _repository.writeAutoUpdateFailedLock(
      lockKey(version: version, platformKey: platformKey),
    );
    await _repository.writeAutoUpdateFailedAt(DateTime.now().toUtc());
  }

  void _attachExistingProgress(AutoUpdateOrchestrationCallbacks callbacks) {
    // Progress is forwarded by UpdateCenterCubit via coordinator listener.
    callbacks.onState(
      UpdateCenterStatus.downloading,
      autoUpdateOwned: true,
    );
  }
}

class AutoUpdateOrchestrationCallbacks {
  const AutoUpdateOrchestrationCallbacks({
    required this.onState,
    required this.onProgress,
    required this.onOwned,
  });

  final void Function(
    UpdateCenterStatus status, {
    String? downloadedPath,
    bool clearDownloadedPath,
    double? downloadProgress,
    bool clearDownloadProgress,
    int? downloadReceivedBytes,
    bool clearDownloadReceivedBytes,
    int? downloadTotalBytes,
    bool clearDownloadTotalBytes,
    String? errorCode,
    bool clearErrorCode,
    bool? autoUpdateOwned,
  }) onState;

  final void Function(int received, int? total) onProgress;
  final void Function(bool owned) onOwned;
}
