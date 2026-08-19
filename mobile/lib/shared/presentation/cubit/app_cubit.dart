import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/connectivity_status.dart';
import 'package:mobile/core/services/sync_configuration_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';

enum AppStartupStatus {
  initial,
  loading,
  ready,
  failure,
}

class AppState extends Equatable {
  const AppState({
    this.startupStatus = AppStartupStatus.initial,
    this.isOnline = true,
    this.themeMode = ThemeMode.system,
    this.localeCode = 'en',
    this.localePreference = 'system',
    this.notificationPushEnabled = true,
    this.notificationEmailEnabled = true,
    this.notifAttendance = true,
    this.notifTasks = true,
    this.notifOvertime = true,
    this.notifSync = true,
    this.notifUpdates = true,
    this.autoSync = true,
    this.wifiOnlySync = false,
    this.syncIntervalMinutes = SyncConfigurationService.defaultIntervalMinutes,
    this.connectivity = ConnectivitySnapshot.unknown,
    this.largeText = false,
    this.reduceAnimations = false,
    this.highContrast = false,
    this.releaseChannel = 'stable',
    this.message,
  });

  final AppStartupStatus startupStatus;
  final bool isOnline;
  final ThemeMode themeMode;
  final String localeCode;
  final String localePreference;
  final bool notificationPushEnabled;
  final bool notificationEmailEnabled;
  final bool notifAttendance;
  final bool notifTasks;
  final bool notifOvertime;
  final bool notifSync;
  final bool notifUpdates;
  final bool autoSync;
  final bool wifiOnlySync;
  final int syncIntervalMinutes;
  final ConnectivitySnapshot connectivity;
  final bool largeText;
  final bool reduceAnimations;
  final bool highContrast;
  final String releaseChannel;
  final String? message;

  Locale get locale => Locale(localeCode);

  AppState copyWith({
    AppStartupStatus? startupStatus,
    bool? isOnline,
    ThemeMode? themeMode,
    String? localeCode,
    String? localePreference,
    bool? notificationPushEnabled,
    bool? notificationEmailEnabled,
    bool? notifAttendance,
    bool? notifTasks,
    bool? notifOvertime,
    bool? notifSync,
    bool? notifUpdates,
    bool? autoSync,
    bool? wifiOnlySync,
    int? syncIntervalMinutes,
    ConnectivitySnapshot? connectivity,
    bool? largeText,
    bool? reduceAnimations,
    bool? highContrast,
    String? releaseChannel,
    String? message,
    bool clearMessage = false,
  }) {
    return AppState(
      startupStatus: startupStatus ?? this.startupStatus,
      isOnline: isOnline ?? this.isOnline,
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      localePreference: localePreference ?? this.localePreference,
      notificationPushEnabled:
          notificationPushEnabled ?? this.notificationPushEnabled,
      notificationEmailEnabled:
          notificationEmailEnabled ?? this.notificationEmailEnabled,
      notifAttendance: notifAttendance ?? this.notifAttendance,
      notifTasks: notifTasks ?? this.notifTasks,
      notifOvertime: notifOvertime ?? this.notifOvertime,
      notifSync: notifSync ?? this.notifSync,
      notifUpdates: notifUpdates ?? this.notifUpdates,
      autoSync: autoSync ?? this.autoSync,
      wifiOnlySync: wifiOnlySync ?? this.wifiOnlySync,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      connectivity: connectivity ?? this.connectivity,
      largeText: largeText ?? this.largeText,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      highContrast: highContrast ?? this.highContrast,
      releaseChannel: releaseChannel ?? this.releaseChannel,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        startupStatus,
        isOnline,
        themeMode,
        localeCode,
        localePreference,
        notificationPushEnabled,
        notificationEmailEnabled,
        notifAttendance,
        notifTasks,
        notifOvertime,
        notifSync,
        notifUpdates,
        autoSync,
        wifiOnlySync,
        syncIntervalMinutes,
        connectivity,
        largeText,
        reduceAnimations,
        highContrast,
        releaseChannel,
        message,
      ];
}

class AppCubit extends Cubit<AppState> {
  AppCubit(
    this._connectivityService,
    this._preferences,
    this._syncConfiguration,
  ) : super(const AppState()) {
    _connectivitySubscription =
        _connectivityService.onStatusChanged.listen((snapshot) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          connectivity: snapshot,
          isOnline: snapshot.canSync,
        ),
      );
    });

    _syncConfigSubscription = _syncConfiguration.onChanged.listen((config) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          autoSync: config.autoSync,
          wifiOnlySync: config.wifiOnlySync,
          syncIntervalMinutes: config.intervalMinutes,
        ),
      );
    });
  }

  static const _themeKey = 'app_theme_mode';
  static const _localeKey = 'app_locale_code';

  /// Maps stored preference to the raw preference value exposed in [AppState].
  static String normalizeLocalePreference(String? stored) {
    return switch (stored) {
      'ar' => 'ar',
      'en' => 'en',
      'system' => 'system',
      _ => 'system',
    };
  }

  /// Resolves the effective display locale from stored preference + device locales.
  static String resolveLocaleCode(String? stored) {
    if (stored == 'ar') return 'ar';
    if (stored == 'en') return 'en';

    final deviceLocales =
        WidgetsBinding.instance.platformDispatcher.locales;
    for (final locale in deviceLocales) {
      if (locale.languageCode == 'ar') return 'ar';
      if (locale.languageCode == 'en') return 'en';
    }
    return 'en';
  }

  static const _pushKey = 'notif_push_enabled';
  static const _emailKey = 'notif_email_enabled';
  static const _notifAttendanceKey = 'notif_attendance';
  static const _notifTasksKey = 'notif_tasks';
  static const _notifOvertimeKey = 'notif_overtime';
  static const _notifSyncKey = 'notif_sync';
  static const _notifUpdatesKey = 'notif_updates';
  static const _largeTextKey = 'pref_large_text';
  static const _reduceAnimKey = 'pref_reduce_animations';
  static const _highContrastKey = 'pref_high_contrast';
  static const _channelKey = 'pref_release_channel';

  final ConnectivityService _connectivityService;
  final PreferencesService _preferences;
  final SyncConfigurationService _syncConfiguration;
  StreamSubscription<ConnectivitySnapshot>? _connectivitySubscription;
  StreamSubscription<SyncConfiguration>? _syncConfigSubscription;

  Future<void> initialize() async {
    emit(state.copyWith(startupStatus: AppStartupStatus.loading));

    try {
      final connectivity =
          await _connectivityService.refreshStatus(reason: 'app_init');
      final syncConfig = _syncConfiguration.current;
      final themeRaw = _preferences.getString(_themeKey);
      final themeMode = switch (themeRaw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      final storedLocale = _preferences.getString(_localeKey);
      final localePreference = normalizeLocalePreference(storedLocale);
      final localeCode = resolveLocaleCode(storedLocale);

      emit(
        state.copyWith(
          startupStatus: AppStartupStatus.ready,
          isOnline: connectivity.canSync,
          connectivity: connectivity,
          themeMode: themeMode,
          localeCode: localeCode,
          localePreference: localePreference,
          notificationPushEnabled: _preferences.getBool(_pushKey) ?? true,
          notificationEmailEnabled: _preferences.getBool(_emailKey) ?? true,
          notifAttendance: _preferences.getBool(_notifAttendanceKey) ?? true,
          notifTasks: _preferences.getBool(_notifTasksKey) ?? true,
          notifOvertime: _preferences.getBool(_notifOvertimeKey) ?? true,
          notifSync: _preferences.getBool(_notifSyncKey) ?? true,
          notifUpdates: _preferences.getBool(_notifUpdatesKey) ?? true,
          autoSync: syncConfig.autoSync,
          wifiOnlySync: syncConfig.wifiOnlySync,
          syncIntervalMinutes: syncConfig.intervalMinutes,
          largeText: _preferences.getBool(_largeTextKey) ?? false,
          reduceAnimations: _preferences.getBool(_reduceAnimKey) ?? false,
          highContrast: _preferences.getBool(_highContrastKey) ?? false,
          releaseChannel: _preferences.getString(_channelKey) ?? 'stable',
        ),
      );
    } on Object catch (error) {
      emit(
        state.copyWith(
          startupStatus: AppStartupStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _preferences.setString(_themeKey, value);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setLocaleCode(String code) async {
    final normalized = code == 'ar' ? 'ar' : 'en';
    await _preferences.setString(_localeKey, normalized);
    emit(
      state.copyWith(
        localeCode: normalized,
        localePreference: normalized,
      ),
    );
  }

  Future<void> setLocaleToSystem() async {
    await _preferences.setString(_localeKey, 'system');
    final resolved = resolveLocaleCode('system');
    emit(
      state.copyWith(
        localeCode: resolved,
        localePreference: 'system',
      ),
    );
  }

  Future<void> setNotificationPreferences({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? attendance,
    bool? tasks,
    bool? overtime,
    bool? sync,
    bool? updates,
  }) async {
    if (pushEnabled != null) {
      await _preferences.setBool(_pushKey, pushEnabled);
    }
    if (emailEnabled != null) {
      await _preferences.setBool(_emailKey, emailEnabled);
    }
    if (attendance != null) {
      await _preferences.setBool(_notifAttendanceKey, attendance);
    }
    if (tasks != null) {
      await _preferences.setBool(_notifTasksKey, tasks);
    }
    if (overtime != null) {
      await _preferences.setBool(_notifOvertimeKey, overtime);
    }
    if (sync != null) {
      await _preferences.setBool(_notifSyncKey, sync);
    }
    if (updates != null) {
      await _preferences.setBool(_notifUpdatesKey, updates);
    }
    emit(
      state.copyWith(
        notificationPushEnabled: pushEnabled,
        notificationEmailEnabled: emailEnabled,
        notifAttendance: attendance,
        notifTasks: tasks,
        notifOvertime: overtime,
        notifSync: sync,
        notifUpdates: updates,
      ),
    );
  }

  Future<void> setSyncPreferences({
    bool? autoSync,
    bool? wifiOnly,
    int? intervalMinutes,
  }) async {
    await _syncConfiguration.update(
      autoSync: autoSync,
      wifiOnlySync: wifiOnly,
      intervalMinutes: intervalMinutes,
    );
  }

  Future<void> setAccessibilityPreferences({
    bool? largeText,
    bool? reduceAnimations,
    bool? highContrast,
  }) async {
    if (largeText != null) {
      await _preferences.setBool(_largeTextKey, largeText);
    }
    if (reduceAnimations != null) {
      await _preferences.setBool(_reduceAnimKey, reduceAnimations);
    }
    if (highContrast != null) {
      await _preferences.setBool(_highContrastKey, highContrast);
    }
    emit(
      state.copyWith(
        largeText: largeText,
        reduceAnimations: reduceAnimations,
        highContrast: highContrast,
      ),
    );
  }

  /// Clears Flutter image cache only — never deletes user/business data.
  Future<void> clearLocalCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    emit(state.copyWith(clearMessage: true));
  }

  /// Restores preference defaults (theme/locale/notifications/sync/a11y).
  Future<void> restoreDefaultPreferences() async {
    await setThemeMode(ThemeMode.system);
    await setLocaleToSystem();
    await setNotificationPreferences(
      pushEnabled: true,
      emailEnabled: true,
      attendance: true,
      tasks: true,
      overtime: true,
      sync: true,
      updates: true,
    );
    await setSyncPreferences(
      autoSync: true,
      wifiOnly: false,
      intervalMinutes: SyncConfigurationService.defaultIntervalMinutes,
    );
    await setAccessibilityPreferences(
      largeText: false,
      reduceAnimations: false,
      highContrast: false,
    );
  }

  @override
  Future<void> close() {
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_syncConfigSubscription?.cancel());
    return super.close();
  }
}
