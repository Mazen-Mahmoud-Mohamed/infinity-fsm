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
  static const _downloadedBuildKey = 'app_update_downloaded_build_v1';
  static const _lastNotifiedVersionKey = 'app_update_last_notified_version_v1';
  static const _lastAutoCheckKey = 'app_update_last_auto_check_at_v1';
  static const _dismissedBannerVersionKey = 'app_update_dismissed_banner_v1';
  static const _autoUpdateEnabledKey = 'app_update_auto_enabled_v1';
  static const _autoUpdateProcessingVersionKey =
      'app_update_auto_processing_version_v1';
  static const _autoUpdateFailedLockKey = 'app_update_auto_failed_lock_v1';
  static const _autoUpdateFailedAtKey = 'app_update_auto_failed_at_v1';
  static const _autoUpdateInstallAttemptedLockKey =
      'app_update_auto_install_lock_v1';

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

  DateTime? readLastAutoCheckAt() {
    final raw = _preferences.getString(_lastAutoCheckKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeLastAutoCheckAt(DateTime value) async {
    await _preferences.setString(_lastAutoCheckKey, value.toIso8601String());
  }

  String? readLastNotifiedUpdateVersion() =>
      _preferences.getString(_lastNotifiedVersionKey);

  Future<void> writeLastNotifiedUpdateVersion(String version) async {
    await _preferences.setString(_lastNotifiedVersionKey, version);
  }

  String? readDismissedBannerVersion() =>
      _preferences.getString(_dismissedBannerVersionKey);

  Future<void> writeDismissedBannerVersion(String version) async {
    await _preferences.setString(_dismissedBannerVersionKey, version);
  }

  String? readDownloadedPath() => _preferences.getString(_downloadedPathKey);

  String? readDownloadedVersion() =>
      _preferences.getString(_downloadedVersionKey);

  int? readDownloadedBuild() {
    final raw = _preferences.getString(_downloadedBuildKey);
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Future<void> writeDownloadedArtifact({
    required String path,
    required String version,
    required int build,
  }) async {
    await _preferences.setString(_downloadedPathKey, path);
    await _preferences.setString(_downloadedVersionKey, version);
    await _preferences.setString(_downloadedBuildKey, build.toString());
  }

  Future<void> clearDownloadedArtifact() async {
    await _preferences.remove(_downloadedPathKey);
    await _preferences.remove(_downloadedVersionKey);
    await _preferences.remove(_downloadedBuildKey);
  }

  bool readAutoUpdateEnabled() =>
      _preferences.getBool(_autoUpdateEnabledKey) ?? false;

  Future<void> writeAutoUpdateEnabled(bool enabled) async {
    await _preferences.setBool(_autoUpdateEnabledKey, enabled);
  }

  String? readAutoUpdateProcessingVersion() =>
      _preferences.getString(_autoUpdateProcessingVersionKey);

  Future<void> writeAutoUpdateProcessingVersion(String version) async {
    await _preferences.setString(_autoUpdateProcessingVersionKey, version);
  }

  Future<void> clearAutoUpdateProcessingVersion() async {
    await _preferences.remove(_autoUpdateProcessingVersionKey);
  }

  String? readAutoUpdateFailedLock() =>
      _preferences.getString(_autoUpdateFailedLockKey);

  Future<void> writeAutoUpdateFailedLock(String lock) async {
    await _preferences.setString(_autoUpdateFailedLockKey, lock);
  }

  DateTime? readAutoUpdateFailedAt() {
    final raw = _preferences.getString(_autoUpdateFailedAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeAutoUpdateFailedAt(DateTime value) async {
    await _preferences.setString(_autoUpdateFailedAtKey, value.toIso8601String());
  }

  String? readAutoUpdateInstallAttemptedLock() =>
      _preferences.getString(_autoUpdateInstallAttemptedLockKey);

  Future<void> writeAutoUpdateInstallAttemptedLock(String lock) async {
    await _preferences.setString(_autoUpdateInstallAttemptedLockKey, lock);
  }

  Future<void> clearAutoUpdateInstallAttemptedLock() async {
    await _preferences.remove(_autoUpdateInstallAttemptedLockKey);
  }
}
