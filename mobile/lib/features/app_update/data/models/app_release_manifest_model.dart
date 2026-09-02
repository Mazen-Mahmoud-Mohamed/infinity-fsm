import 'package:mobile/features/app_update/domain/entities/app_release_manifest.dart';

class AppReleaseManifestModel extends AppReleaseManifest {
  const AppReleaseManifestModel({
    required super.version,
    required super.build,
    required super.channel,
    super.releaseDate,
    super.releaseNotes,
    required super.windows,
    required super.android,
  });

  factory AppReleaseManifestModel.fromJson(Map<String, dynamic> json) {
    final version = json['version']?.toString() ?? '';
    final buildRaw = json['build'];
    final build = buildRaw is int
        ? buildRaw
        : int.tryParse(buildRaw?.toString() ?? '') ?? -1;

    DateTime? releaseDate;
    final releaseDateRaw = json['releaseDate']?.toString();
    if (releaseDateRaw != null && releaseDateRaw.isNotEmpty) {
      releaseDate = DateTime.tryParse(releaseDateRaw);
    }

    return AppReleaseManifestModel(
      version: version,
      build: build,
      channel: json['channel']?.toString() ?? 'stable',
      releaseDate: releaseDate,
      releaseNotes: json['releaseNotes']?.toString(),
      windows: _artifactFromJson(json['windows'] as Map<String, dynamic>?),
      android: _artifactFromJson(json['android'] as Map<String, dynamic>?),
    );
  }

  static AppReleaseArtifact _artifactFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AppReleaseArtifact(available: false);
    }
    final sizeRaw = json['size'];
    final size = sizeRaw is int
        ? sizeRaw
        : int.tryParse(sizeRaw?.toString() ?? '');

    return AppReleaseArtifact(
      available: json['available'] == true,
      downloadUrl: json['downloadUrl']?.toString(),
      sha256: json['sha256']?.toString(),
      size: size,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'build': build,
        'channel': channel,
        'releaseDate': releaseDate?.toIso8601String(),
        'releaseNotes': releaseNotes,
        'windows': _artifactToJson(windows),
        'android': _artifactToJson(android),
      };

  static Map<String, dynamic> _artifactToJson(AppReleaseArtifact artifact) => {
        'available': artifact.available,
        if (artifact.downloadUrl != null) 'downloadUrl': artifact.downloadUrl,
        if (artifact.sha256 != null) 'sha256': artifact.sha256,
        if (artifact.size != null) 'size': artifact.size,
      };
}
