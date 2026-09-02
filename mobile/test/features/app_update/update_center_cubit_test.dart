import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/app_update/data/repositories/app_update_repository_impl.dart';
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
  });

  final ({String version, int build}) installed;
  final AppReleaseManifest? manifest;
  final bool checkThrows;
  final String platformKey;

  @override
  String get currentPlatformKey => platformKey;

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
    void Function(int received, int? total)? onProgress,
  }) async {
    return '/tmp/update.exe';
  }

  @override
  Future<void> installDownloadedUpdate({
    required String filePath,
    required String platformKey,
  }) async {}

  @override
  Future<String?> getDownloadedArtifactPath() async => null;

  @override
  Future<String?> getDownloadedArtifactVersion() async => null;
}

AppReleaseManifest _manifest({
  String version = '1.0.1',
  int build = 2,
  bool windows = true,
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
    android: const AppReleaseArtifact(available: false),
  );
}

void main() {
  group('UpdateCenterCubit', () {
    test('reports up to date when server matches installed version', () async {
      final cubit = UpdateCenterCubit(
        repository: _FakeAppUpdateRepository(
          manifest: _manifest(version: '1.0.0', build: 1),
        ),
        releaseChannel: 'stable',
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.upToDate);
      await cubit.close();
    });

    test('reports update available for newer server release', () async {
      final cubit = UpdateCenterCubit(
        repository: _FakeAppUpdateRepository(manifest: _manifest()),
        releaseChannel: 'stable',
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.updateAvailable);
      expect(cubit.state.latestRelease?.version, '1.0.1');
      await cubit.close();
    });

    test('handles offline check failure while keeping cached release', () async {
      final cubit = UpdateCenterCubit(
        repository: _FakeAppUpdateRepository(
          manifest: _manifest(),
          checkThrows: true,
        ),
        releaseChannel: 'stable',
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.checkFailed);
      expect(cubit.state.errorCode, 'offline');
      expect(cubit.state.latestRelease, isNotNull);
      await cubit.close();
    });

    test('marks platform unavailable when artifact missing', () async {
      final cubit = UpdateCenterCubit(
        repository: _FakeAppUpdateRepository(
          manifest: _manifest(windows: false),
          platformKey: 'windows',
        ),
        releaseChannel: 'stable',
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.platformUnavailable);
      await cubit.close();
    });

    test('reports ahead of server when installed version is newer', () async {
      final cubit = UpdateCenterCubit(
        repository: _FakeAppUpdateRepository(
          installed: (version: '1.1.0', build: 3),
          manifest: _manifest(version: '1.0.9', build: 9),
        ),
        releaseChannel: 'stable',
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.aheadOfServer);
      await cubit.close();
    });

    test('handles null manifest as invalid response', () async {
      final cubit = UpdateCenterCubit(
        repository: _FakeAppUpdateRepository(manifest: null),
        releaseChannel: 'stable',
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.checkFailed);
      expect(cubit.state.errorCode, 'invalid_response');
      await cubit.close();
    });

    test('marks android unavailable when artifact missing', () async {
      final cubit = UpdateCenterCubit(
        repository: _FakeAppUpdateRepository(
          manifest: _manifest(windows: false),
          platformKey: 'android',
        ),
        releaseChannel: 'stable',
      );
      await cubit.initialize();
      await cubit.checkForUpdates();
      expect(cubit.state.status, UpdateCenterStatus.platformUnavailable);
      await cubit.close();
    });
  });
}
