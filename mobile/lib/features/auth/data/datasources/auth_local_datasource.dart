import 'dart:convert';

import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/storage/token_manager.dart';
import 'package:mobile/features/auth/data/models/current_user_model.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';

class AuthLocalDataSource {
  AuthLocalDataSource({
    required this._tokenManager,
    required this._preferencesService,
  });

  final TokenManager _tokenManager;
  final PreferencesService _preferencesService;

  Future<bool> hasSession() => _tokenManager.hasValidSession();

  Future<bool> isAccessTokenExpired() => _tokenManager.isAccessTokenExpired();

  Future<String?> getDeviceId() =>
      Future.value(_preferencesService.getString(StorageKeys.deviceId));

  Future<String?> getRefreshToken() => _tokenManager.getRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
  }) {
    return _tokenManager.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
    );
  }

  Future<void> saveCachedUser(CurrentUser user) {
    final model = user is CurrentUserModel
        ? user
        : CurrentUserModel.fromEntity(user);
    return _preferencesService.setString(
      StorageKeys.currentUser,
      jsonEncode(model.toJson()),
    );
  }

  CurrentUserModel? readCachedUser() {
    final raw = _preferencesService.getString(StorageKeys.currentUser);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return CurrentUserModel.fromJson(decoded);
    } on Object {
      return null;
    }
  }

  Future<void> clearCachedUser() {
    return _preferencesService.remove(StorageKeys.currentUser);
  }

  Future<void> clearSession() async {
    await _tokenManager.clearTokens();
    await clearCachedUser();
  }

  String? getRememberedEmail() =>
      _preferencesService.getString(StorageKeys.rememberedEmail);

  bool getRememberMe() =>
      _preferencesService.getBool(StorageKeys.rememberMe) ?? false;

  Future<void> saveRememberMe({
    required bool rememberMe,
    required String email,
  }) async {
    await _preferencesService.setBool(StorageKeys.rememberMe, rememberMe);
    if (rememberMe) {
      await _preferencesService.setString(StorageKeys.rememberedEmail, email);
    } else {
      await _preferencesService.remove(StorageKeys.rememberedEmail);
    }
  }
}
