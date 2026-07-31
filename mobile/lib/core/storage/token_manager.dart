import 'dart:convert';

import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

class TokenManager {
  TokenManager(this._secureStorage);

  final SecureStorageService _secureStorage;

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedExpiresAtRaw;
  bool _memoryHydrated = false;

  Future<void> _hydrateMemoryIfNeeded() async {
    if (_memoryHydrated) {
      return;
    }
    final results = await Future.wait([
      _secureStorage.read(StorageKeys.accessToken),
      _secureStorage.read(StorageKeys.refreshToken),
      _secureStorage.read(StorageKeys.tokenExpiresAt),
    ]);
    _cachedAccessToken = results[0];
    _cachedRefreshToken = results[1];
    _cachedExpiresAtRaw = results[2];
    _memoryHydrated = true;
  }

  Future<String?> getAccessToken() async {
    await _hydrateMemoryIfNeeded();
    return _cachedAccessToken;
  }

  Future<String?> getRefreshToken() async {
    await _hydrateMemoryIfNeeded();
    return _cachedRefreshToken;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    _memoryHydrated = true;

    String? expiresAt;
    if (expiresIn != null) {
      expiresAt = DateTime.now()
          .add(Duration(seconds: expiresIn))
          .millisecondsSinceEpoch
          .toString();
      _cachedExpiresAtRaw = expiresAt;
    }

    await Future.wait([
      _secureStorage.write(StorageKeys.accessToken, accessToken),
      _secureStorage.write(StorageKeys.refreshToken, refreshToken),
      if (expiresAt != null)
        _secureStorage.write(StorageKeys.tokenExpiresAt, expiresAt),
    ]);
  }

  Future<void> clearTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedExpiresAtRaw = null;
    _memoryHydrated = true;
    await Future.wait([
      _secureStorage.delete(StorageKeys.accessToken),
      _secureStorage.delete(StorageKeys.refreshToken),
      _secureStorage.delete(StorageKeys.tokenExpiresAt),
    ]);
  }

  Future<bool> hasValidSession() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  Future<bool> isAccessTokenExpired() async {
    final accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return true;
    }

    final expiry = _readJwtExpiry(accessToken);
    if (expiry != null) {
      return DateTime.now().isAfter(
        expiry.subtract(const Duration(seconds: 30)),
      );
    }

    await _hydrateMemoryIfNeeded();
    final expiresAtRaw = _cachedExpiresAtRaw;
    if (expiresAtRaw == null) {
      return false;
    }

    final expiresAtMs = int.tryParse(expiresAtRaw);
    if (expiresAtMs == null) {
      return false;
    }

    return DateTime.now().millisecondsSinceEpoch >= expiresAtMs;
  }

  DateTime? _readJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final normalized = base64Url.normalize(parts[1]);
      final payload = json.decode(utf8.decode(base64Url.decode(normalized)));
      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final exp = payload['exp'];
      if (exp is! num) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    } on Object {
      return null;
    }
  }
}
