import 'package:equatable/equatable.dart';

class AppReleaseArtifact extends Equatable {
  const AppReleaseArtifact({
    required this.available,
    this.downloadUrl,
    this.sha256,
    this.size,
  });

  final bool available;
  final String? downloadUrl;
  final String? sha256;
  final int? size;

  @override
  List<Object?> get props => [available, downloadUrl, sha256, size];
}

class AppReleaseManifest extends Equatable {
  const AppReleaseManifest({
    required this.version,
    required this.build,
    required this.channel,
    this.releaseDate,
    this.releaseNotes,
    required this.windows,
    required this.android,
  });

  final String version;
  final int build;
  final String channel;
  final DateTime? releaseDate;
  final String? releaseNotes;
  final AppReleaseArtifact windows;
  final AppReleaseArtifact android;

  bool get isConfigured => version.isNotEmpty && build >= 0;

  AppReleaseArtifact artifactForPlatform(String platformKey) {
    switch (platformKey) {
      case 'windows':
        return windows;
      case 'android':
        return android;
      default:
        return const AppReleaseArtifact(available: false);
    }
  }

  @override
  List<Object?> get props => [
        version,
        build,
        channel,
        releaseDate,
        releaseNotes,
        windows,
        android,
      ];
}

enum UpdateAvailability {
  unknown,
  upToDate,
  updateAvailable,
  aheadOfServer,
  platformUnavailable,
}
