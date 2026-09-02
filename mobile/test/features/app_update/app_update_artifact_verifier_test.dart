import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_artifact_verifier.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_release_identity.dart';

void main() {
  group('AppUpdateReleaseIdentity', () {
    test('builds versioned file names', () {
      const identity = AppUpdateReleaseIdentity(version: '1.0.2', build: 3);
      expect(
        identity.fileName(platformKey: 'android'),
        'infinity-android-1.0.2-b3.apk',
      );
    });

    test('requires version and build to match stored identity', () {
      const identity = AppUpdateReleaseIdentity(version: '1.0.2', build: 3);
      expect(
        identity.matchesVersionAndBuild(
          storedVersion: '1.0.2',
          storedBuild: 3,
        ),
        isTrue,
      );
      expect(
        identity.matchesVersionAndBuild(
          storedVersion: '1.0.2',
          storedBuild: 2,
        ),
        isFalse,
      );
      expect(
        identity.matchesVersionAndBuild(
          storedVersion: '1.0.1',
          storedBuild: 2,
        ),
        isFalse,
      );
    });
  });

  group('AppUpdateArtifactVerifier', () {
    late Directory tempDir;
    const verifier = AppUpdateArtifactVerifier();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('infinity-update-test-');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('accepts matching size and sha256', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final file = File('${tempDir.path}/artifact.apk');
      await file.writeAsBytes(bytes);
      final digest = sha256.convert(bytes).toString();

      final valid = await verifier.verify(
        file: file,
        artifact: AppReleaseArtifact(
          available: true,
          downloadUrl: 'https://example.com/app-release.apk',
          sha256: digest,
          size: bytes.length,
        ),
      );

      expect(valid, isTrue);
    });

    test('rejects wrong sha256', () async {
      final file = File('${tempDir.path}/artifact.apk');
      await file.writeAsBytes(const [9, 9, 9]);
      final wrongHash = 'a' * 64;

      final valid = await verifier.verify(
        file: file,
        artifact: AppReleaseArtifact(
          available: true,
          downloadUrl: 'https://example.com/app-release.apk',
          sha256: wrongHash,
          size: 3,
        ),
      );

      expect(valid, isFalse);
    });

    test('rejects wrong size', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final file = File('${tempDir.path}/artifact.apk');
      await file.writeAsBytes(bytes);

      final valid = await verifier.verify(
        file: file,
        artifact: AppReleaseArtifact(
          available: true,
          downloadUrl: 'https://example.com/app-release.apk',
          sha256: sha256.convert(bytes).toString(),
          size: 999,
        ),
      );

      expect(valid, isFalse);
    });
  });
}
