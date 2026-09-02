import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppUpdateDownloadService {
  Future<File> downloadArtifact({
    required AppReleaseArtifact artifact,
    required String platformKey,
    required String version,
    void Function(int received, int? total)? onProgress,
  }) async {
    final url = artifact.downloadUrl;
    if (url == null || url.isEmpty) {
      throw const AppUpdateDownloadException('missing_download_url');
    }

    final directory = await _updatesDirectory();
    final extension = platformKey == 'android' ? 'apk' : 'exe';
    final safeVersion = version.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '_');
    final destination = File(
      p.join(directory.path, 'infinity-$platformKey-$safeVersion.$extension'),
    );
    if (await destination.exists()) {
      await destination.delete();
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
      ),
    );

    try {
      await dio.download(
        url,
        destination.path,
        onReceiveProgress: onProgress,
      );
    } on DioException {
      if (await destination.exists()) {
        await destination.delete();
      }
      rethrow;
    }

    if (artifact.sha256 != null && artifact.sha256!.isNotEmpty) {
      final valid = await _verifySha256(destination, artifact.sha256!);
      if (!valid) {
        await destination.delete();
        throw const AppUpdateDownloadException('checksum_mismatch');
      }
    }

    if (artifact.size != null && artifact.size! > 0) {
      final length = await destination.length();
      if (length != artifact.size) {
        await destination.delete();
        throw const AppUpdateDownloadException('size_mismatch');
      }
    }

    return destination;
  }

  Future<Directory> _updatesDirectory() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'updates'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<bool> _verifySha256(File file, String expectedHex) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    return digest.toLowerCase() == expectedHex.toLowerCase();
  }
}

class AppUpdateDownloadException implements Exception {
  const AppUpdateDownloadException(this.code);

  final String code;

  @override
  String toString() => 'AppUpdateDownloadException($code)';
}
