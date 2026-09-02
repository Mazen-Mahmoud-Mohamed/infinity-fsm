import 'package:equatable/equatable.dart';
import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';

enum UpdateCenterStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  aheadOfServer,
  platformUnavailable,
  checkFailed,
  downloading,
  downloadReady,
  downloadFailed,
  verifying,
  installing,
}

class UpdateCenterState extends Equatable {
  const UpdateCenterState({
    this.status = UpdateCenterStatus.idle,
    this.installedVersion = '',
    this.installedBuild = 0,
    this.platformKey = 'other',
    this.latestRelease,
    this.availability = UpdateAvailability.unknown,
    this.lastCheckedAt,
    this.downloadProgress,
    this.downloadReceivedBytes,
    this.downloadTotalBytes,
    this.downloadedPath,
    this.errorCode,
    this.showUpdateBanner = false,
    this.autoUpdateEnabled = false,
    this.autoUpdateOwned = false,
  });

  final UpdateCenterStatus status;
  final String installedVersion;
  final int installedBuild;
  final String platformKey;
  final AppReleaseManifest? latestRelease;
  final UpdateAvailability availability;
  final DateTime? lastCheckedAt;
  final double? downloadProgress;
  final int? downloadReceivedBytes;
  final int? downloadTotalBytes;
  final String? downloadedPath;
  final String? errorCode;
  final bool showUpdateBanner;
  final bool autoUpdateEnabled;
  final bool autoUpdateOwned;

  bool get isBusy =>
      status == UpdateCenterStatus.checking ||
      status == UpdateCenterStatus.downloading ||
      status == UpdateCenterStatus.verifying ||
      status == UpdateCenterStatus.installing;

  bool get canDownload =>
      availability == UpdateAvailability.updateAvailable &&
      !isBusy &&
      status != UpdateCenterStatus.downloadReady &&
      status != UpdateCenterStatus.verifying;

  bool get canInstall =>
      status == UpdateCenterStatus.downloadReady &&
      downloadedPath != null &&
      downloadedPath!.isNotEmpty;

  AppReleaseArtifact? get platformArtifact =>
      latestRelease?.artifactForPlatform(platformKey);

  UpdateCenterState copyWith({
    UpdateCenterStatus? status,
    String? installedVersion,
    int? installedBuild,
    String? platformKey,
    AppReleaseManifest? latestRelease,
    bool clearLatestRelease = false,
    UpdateAvailability? availability,
    DateTime? lastCheckedAt,
    double? downloadProgress,
    bool clearDownloadProgress = false,
    int? downloadReceivedBytes,
    bool clearDownloadReceivedBytes = false,
    int? downloadTotalBytes,
    bool clearDownloadTotalBytes = false,
    String? downloadedPath,
    bool clearDownloadedPath = false,
    String? errorCode,
    bool clearErrorCode = false,
    bool? showUpdateBanner,
    bool? autoUpdateEnabled,
    bool? autoUpdateOwned,
  }) {
    return UpdateCenterState(
      status: status ?? this.status,
      installedVersion: installedVersion ?? this.installedVersion,
      installedBuild: installedBuild ?? this.installedBuild,
      platformKey: platformKey ?? this.platformKey,
      latestRelease: clearLatestRelease ? null : (latestRelease ?? this.latestRelease),
      availability: availability ?? this.availability,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      downloadProgress:
          clearDownloadProgress ? null : (downloadProgress ?? this.downloadProgress),
      downloadReceivedBytes: clearDownloadReceivedBytes
          ? null
          : (downloadReceivedBytes ?? this.downloadReceivedBytes),
      downloadTotalBytes: clearDownloadTotalBytes
          ? null
          : (downloadTotalBytes ?? this.downloadTotalBytes),
      downloadedPath:
          clearDownloadedPath ? null : (downloadedPath ?? this.downloadedPath),
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
      showUpdateBanner: showUpdateBanner ?? this.showUpdateBanner,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      autoUpdateOwned: autoUpdateOwned ?? this.autoUpdateOwned,
    );
  }

  @override
  List<Object?> get props => [
        status,
        installedVersion,
        installedBuild,
        platformKey,
        latestRelease,
        availability,
        lastCheckedAt,
        downloadProgress,
        downloadReceivedBytes,
        downloadTotalBytes,
        downloadedPath,
        errorCode,
        showUpdateBanner,
        autoUpdateEnabled,
        autoUpdateOwned,
      ];
}
