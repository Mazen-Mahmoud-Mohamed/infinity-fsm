import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/app_update/data/repositories/app_update_repository_impl.dart';
import 'package:mobile/features/app_update/data/services/app_auto_update_manager.dart';
import 'package:mobile/features/app_update/data/services/app_update_download_coordinator.dart';
import 'package:mobile/features/app_update/data/services/app_update_download_service.dart';
import 'package:mobile/features/app_update/data/services/app_update_install_service.dart';
import 'package:mobile/features/app_update/data/services/app_update_notification_service.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';
import 'package:mobile/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_localization.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_notification_identity.dart';
import 'package:mobile/features/app_update/domain/utils/version_comparator.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_state.dart';

enum AppUpdateAutoCheckReason {
  startup,
  authenticated,
  resumed,
  connectivityRestored,
}

class UpdateCenterCubit extends Cubit<UpdateCenterState> {
  UpdateCenterCubit({
    required AppUpdateRepository repository,
    required AppUpdateDownloadCoordinator downloadCoordinator,
    required AppUpdateNotificationService notificationService,
    required AppAutoUpdateManager autoUpdateManager,
    required String releaseChannel,
    required String Function() localeCodeProvider,
  })  : _repository = repository,
        _downloadCoordinator = downloadCoordinator,
        _notificationService = notificationService,
        _autoUpdateManager = autoUpdateManager,
        _releaseChannel = releaseChannel,
        _localeCodeProvider = localeCodeProvider,
        super(const UpdateCenterState());

  static const _autoCheckInterval = Duration(hours: 4);

  final AppUpdateRepository _repository;
  final AppUpdateDownloadCoordinator _downloadCoordinator;
  final AppUpdateNotificationService _notificationService;
  final AppAutoUpdateManager _autoUpdateManager;
  final String Function() _localeCodeProvider;

  String _releaseChannel;
  bool _sessionAutoCheckAttempted = false;
  bool _initialized = false;

  String get releaseChannel => _releaseChannel;

  void bindReleaseChannel(String channel) {
    if (channel.isEmpty || channel == _releaseChannel) return;
    _releaseChannel = channel;
  }

  Future<void> initialize() async {
    final installed = await _repository.getInstalledVersion();
    final cached = await _repository.getCachedRelease();
    final lastChecked = await _repository.getLastCheckedAt();
    final platformKey = _repository.currentPlatformKey;
    final dismissedBanner = await _repository.getDismissedBannerVersion();
    final autoUpdateEnabled = await _repository.isAutoUpdateEnabled();

    final availability = cached == null
        ? UpdateAvailability.unknown
        : _resolveAvailability(
            installedVersion: installed.version,
            installedBuild: installed.build,
            manifest: cached,
            platformKey: platformKey,
          );

    final downloadedPath = cached == null
        ? null
        : await _repository.resolveVerifiedDownloadedPath(
            manifest: cached,
            platformKey: platformKey,
          );

    UpdateCenterStatus status = _statusForAvailability(availability);
    String? restoredDownloadPath;
    var autoUpdateOwned = false;

    if (!kIsWeb &&
        availability == UpdateAvailability.updateAvailable &&
        downloadedPath != null) {
      status = UpdateCenterStatus.downloadReady;
      restoredDownloadPath = downloadedPath;
    }

    if (_repository.isDownloadInProgress) {
      status = UpdateCenterStatus.downloading;
      autoUpdateOwned = autoUpdateEnabled;
      _attachDownloadProgressListener();
    }

    emit(
      state.copyWith(
        installedVersion: installed.version,
        installedBuild: installed.build,
        platformKey: platformKey,
        latestRelease: cached,
        lastCheckedAt: lastChecked,
        availability: availability,
        status: status,
        downloadedPath: restoredDownloadPath,
        autoUpdateEnabled: autoUpdateEnabled,
        autoUpdateOwned: autoUpdateOwned,
        showUpdateBanner: _shouldShowBanner(
          availability: availability,
          version: cached?.version,
          dismissedVersion: dismissedBanner,
          autoUpdateEnabled: autoUpdateEnabled,
          autoUpdateOwned: autoUpdateOwned,
        ),
        downloadReceivedBytes: _repository.isDownloadInProgress
            ? _downloadCoordinator.lastReceivedBytes
            : null,
        downloadTotalBytes: _repository.isDownloadInProgress
            ? _downloadCoordinator.lastTotalBytes
            : null,
        downloadProgress: _repository.isDownloadInProgress &&
                _downloadCoordinator.lastTotalBytes != null &&
                _downloadCoordinator.lastTotalBytes! > 0
            ? _downloadCoordinator.lastReceivedBytes /
                _downloadCoordinator.lastTotalBytes!
            : null,
      ),
    );

    _initialized = true;

    if (autoUpdateEnabled &&
        availability == UpdateAvailability.updateAvailable &&
        cached != null &&
        !_sessionAutoCheckAttempted) {
      unawaited(_tryAutoUpdate(cached, availability));
    }
  }

  Future<void> setAutoUpdateEnabled(bool enabled) async {
    await _autoUpdateManager.setEnabled(enabled);
    emit(state.copyWith(autoUpdateEnabled: enabled));

    if (enabled) {
      if (state.availability == UpdateAvailability.updateAvailable &&
          state.latestRelease != null) {
        unawaited(
          _tryAutoUpdate(state.latestRelease!, state.availability),
        );
      } else {
        unawaited(
          maybeAutoCheck(reason: AppUpdateAutoCheckReason.authenticated),
        );
      }
    }
  }

  Future<void> onAppReady({required bool isAuthenticated}) async {
    if (!_initialized) {
      await initialize();
    }
    if (isAuthenticated) {
      unawaited(
        maybeAutoCheck(reason: AppUpdateAutoCheckReason.authenticated),
      );
    }
  }

  Future<void> maybeAutoCheck({
    required AppUpdateAutoCheckReason reason,
  }) async {
    if (isClosed || kIsWeb) return;
    if (!await _shouldRunAutoCheck(reason)) return;

    _sessionAutoCheckAttempted = true;
    await _repository.writeLastAutoCheckAt(DateTime.now().toUtc());

    try {
      final manifest = await _repository.checkForUpdates(
        channel: _releaseChannel,
      );
      if (manifest == null) return;

      final availability = _resolveAvailability(
        installedVersion: state.installedVersion,
        installedBuild: state.installedBuild,
        manifest: manifest,
        platformKey: state.platformKey,
      );

      await _applyManifestResult(
        manifest: manifest,
        availability: availability,
        notifyIfAvailable: true,
      );
    } on AppUpdateCheckException {
      // Offline or expected failures — silent for automatic checks.
    } on DioException {
      // Network errors must not block or spam the user.
    } on Object {
      // Swallow unexpected auto-check failures.
    }
  }

  Future<void> checkForUpdates() async {
    if (state.isBusy && state.status != UpdateCenterStatus.downloadFailed) {
      return;
    }

    emit(
      state.copyWith(
        status: UpdateCenterStatus.checking,
        clearErrorCode: true,
        clearDownloadProgress: state.status != UpdateCenterStatus.downloading,
      ),
    );

    try {
      final manifest = await _repository.checkForUpdates(
        channel: _releaseChannel,
      );
      final lastChecked = await _repository.getLastCheckedAt();

      if (manifest == null) {
        emit(
          state.copyWith(
            status: UpdateCenterStatus.checkFailed,
            errorCode: 'invalid_response',
            lastCheckedAt: lastChecked,
          ),
        );
        return;
      }

      final availability = _resolveAvailability(
        installedVersion: state.installedVersion,
        installedBuild: state.installedBuild,
        manifest: manifest,
        platformKey: state.platformKey,
      );

      await _applyManifestResult(
        manifest: manifest,
        availability: availability,
        notifyIfAvailable: false,
        lastCheckedAt: lastChecked,
        showCheckingComplete: true,
      );
    } on AppUpdateCheckException catch (error) {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.checkFailed,
          errorCode: error.code,
        ),
      );
    } on DioException {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.checkFailed,
          errorCode: 'network',
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.checkFailed,
          errorCode: 'unknown',
        ),
      );
    }
  }

  Future<void> downloadUpdate() async {
    final manifest = state.latestRelease;
    final artifact = state.platformArtifact;
    if (manifest == null ||
        artifact == null ||
        !artifact.available ||
        state.availability != UpdateAvailability.updateAvailable) {
      return;
    }

    if (state.status == UpdateCenterStatus.downloading ||
        state.status == UpdateCenterStatus.installing ||
        state.status == UpdateCenterStatus.verifying) {
      return;
    }

    emit(
      state.copyWith(
        status: UpdateCenterStatus.downloading,
        downloadProgress: 0,
        downloadReceivedBytes: 0,
        downloadTotalBytes: artifact.size,
        clearErrorCode: true,
      ),
    );

    _attachDownloadProgressListener();

    try {
      final path = await _repository.downloadUpdate(
        artifact: artifact,
        platformKey: state.platformKey,
        version: manifest.version,
        build: manifest.build,
        onProgress: _emitDownloadProgress,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadReady,
          downloadedPath: path,
          downloadProgress: 1,
          downloadReceivedBytes: artifact.size,
          downloadTotalBytes: artifact.size,
        ),
      );

      if (state.autoUpdateEnabled) {
        await _autoUpdateManager.continueAfterManualDownload(
          version: manifest.version,
          path: path,
          platformKey: state.platformKey,
          callbacks: _autoUpdateCallbacks(),
        );
      }
    } on AppUpdateDownloadException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadFailed,
          errorCode: error.code,
          clearDownloadProgress: true,
          clearDownloadReceivedBytes: true,
          clearDownloadTotalBytes: true,
        ),
      );
    } on DioException {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadFailed,
          errorCode: 'network',
          clearDownloadProgress: true,
          clearDownloadReceivedBytes: true,
          clearDownloadTotalBytes: true,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadFailed,
          errorCode: 'unknown',
          clearDownloadProgress: true,
          clearDownloadReceivedBytes: true,
          clearDownloadTotalBytes: true,
        ),
      );
    } finally {
      if (!_shouldKeepProgressListener()) {
        _downloadCoordinator.attachProgressListener(null);
      }
    }
  }

  Future<void> installDownloadedUpdate() async {
    final path = state.downloadedPath;
    if (path == null || path.isEmpty) return;
    if (state.isBusy) return;

    emit(
      state.copyWith(
        status: UpdateCenterStatus.installing,
        clearErrorCode: true,
      ),
    );

    try {
      await _repository.installDownloadedUpdate(
        filePath: path,
        platformKey: state.platformKey,
      );
    } on AppUpdateInstallException catch (error) {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadReady,
          errorCode: error.code,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: UpdateCenterStatus.downloadReady,
          errorCode: 'install_failed',
        ),
      );
    }
  }

  Future<void> dismissUpdateBanner() async {
    final version = state.latestRelease?.version;
    if (version == null || version.isEmpty) return;
    await _repository.writeDismissedBannerVersion(version);
    emit(state.copyWith(showUpdateBanner: false));
  }

  String? get releaseNotes {
    final notes = state.latestRelease?.releaseNotes?.trim();
    if (notes == null || notes.isEmpty) return null;
    return notes;
  }

  Future<bool> _shouldRunAutoCheck(AppUpdateAutoCheckReason reason) async {
    // Connectivity restoration must always reconcile the latest release so
    // offline users are not stuck waiting for the 4h throttle.
    if (reason == AppUpdateAutoCheckReason.connectivityRestored) {
      return true;
    }
    if (reason == AppUpdateAutoCheckReason.authenticated &&
        !_sessionAutoCheckAttempted) {
      return true;
    }
    if (reason == AppUpdateAutoCheckReason.startup &&
        !_sessionAutoCheckAttempted) {
      return true;
    }

    final lastAuto = await _repository.getLastAutoCheckAt();
    if (lastAuto == null) return true;
    return DateTime.now().toUtc().difference(lastAuto) >= _autoCheckInterval;
  }

  Future<void> _applyManifestResult({
    required AppReleaseManifest manifest,
    required UpdateAvailability availability,
    required bool notifyIfAvailable,
    DateTime? lastCheckedAt,
    bool showCheckingComplete = false,
  }) async {
    final dismissedBanner = await _repository.getDismissedBannerVersion();
    final autoUpdateEnabled = state.autoUpdateEnabled;

    UpdateCenterStatus nextStatus = _repository.isDownloadInProgress
        ? UpdateCenterStatus.downloading
        : _statusForAvailability(availability);

    String? restoredDownloadPath;
    var autoUpdateOwned = state.autoUpdateOwned;

    if (!kIsWeb && availability == UpdateAvailability.updateAvailable) {
      restoredDownloadPath = await _repository.resolveVerifiedDownloadedPath(
        manifest: manifest,
        platformKey: state.platformKey,
      );
      if (restoredDownloadPath != null) {
        nextStatus = UpdateCenterStatus.downloadReady;
      }
    }

    if (showCheckingComplete) {
      nextStatus = nextStatus == UpdateCenterStatus.downloading
          ? UpdateCenterStatus.downloading
          : _statusForAvailability(availability);
      if (restoredDownloadPath != null) {
        nextStatus = UpdateCenterStatus.downloadReady;
      }
    }

    emit(
      state.copyWith(
        latestRelease: manifest,
        lastCheckedAt: lastCheckedAt ?? state.lastCheckedAt,
        availability: availability,
        status: nextStatus,
        downloadedPath: restoredDownloadPath,
        clearDownloadedPath:
            restoredDownloadPath == null &&
                availability != UpdateAvailability.updateAvailable,
        showUpdateBanner: _shouldShowBanner(
          availability: availability,
          version: manifest.version,
          dismissedVersion: dismissedBanner,
          autoUpdateEnabled: autoUpdateEnabled,
          autoUpdateOwned: autoUpdateOwned,
        ),
        clearErrorCode: true,
      ),
    );

    if (availability == UpdateAvailability.updateAvailable &&
        autoUpdateEnabled) {
      final handled = await _tryAutoUpdate(manifest, availability);
      if (handled) return;
    }

    if (availability == UpdateAvailability.updateAvailable && notifyIfAvailable) {
      await _maybeNotifyUpdateAvailable(
        version: manifest.version,
        build: manifest.build,
      );
    }
  }

  Future<bool> _tryAutoUpdate(
    AppReleaseManifest manifest,
    UpdateAvailability availability,
  ) async {
    if (isClosed || !state.autoUpdateEnabled) return false;

    _attachDownloadProgressListener();

    final handled = await _autoUpdateManager.tryHandleUpdateAvailable(
      manifest: manifest,
      availability: availability,
      platformKey: state.platformKey,
      callbacks: _autoUpdateCallbacks(),
    );

    if (handled && !isClosed) {
      emit(
        state.copyWith(
          showUpdateBanner: false,
          autoUpdateOwned: true,
        ),
      );
    }

    return handled;
  }

  AutoUpdateOrchestrationCallbacks _autoUpdateCallbacks() {
    return AutoUpdateOrchestrationCallbacks(
      onOwned: (owned) {
        if (isClosed) return;
        emit(state.copyWith(autoUpdateOwned: owned, showUpdateBanner: false));
      },
      onProgress: _emitDownloadProgress,
      onState: (
        status, {
        String? downloadedPath,
        bool clearDownloadedPath = false,
        double? downloadProgress,
        bool clearDownloadProgress = false,
        int? downloadReceivedBytes,
        bool clearDownloadReceivedBytes = false,
        int? downloadTotalBytes,
        bool clearDownloadTotalBytes = false,
        String? errorCode,
        bool clearErrorCode = false,
        bool? autoUpdateOwned,
      }) {
        if (isClosed) return;
        emit(
          state.copyWith(
            status: status,
            downloadedPath: downloadedPath,
            clearDownloadedPath: clearDownloadedPath,
            downloadProgress: downloadProgress,
            clearDownloadProgress: clearDownloadProgress,
            downloadReceivedBytes: downloadReceivedBytes,
            clearDownloadReceivedBytes: clearDownloadReceivedBytes,
            downloadTotalBytes: downloadTotalBytes,
            clearDownloadTotalBytes: clearDownloadTotalBytes,
            errorCode: errorCode,
            clearErrorCode: clearErrorCode,
            autoUpdateOwned: autoUpdateOwned,
            showUpdateBanner: false,
          ),
        );
      },
    );
  }

  bool _shouldShowBanner({
    required UpdateAvailability availability,
    required String? version,
    required String? dismissedVersion,
    required bool autoUpdateEnabled,
    required bool autoUpdateOwned,
  }) {
    if (autoUpdateEnabled || autoUpdateOwned) return false;
    if (availability != UpdateAvailability.updateAvailable) return false;
    if (version == null || version.isEmpty) return false;
    if (dismissedVersion == version) return false;
    return true;
  }

  Future<void> _maybeNotifyUpdateAvailable({
    required String version,
    required int build,
  }) async {
    if (state.autoUpdateEnabled || state.autoUpdateOwned) return;

    final lastNotified = await _repository.getLastNotifiedUpdateVersion();
    if (isSameAppUpdateNotification(
      storedKey: lastNotified,
      version: version,
      build: build,
    )) {
      return;
    }

    final l10n = appUpdateLocalizations(_localeCodeProvider());
    await _notificationService.showUpdateAvailable(
      version: version,
      build: build,
      title: l10n.appUpdateNotificationTitle,
      body: l10n.appUpdateNotificationBody(version),
      updateActionLabel: l10n.appUpdateActionUpdate,
    );
    await _repository.writeLastNotifiedUpdateVersion(
      appUpdateNotificationDedupeKey(version: version, build: build),
    );
  }

  bool _shouldKeepProgressListener() {
    return _repository.isDownloadInProgress ||
        state.autoUpdateOwned ||
        state.status == UpdateCenterStatus.downloading;
  }

  void _attachDownloadProgressListener() {
    _downloadCoordinator.attachProgressListener(_emitDownloadProgress);
  }

  void _emitDownloadProgress(int received, int? total) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: UpdateCenterStatus.downloading,
        downloadReceivedBytes: received,
        downloadTotalBytes: total,
        downloadProgress: total != null && total > 0 ? received / total : null,
      ),
    );
  }

  UpdateAvailability _resolveAvailability({
    required String installedVersion,
    required int installedBuild,
    required AppReleaseManifest manifest,
    required String platformKey,
  }) {
    final comparison = compareAppVersions(
      currentVersion: installedVersion,
      currentBuild: installedBuild,
      latestVersion: manifest.version,
      latestBuild: manifest.build,
    );

    switch (comparison) {
      case VersionComparison.equal:
        return UpdateAvailability.upToDate;
      case VersionComparison.currentIsNewer:
        return UpdateAvailability.aheadOfServer;
      case VersionComparison.updateAvailable:
        final artifact = manifest.artifactForPlatform(platformKey);
        if (!artifact.available || artifact.downloadUrl == null) {
          return UpdateAvailability.platformUnavailable;
        }
        return UpdateAvailability.updateAvailable;
    }
  }

  UpdateCenterStatus _statusForAvailability(UpdateAvailability availability) {
    switch (availability) {
      case UpdateAvailability.unknown:
        return UpdateCenterStatus.idle;
      case UpdateAvailability.upToDate:
        return UpdateCenterStatus.upToDate;
      case UpdateAvailability.updateAvailable:
        return UpdateCenterStatus.updateAvailable;
      case UpdateAvailability.aheadOfServer:
        return UpdateCenterStatus.aheadOfServer;
      case UpdateAvailability.platformUnavailable:
        return UpdateCenterStatus.platformUnavailable;
    }
  }
}
