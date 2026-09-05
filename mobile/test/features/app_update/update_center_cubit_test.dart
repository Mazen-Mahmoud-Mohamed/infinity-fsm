import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/app_update/data/repositories/app_update_repository_impl.dart';
import 'package:mobile/features/app_update/data/services/app_auto_update_manager.dart';
import 'package:mobile/features/app_update/data/services/app_update_download_coordinator.dart';
import 'package:mobile/features/app_update/data/services/app_update_download_service.dart';
import 'package:mobile/features/app_update/data/services/app_update_notification_service.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';
import 'package:mobile/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_cubit.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_state.dart';

class _FakeAppUpdateRepository implements AppUpdateRepository {
  _FakeAppUpdateRepository({
    this.installed = (version: '1.0.0', build: 1),
    this.manifest,
    this.checkThrows = false,
    this.platformKey = 'windows',
    this.autoUpdateEnabled = false,
  });

  final ({String version, int build}) installed;
  final AppReleaseManifest? manifest;
  final bool checkThrows;
  final String platformKey;
  bool autoUpdateEnabled;

  String? lastNotified;
  String? dismissedBanner;
  DateTime? lastAutoCheck;
  bool downloading = false;
  int downloadCount = 0;
  int installCount = 0;
  String? processingVersion;
  String? failedLock;
  DateTime? failedAt;
  String? installAttemptedLock;
  String? downloadedPath;
  String? downloadedVersion;
  int? downloadedBuild;

  @override
  String get currentPlatformKey => platformKey;

  @override
  bool get isDownloadInProgress => downloading;

  @override
  Future<AppReleaseManifest?> checkForUpdates({required String channel}) async {
    if (checkThrows) {
      throw const AppUpdateCheckException('offline');
    }
    return manifest;
  }

  @override
  Future<AppReleaseManifest?> getCachedRelease() async => manifest;

  @override
  Future<DateTime?> getLastCheckedAt() async => null;

  @override
  Future<({String version, int build})> getInstalledVersion() async =>
      installed;

  @override
  Future<String> downloadUpdate({
    required AppReleaseArtifact artifact,
    required String platformKey,
    required String version,
    required int build,
    void Function(int received, int? total)? onProgress,
  }) async {
    downloadCount += 1;
    downloading = true;
    onProgress?.call(50, 100);
    onProgress?.call(100, 100);
    downloading = false;
    downloadedPath = '/tmp/update.exe';
    downloadedVersion = version;
    downloadedBuild = build;
    return downloadedPath!;
  }

  @override
  Future<String?> resolveVerifiedDownloadedPath({
    required AppReleaseManifest manifest,
    required String platformKey,
  }) async {
    if (downloadedPath == null) return null;
    if (downloadedVersion != manifest.version) return null;
    if (downloadedBuild != manifest.build) return null;
    return downloadedPath;
  }

  @override
  Future<void> clearDownloadedArtifact() async {
    downloadedPath = null;
    downloadedVersion = null;
    downloadedBuild = null;
  }

  @override
  Future<int> cleanupStaleUpdateArtifacts({
    required String installedVersion,
    required int installedBuild,
    String? keepPath,
  }) async {
    return 0;
  }

  @override
  Future<int?> getDownloadedArtifactBuild() async => downloadedBuild;

  @override
  Future<void> installDownloadedUpdate({
    required String filePath,
    required String platformKey,
  }) async {
    installCount += 1;
  }

  @override
  Future<String?> getDownloadedArtifactPath() async => downloadedPath;

  @override
  Future<String?> getDownloadedArtifactVersion() async => downloadedVersion;

  @override
  Future<String?> getDismissedBannerVersion() async => dismissedBanner;

  @override
  Future<void> writeDismissedBannerVersion(String version) async {
    dismissedBanner = version;
  }

  @override
  Future<DateTime?> getLastAutoCheckAt() async => lastAutoCheck;

  @override
  Future<void> writeLastAutoCheckAt(DateTime value) async {
    lastAutoCheck = value;
  }

  @override
  Future<String?> getLastNotifiedUpdateVersion() async => lastNotified;

  @override
  Future<void> writeLastNotifiedUpdateVersion(String version) async {
    lastNotified = version;
  }

  @override
  Future<bool> isAutoUpdateEnabled() async => autoUpdateEnabled;

  @override
  Future<void> writeAutoUpdateEnabled(bool enabled) async {
    autoUpdateEnabled = enabled;
  }

  @override
  Future<String?> getAutoUpdateProcessingVersion() async => processingVersion;

  @override
  Future<void> writeAutoUpdateProcessingVersion(String version) async {
    processingVersion = version;
  }

  @override
  Future<void> clearAutoUpdateProcessingVersion() async {
    processingVersion = null;
  }

  @override
  Future<String?> getAutoUpdateFailedLock() async => failedLock;

  @override
  Future<void> writeAutoUpdateFailedLock(String lock) async {
    failedLock = lock;
  }

  @override
  Future<DateTime?> getAutoUpdateFailedAt() async => failedAt;

  @override
  Future<void> writeAutoUpdateFailedAt(DateTime value) async {
    failedAt = value;
  }

  @override
  Future<String?> getAutoUpdateInstallAttemptedLock() async =>
      installAttemptedLock;

  @override
  Future<void> writeAutoUpdateInstallAttemptedLock(String lock) async {
    installAttemptedLock = lock;
  }

  @override
  Future<void> clearAutoUpdateInstallAttemptedLock() async {
    installAttemptedLock = null;
  }
}

class _RecordingNotificationService extends AppUpdateNotificationService {
  int showCount = 0;
  String? lastVersion;
  int? lastBuild;

  @override
  Future<void> showUpdateAvailable({
    required String version,
    required int build,
    required String title,
    required String body,
    required String updateActionLabel,
  }) async {
    showCount += 1;
    lastVersion = version;
    lastBuild = build;
  }
}

AppReleaseManifest _manifest({
  String version = '1.0.1',
  int build = 2,
  bool windows = true,
  bool android = false,
}) {
  return AppReleaseManifest(
    version: version,
    build: build,
    channel: 'stable',
    releaseNotes: 'Notes',
    releaseDate: DateTime.utc(2026, 9, 2),
    windows: AppReleaseArtifact(
      available: windows,
      downloadUrl: windows ? 'https://cdn.example.com/setup.exe' : null,
      sha256: 'abc',
      size: 100,
    ),
    android: AppReleaseArtifact(
      available: android,
      downloadUrl: android ? 'https://cdn.example.com/app-release.apk' : null,
      sha256: 'def',
      size: 200,
    ),
  );
}

UpdateCenterCubit _createCubit(
  AppUpdateRepository repository, {
  AppUpdateNotificationService? notificationService,
  AppAutoUpdateManager? autoUpdateManager,
}) {
  return UpdateCenterCubit(
    repository: repository,
    downloadCoordinator: AppUpdateDownloadCoordinator(AppUpdateDownloadService()),
    notificationService: notificationService ?? _RecordingNotificationService(),
    autoUpdateManager: autoUpdateManager ?? AppAutoUpdateManager(repository),
    releaseChannel: 'stable',
    localeCodeProvider: () => 'en',
  );
}

void main() {
  group('UpdateCenterCubit', () {
    test('reports up to date when server matches installed version', () async {
      final cubit = _createCubit(
        _FakeAppUpdateRepository(
          manifest: _manifest(version: '1.0.0', build: 1),
        ),
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.upToDate);
      await cubit.close();
    });

    test('reports update available for newer server release', () async {
      final cubit = _createCubit(_FakeAppUpdateRepository(manifest: _manifest()));
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.updateAvailable);
      expect(cubit.state.latestRelease?.version, '1.0.1');
      await cubit.close();
    });

    test('handles offline check failure while keeping cached release', () async {
      final cubit = _createCubit(
        _FakeAppUpdateRepository(
          manifest: _manifest(),
          checkThrows: true,
        ),
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.checkFailed);
      expect(cubit.state.errorCode, 'offline');
      expect(cubit.state.latestRelease, isNotNull);
      await cubit.close();
    });

    test('marks platform unavailable when artifact missing', () async {
      final cubit = _createCubit(
        _FakeAppUpdateRepository(
          manifest: _manifest(windows: false),
          platformKey: 'windows',
        ),
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.platformUnavailable);
      await cubit.close();
    });

    test('reports ahead of server when installed version is newer', () async {
      final cubit = _createCubit(
        _FakeAppUpdateRepository(
          installed: (version: '1.1.0', build: 3),
          manifest: _manifest(version: '1.0.9', build: 9),
        ),
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.aheadOfServer);
      await cubit.close();
    });

    test('handles null manifest as invalid response', () async {
      final cubit = _createCubit(_FakeAppUpdateRepository(manifest: null));
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.checkFailed);
      expect(cubit.state.errorCode, 'invalid_response');
      await cubit.close();
    });

    test('marks android unavailable when artifact missing', () async {
      final cubit = _createCubit(
        _FakeAppUpdateRepository(
          manifest: _manifest(windows: false),
          platformKey: 'android',
        ),
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.platformUnavailable);
      await cubit.close();
    });

    test('auto check notifies once and supports banner dismiss when OFF', () async {
      final notificationService = _RecordingNotificationService();
      final cubit = _createCubit(
        _FakeAppUpdateRepository(manifest: _manifest()),
        notificationService: notificationService,
      );

      await cubit.initialize();
      await cubit.maybeAutoCheck(
        reason: AppUpdateAutoCheckReason.authenticated,
      );

      expect(cubit.state.showUpdateBanner, isTrue);
      expect(notificationService.showCount, 1);
      expect(notificationService.lastVersion, '1.0.1');
      expect(notificationService.lastBuild, 2);

      await cubit.maybeAutoCheck(reason: AppUpdateAutoCheckReason.resumed);
      expect(notificationService.showCount, 1);

      await cubit.dismissUpdateBanner();
      expect(cubit.state.showUpdateBanner, isFalse);

      await cubit.close();
    });

    test('connectivity restore notifies unseen release despite recent auto-check',
        () async {
      final notificationService = _RecordingNotificationService();
      final repository = _FakeAppUpdateRepository(manifest: _manifest());
      repository.lastAutoCheck = DateTime.now().toUtc();
      final cubit = _createCubit(
        repository,
        notificationService: notificationService,
      );

      await cubit.initialize();
      await cubit.maybeAutoCheck(
        reason: AppUpdateAutoCheckReason.connectivityRestored,
      );

      expect(notificationService.showCount, 1);
      expect(repository.lastNotified, 'app-update:v1.0.1:2');

      await cubit.maybeAutoCheck(
        reason: AppUpdateAutoCheckReason.connectivityRestored,
      );
      expect(notificationService.showCount, 1);

      await cubit.close();
    });

    test('already notified release is not re-notified on connectivity restore',
        () async {
      final notificationService = _RecordingNotificationService();
      final repository = _FakeAppUpdateRepository(manifest: _manifest());
      repository.lastNotified = 'app-update:v1.0.1:2';
      final cubit = _createCubit(
        repository,
        notificationService: notificationService,
      );

      await cubit.initialize();
      await cubit.maybeAutoCheck(
        reason: AppUpdateAutoCheckReason.connectivityRestored,
      );

      expect(notificationService.showCount, 0);
      expect(cubit.state.showUpdateBanner, isTrue);

      await cubit.close();
    });

    test('v1.0.1 stored artifact does not satisfy v1.0.2 manifest', () async {
      final repository = _FakeAppUpdateRepository(manifest: _manifest(version: '1.0.2', build: 3));
      repository.downloadedPath = '/tmp/infinity-android-1.0.1-b2.apk';
      repository.downloadedVersion = '1.0.1';
      repository.downloadedBuild = 2;

      final resolved = await repository.resolveVerifiedDownloadedPath(
        manifest: _manifest(version: '1.0.2', build: 3),
        platformKey: 'android',
      );

      expect(resolved, isNull);
    });

    test('download completes with progress', () async {
      final cubit = _createCubit(_FakeAppUpdateRepository(manifest: _manifest()));
      await cubit.initialize();
      await cubit.checkForUpdates();
      await cubit.downloadUpdate();
      expect(cubit.state.status, UpdateCenterStatus.downloadReady);
      expect(cubit.state.downloadProgress, 1);
      await cubit.close();
    });

    test('auto update defaults to OFF and persists ON', () async {
      final repository = _FakeAppUpdateRepository(manifest: _manifest());
      final cubit = _createCubit(repository);

      await cubit.initialize();
      expect(cubit.state.autoUpdateEnabled, isFalse);

      await cubit.setAutoUpdateEnabled(true);
      expect(cubit.state.autoUpdateEnabled, isTrue);
      expect(repository.autoUpdateEnabled, isTrue);

      await cubit.close();
    });

    test('auto update ON suppresses notification and starts download', () async {
      final notificationService = _RecordingNotificationService();
      final repository = _FakeAppUpdateRepository(
        manifest: _manifest(),
        autoUpdateEnabled: true,
      );
      final cubit = _createCubit(
        repository,
        notificationService: notificationService,
      );

      await cubit.initialize();
      await cubit.maybeAutoCheck(
        reason: AppUpdateAutoCheckReason.authenticated,
      );

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.showUpdateBanner, isFalse);
      expect(notificationService.showCount, 0);
      expect(cubit.state.autoUpdateOwned, isTrue);
      expect(repository.downloadCount, 1);
      expect(repository.installCount, 1);

      await cubit.close();
    });

    test('auto update ON does not duplicate download on repeated checks', () async {
      final repository = _FakeAppUpdateRepository(
        manifest: _manifest(),
        autoUpdateEnabled: true,
      );
      final cubit = _createCubit(repository);

      await cubit.initialize();
      await cubit.maybeAutoCheck(
        reason: AppUpdateAutoCheckReason.authenticated,
      );
      await Future<void>.delayed(Duration.zero);
      await cubit.maybeAutoCheck(reason: AppUpdateAutoCheckReason.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(repository.downloadCount, 1);

      await cubit.close();
    });

    test('toggle ON during manual download reuses coordinator', () async {
      final repository = _FakeAppUpdateRepository(manifest: _manifest());
      final cubit = _createCubit(repository);

      await cubit.initialize();
      await cubit.checkForUpdates();
      final downloadFuture = cubit.downloadUpdate();

      await cubit.setAutoUpdateEnabled(true);
      await downloadFuture;
      await Future<void>.delayed(Duration.zero);

      expect(repository.downloadCount, 1);

      await cubit.close();
    });
  });

  group('AppAutoUpdateManager', () {
    test('lock key includes version and platform', () {
      expect(
        AppAutoUpdateManager.lockKey(version: '1.0.2', platformKey: 'windows'),
        'auto-update:v1.0.2:windows',
      );
    });

    test('returns false when auto update disabled', () async {
      final repository = _FakeAppUpdateRepository(manifest: _manifest());
      final manager = AppAutoUpdateManager(repository);
      var stateChanges = 0;

      final handled = await manager.tryHandleUpdateAvailable(
        manifest: _manifest(),
        availability: UpdateAvailability.updateAvailable,
        platformKey: 'windows',
        callbacks: AutoUpdateOrchestrationCallbacks(
          onState: (_, {clearDownloadedPath = false, clearDownloadProgress = false, clearDownloadReceivedBytes = false, clearDownloadTotalBytes = false, clearErrorCode = false, downloadedPath, downloadProgress, downloadReceivedBytes, downloadTotalBytes, errorCode, autoUpdateOwned}) {
            stateChanges += 1;
          },
          onProgress: (_, __) {},
          onOwned: (_) {},
        ),
      );

      expect(handled, isFalse);
      expect(stateChanges, 0);
    });
  });
}
