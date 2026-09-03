import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/app_update/data/services/app_update_download_service.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_release_identity.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AppUpdateDownloadService.cleanupStaleArtifacts', () {
    late Directory tempDir;
    late AppUpdateDownloadService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('infinity-updates-clean-');
      service = AppUpdateDownloadService(
        updatesDirectoryProvider: () async => tempDir,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<File> writeArtifact({
      required String version,
      required int build,
      required String platformKey,
    }) async {
      final name = AppUpdateReleaseIdentity(version: version, build: build)
          .fileName(platformKey: platformKey);
      final file = File(p.join(tempDir.path, name));
      await file.writeAsBytes(List<int>.filled(32, 1));
      return file;
    }

    test('deletes installed and older APKs but keeps newer pending update', () async {
      final oldFile = await writeArtifact(
        version: '1.0.6',
        build: 7,
        platformKey: 'android',
      );
      final currentFile = await writeArtifact(
        version: '1.0.7',
        build: 8,
        platformKey: 'android',
      );
      final pendingFile = await writeArtifact(
        version: '1.0.8',
        build: 9,
        platformKey: 'android',
      );

      final deleted = await service.cleanupStaleArtifacts(
        installedVersion: '1.0.7',
        installedBuild: 8,
        keepPath: pendingFile.path,
      );

      expect(deleted, 2);
      expect(await oldFile.exists(), isFalse);
      expect(await currentFile.exists(), isFalse);
      expect(await pendingFile.exists(), isTrue);
    });

    test('after upgrade deletes previous pending APK for installed version', () async {
      final installedArtifact = await writeArtifact(
        version: '1.0.8',
        build: 9,
        platformKey: 'android',
      );
      final older = await writeArtifact(
        version: '1.0.5',
        build: 6,
        platformKey: 'android',
      );

      final deleted = await service.cleanupStaleArtifacts(
        installedVersion: '1.0.8',
        installedBuild: 9,
      );

      expect(deleted, 2);
      expect(await installedArtifact.exists(), isFalse);
      expect(await older.exists(), isFalse);
    });

    test('never deletes keepPath even if not newer', () async {
      final keep = await writeArtifact(
        version: '1.0.7',
        build: 8,
        platformKey: 'android',
      );

      final deleted = await service.cleanupStaleArtifacts(
        installedVersion: '1.0.7',
        installedBuild: 8,
        keepPath: keep.path,
      );

      expect(deleted, 0);
      expect(await keep.exists(), isTrue);
    });
  });
}
