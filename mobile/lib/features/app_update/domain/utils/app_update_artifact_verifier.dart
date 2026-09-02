import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';

/// Verifies a downloaded update artifact against manifest metadata.
class AppUpdateArtifactVerifier {
  const AppUpdateArtifactVerifier();

  Future<bool> verify({
    required File file,
    required AppReleaseArtifact artifact,
  }) async {
    if (!await file.exists()) {
      return false;
    }

    if (artifact.sha256 != null && artifact.sha256!.isNotEmpty) {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes).toString();
      if (digest.toLowerCase() != artifact.sha256!.toLowerCase()) {
        return false;
      }
    }

    if (artifact.size != null && artifact.size! > 0) {
      final length = await file.length();
      if (length != artifact.size) {
        return false;
      }
    }

    return true;
  }
}
