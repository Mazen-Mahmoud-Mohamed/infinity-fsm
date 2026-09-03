import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_artifact_verifier.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_release_identity.dart';
import 'package:mobile/features/app_update/domain/utils/version_comparator.dart';

class AppUpdateDownloadService {
  AppUpdateDownloadService({
    Dio? dio,
    AppUpdateArtifactVerifier? verifier,
    Future<Directory> Function()? updatesDirectoryProvider,
  })  : _dio = dio ?? _createDio(),
        _verifier = verifier ?? const AppUpdateArtifactVerifier(),
        _updatesDirectoryProvider =
            updatesDirectoryProvider ?? _defaultUpdatesDirectory;

  final AppUpdateArtifactVerifier _verifier;
  final Dio _dio;
  final Future<Directory> Function() _updatesDirectoryProvider;

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 30),
      ),
    );
  }

  Future<File> downloadArtifact({
    required AppReleaseArtifact artifact,
    required String platformKey,
    required String version,
    required int build,
    void Function(int received, int? total)? onProgress,
  }) async {
    final url = artifact.downloadUrl;
    if (url == null || url.isEmpty) {
      throw const AppUpdateDownloadException('missing_download_url');
    }

    final directory = await _updatesDirectoryProvider();
    final destination = File(
      p.join(
        directory.path,
        AppUpdateReleaseIdentity(version: version, build: build)
            .fileName(platformKey: platformKey),
      ),
    );

    var startByte = 0;
    if (await destination.exists()) {
      startByte = await destination.length();
      if (artifact.size != null &&
          artifact.size! > 0 &&
          startByte >= artifact.size!) {
        await destination.delete();
        startByte = 0;
      }
    }

    final totalExpected = artifact.size;
    if (totalExpected != null && totalExpected > 0) {
      onProgress?.call(startByte, totalExpected);
    }

    try {
      await _downloadWithOptionalResume(
        url: url,
        destination: destination,
        startByte: startByte,
        onProgress: (received, total) {
          final absoluteReceived = startByte + received;
          final absoluteTotal = total != null ? startByte + total : totalExpected;
          onProgress?.call(absoluteReceived, absoluteTotal);
        },
      );
    } on DioException {
      rethrow;
    }

    final valid = await _verifier.verify(file: destination, artifact: artifact);
    if (!valid) {
      await destination.delete();
      throw const AppUpdateDownloadException('verification_failed');
    }

    return destination;
  }

  /// Deletes stale Update Center artifacts under the updates directory.
  ///
  /// Keeps:
  /// - [keepPath] when provided (active pending download)
  /// - artifacts newer than the currently installed version/build
  ///
  /// Removes older/equal versioned APK/EXE files. Never touches anything
  /// outside the updates directory. Does not delete the installed app or
  /// business/auth data.
  Future<int> cleanupStaleArtifacts({
    required String installedVersion,
    required int installedBuild,
    String? keepPath,
  }) async {
    final directory = await _updatesDirectoryProvider();
    if (!await directory.exists()) return 0;

    final normalizedKeep = keepPath == null || keepPath.isEmpty
        ? null
        : p.normalize(keepPath);
    var deleted = 0;

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final path = p.normalize(entity.path);
      if (normalizedKeep != null && path == normalizedKeep) {
        continue;
      }

      final name = p.basename(path);
      if (!name.startsWith('infinity-')) {
        continue;
      }

      final identity = AppUpdateReleaseIdentity.tryParseFileName(name);
      if (identity != null) {
        final comparison = compareAppVersions(
          currentVersion: installedVersion,
          currentBuild: installedBuild,
          latestVersion: identity.version,
          latestBuild: identity.build,
        );
        // Keep only pending updates that are newer than what is installed.
        if (comparison == VersionComparison.updateAvailable) {
          continue;
        }
      }

      try {
        await entity.delete();
        deleted++;
      } on Object {
        // Best-effort cleanup; ignore files locked by the package installer.
      }
    }

    return deleted;
  }

  Future<void> _downloadWithOptionalResume({
    required String url,
    required File destination,
    required int startByte,
    required void Function(int received, int? total) onProgress,
  }) async {
    if (startByte > 0) {
      try {
        final response = await _dio.get<ResponseBody>(
          url,
          options: Options(
            headers: {'Range': 'bytes=$startByte-'},
            responseType: ResponseType.stream,
            validateStatus: (status) =>
                status != null && (status == 200 || status == 206),
          ),
        );

        final raf = await destination.open(mode: FileMode.append);
        var received = startByte;
        await for (final chunk in response.data!.stream) {
          await raf.writeFrom(chunk);
          received += chunk.length;
          onProgress(received - startByte, null);
        }
        await raf.close();
        return;
      } on DioException {
        if (await destination.exists()) {
          await destination.delete();
        }
      } on Object {
        if (await destination.exists()) {
          await destination.delete();
        }
      }
    }

    if (await destination.exists()) {
      await destination.delete();
    }

    await _dio.download(
      url,
      destination.path,
      onReceiveProgress: onProgress,
    );
  }

  static Future<Directory> _defaultUpdatesDirectory() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'updates'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

class AppUpdateDownloadException implements Exception {
  const AppUpdateDownloadException(this.code);

  final String code;

  @override
  String toString() => 'AppUpdateDownloadException($code)';
}
