import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:mobile/core/storage/preferences_service.dart';

/// Central source of truth for background data-sync preferences.
class SyncConfiguration extends Equatable {
  const SyncConfiguration({
    this.autoSync = true,
    this.wifiOnlySync = false,
    this.intervalMinutes = SyncConfigurationService.defaultIntervalMinutes,
  });

  final bool autoSync;
  final bool wifiOnlySync;
  final int intervalMinutes;

  Duration get interval => Duration(minutes: intervalMinutes);

  SyncConfiguration copyWith({
    bool? autoSync,
    bool? wifiOnlySync,
    int? intervalMinutes,
  }) {
    return SyncConfiguration(
      autoSync: autoSync ?? this.autoSync,
      wifiOnlySync: wifiOnlySync ?? this.wifiOnlySync,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    );
  }

  @override
  List<Object?> get props => [autoSync, wifiOnlySync, intervalMinutes];
}

class SyncConfigurationService {
  SyncConfigurationService(this._preferences);

  static const defaultIntervalMinutes = 5;
  static const supportedIntervalMinutes = [5, 15, 30, 60];

  static const _autoSyncKey = 'pref_auto_sync';
  static const _wifiOnlyKey = 'pref_wifi_only_sync';
  static const _syncIntervalKey = 'pref_sync_interval_min';

  final PreferencesService _preferences;
  final _controller = StreamController<SyncConfiguration>.broadcast();

  SyncConfiguration _current = const SyncConfiguration();

  SyncConfiguration get current => _current;

  Stream<SyncConfiguration> get onChanged => _controller.stream;

  Future<void> load() async {
    final storedInterval = _preferences.getInt(_syncIntervalKey);
    _current = SyncConfiguration(
      autoSync: _preferences.getBool(_autoSyncKey) ?? true,
      wifiOnlySync: _preferences.getBool(_wifiOnlyKey) ?? false,
      intervalMinutes: _normalizeInterval(storedInterval),
    );
    _controller.add(_current);
  }

  Future<void> update({
    bool? autoSync,
    bool? wifiOnlySync,
    int? intervalMinutes,
  }) async {
    if (autoSync != null) {
      await _preferences.setBool(_autoSyncKey, autoSync);
    }
    if (wifiOnlySync != null) {
      await _preferences.setBool(_wifiOnlyKey, wifiOnlySync);
    }
    if (intervalMinutes != null) {
      await _preferences.setInt(
        _syncIntervalKey,
        _normalizeInterval(intervalMinutes),
      );
    }

    _current = _current.copyWith(
      autoSync: autoSync,
      wifiOnlySync: wifiOnlySync,
      intervalMinutes:
          intervalMinutes == null ? null : _normalizeInterval(intervalMinutes),
    );
    _controller.add(_current);
  }

  int _normalizeInterval(int? minutes) {
    if (minutes == null) {
      return defaultIntervalMinutes;
    }
    if (supportedIntervalMinutes.contains(minutes)) {
      return minutes;
    }
    return defaultIntervalMinutes;
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
