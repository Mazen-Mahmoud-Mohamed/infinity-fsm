import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/services/connectivity_service.dart';
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
    this.notificationPushEnabled = true,
    this.notificationEmailEnabled = true,
    this.message,
  });

  final AppStartupStatus startupStatus;
  final bool isOnline;
  final ThemeMode themeMode;
  final String localeCode;
  final bool notificationPushEnabled;
  final bool notificationEmailEnabled;
  final String? message;

  Locale get locale => Locale(localeCode);

  AppState copyWith({
    AppStartupStatus? startupStatus,
    bool? isOnline,
    ThemeMode? themeMode,
    String? localeCode,
    bool? notificationPushEnabled,
    bool? notificationEmailEnabled,
    String? message,
  }) {
    return AppState(
      startupStatus: startupStatus ?? this.startupStatus,
      isOnline: isOnline ?? this.isOnline,
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      notificationPushEnabled:
          notificationPushEnabled ?? this.notificationPushEnabled,
      notificationEmailEnabled:
          notificationEmailEnabled ?? this.notificationEmailEnabled,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        startupStatus,
        isOnline,
        themeMode,
        localeCode,
        notificationPushEnabled,
        notificationEmailEnabled,
        message,
      ];
}

class AppCubit extends Cubit<AppState> {
  AppCubit(
    this._connectivityService,
    this._preferences,
  ) : super(const AppState()) {
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(isOnline: isOnline));
    });
  }

  static const _themeKey = 'app_theme_mode';
  static const _localeKey = 'app_locale_code';
  static const _pushKey = 'notif_push_enabled';
  static const _emailKey = 'notif_email_enabled';

  final ConnectivityService _connectivityService;
  final PreferencesService _preferences;
  StreamSubscription<bool>? _connectivitySubscription;

  Future<void> initialize() async {
    emit(state.copyWith(startupStatus: AppStartupStatus.loading));

    try {
      final isOnline = await _connectivityService.isConnected;
      final themeRaw = _preferences.getString(_themeKey);
      final themeMode = switch (themeRaw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      final localeCode = _preferences.getString(_localeKey) ?? 'en';
      final push = _preferences.getBool(_pushKey) ?? true;
      final email = _preferences.getBool(_emailKey) ?? true;

      emit(
        state.copyWith(
          startupStatus: AppStartupStatus.ready,
          isOnline: isOnline,
          themeMode: themeMode,
          localeCode: localeCode == 'ar' ? 'ar' : 'en',
          notificationPushEnabled: push,
          notificationEmailEnabled: email,
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
    emit(state.copyWith(localeCode: normalized));
  }

  Future<void> setNotificationPreferences({
    bool? pushEnabled,
    bool? emailEnabled,
  }) async {
    if (pushEnabled != null) {
      await _preferences.setBool(_pushKey, pushEnabled);
    }
    if (emailEnabled != null) {
      await _preferences.setBool(_emailKey, emailEnabled);
    }
    emit(
      state.copyWith(
        notificationPushEnabled: pushEnabled,
        notificationEmailEnabled: emailEnabled,
      ),
    );
  }

  Future<void> clearLocalCache() async {
    // UI-only Phase 1: preferences keys for offline queues are feature-owned.
    // This marks a successful "cache clear" acknowledgement for the Settings UI.
    emit(state.copyWith(message: null));
  }

  @override
  Future<void> close() {
    unawaited(_connectivitySubscription?.cancel());
    return super.close();
  }
}
