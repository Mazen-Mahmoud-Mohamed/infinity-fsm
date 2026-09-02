import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/app_update/domain/utils/version_comparator.dart';

void main() {
  group('compareAppVersions', () {
    test('same version and build returns equal', () {
      expect(
        compareAppVersions(
          currentVersion: '1.0.0',
          currentBuild: 1,
          latestVersion: '1.0.0',
          latestBuild: 1,
        ),
        VersionComparison.equal,
      );
    });

    test('higher server version returns updateAvailable', () {
      expect(
        compareAppVersions(
          currentVersion: '1.0.0',
          currentBuild: 1,
          latestVersion: '1.0.1',
          latestBuild: 1,
        ),
        VersionComparison.updateAvailable,
      );
    });

    test('same version with higher build returns updateAvailable', () {
      expect(
        compareAppVersions(
          currentVersion: '1.0.0',
          currentBuild: 1,
          latestVersion: '1.0.0',
          latestBuild: 2,
        ),
        VersionComparison.updateAvailable,
      );
    });

    test('current ahead of server returns currentIsNewer', () {
      expect(
        compareAppVersions(
          currentVersion: '1.1.0',
          currentBuild: 3,
          latestVersion: '1.0.9',
          latestBuild: 9,
        ),
        VersionComparison.currentIsNewer,
      );
    });

    test('handles multi-part semantic versions', () {
      expect(
        compareAppVersions(
          currentVersion: '1.0.0',
          currentBuild: 1,
          latestVersion: '2.0.0',
          latestBuild: 1,
        ),
        VersionComparison.updateAvailable,
      );
    });
  });
}
