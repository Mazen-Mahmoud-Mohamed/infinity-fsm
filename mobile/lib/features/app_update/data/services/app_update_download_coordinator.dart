import 'dart:async';

import 'package:mobile/features/app_update/data/services/app_update_download_service.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';

typedef AppUpdateDownloadProgress = void Function(int received, int? total);

/// Application-level download lifecycle independent from Update Center UI.
class AppUpdateDownloadCoordinator {
  AppUpdateDownloadCoordinator(this._downloadService);

  final AppUpdateDownloadService _downloadService;

  Future<String>? _activeDownload;
  AppUpdateDownloadProgress? _progressListener;
  int _lastReceived = 0;
  int? _lastTotal;

  bool get isDownloading => _activeDownload != null;

  int get lastReceivedBytes => _lastReceived;

  int? get lastTotalBytes => _lastTotal;

  void attachProgressListener(AppUpdateDownloadProgress? listener) {
    _progressListener = listener;
    if (listener != null && isDownloading) {
      listener(_lastReceived, _lastTotal);
    }
  }

  Future<String> downloadArtifact({
    required AppReleaseArtifact artifact,
    required String platformKey,
    required String version,
    required int build,
    AppUpdateDownloadProgress? onProgress,
  }) {
    if (_activeDownload != null) {
      if (onProgress != null) {
        attachProgressListener(onProgress);
      }
      return _activeDownload!;
    }

    attachProgressListener(onProgress);

    _lastReceived = 0;
    _lastTotal = null;

    _activeDownload = _downloadService
        .downloadArtifact(
          artifact: artifact,
          platformKey: platformKey,
          version: version,
          build: build,
          onProgress: (received, total) {
            _lastReceived = received;
            _lastTotal = total;
            _progressListener?.call(received, total);
          },
        )
        .then((file) => file.path)
        .whenComplete(() {
          _activeDownload = null;
        });

    return _activeDownload!;
  }
}
