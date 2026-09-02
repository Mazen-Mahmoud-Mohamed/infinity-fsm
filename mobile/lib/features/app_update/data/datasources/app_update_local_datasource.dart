import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/app_update/data/models/app_release_manifest_model.dart';

class AppUpdateLocalDataSource {
  AppUpdateLocalDataSource(this._preferences);

  final PreferencesService _preferences;

  static const _releaseKey = 'app_update_cached_release_v1';
  static const _lastCheckedKey = 'app_update_last_checked_at_v1';
  static const _downloadedPathKey = 'app_update_downloaded_path_v1';
  static const _downloadedVersionKey = 'app_update_downloaded_version_v1';

  AppReleaseManifestModel? readCachedRelease() {
    final raw = _preferences.getString(_releaseKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppReleaseManifestModel.fromJson(json);
    } on Object {
      return null;
    }
  }

  Future<void> writeCachedRelease(AppReleaseManifestModel manifest) async {
    await _preferences.setString(_releaseKey, jsonEncode(manifest.toJson()));
  }

  DateTime? readLastCheckedAt() {
    final raw = _preferences.getString(_lastCheckedKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeLastCheckedAt(DateTime value) async {
    await _preferences.setString(_lastCheckedKey, value.toIso8601String());
  }

  String? readDownloadedPath() => _preferences.getString(_downloadedPathKey);

  String? readDownloadedVersion() =>
      _preferences.getString(_downloadedVersionKey);

  Future<void> writeDownloadedArtifact({
    required String path,
    required String version,
  }) async {
    await _preferences.setString(_downloadedPathKey, path);
    await _preferences.setString(_downloadedVersionKey, version);
  }

  Future<void> clearDownloadedArtifact() async {
    await _preferences.remove(_downloadedPathKey);
    await _preferences.remove(_downloadedVersionKey);
  }
}
