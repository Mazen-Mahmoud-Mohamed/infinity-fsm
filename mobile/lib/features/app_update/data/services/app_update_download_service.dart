import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class AppUpdateDownloadService {
  AppUpdateDownloadService({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

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
