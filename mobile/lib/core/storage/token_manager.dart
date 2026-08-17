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
  bool _persistToSecureStorage = true;
  Future<void> _writeQueue = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() action) {
    final operation = _writeQueue.then((_) => action());
    _writeQueue = operation.then((_) {}, onError: (_) {});
    return operation;
  }

  Future<void> _hydrateMemoryIfNeeded() async {
    if (_memoryHydrated) {
      return;
    }
    await _serialized(() async {
      if (_memoryHydrated) {
        return;
      }
      _cachedAccessToken = await _secureStorage.read(StorageKeys.accessToken);
      _cachedRefreshToken = await _secureStorage.read(StorageKeys.refreshToken);
      _cachedExpiresAtRaw = await _secureStorage.read(StorageKeys.tokenExpiresAt);
      _memoryHydrated = true;
    });
  }

  Future<String?> getAccessToken() async {
    await _hydrateMemoryIfNeeded();
    return _cachedAccessToken;
  }

  Future<String?> getRefreshToken() async {
    await _hydrateMemoryIfNeeded();
    return _cachedRefreshToken;
  }

  /// Saves tokens in memory and, when [persist] is true, to secure storage.
  ///
  /// Writes are serialized. Windows DPAPI storage is a single JSON file; parallel
  /// writes can overwrite each other and drop the refresh token.
  ///
  /// When [persist] is omitted, the last persistence choice is reused so token
  /// refresh stays memory-only when Remember Me was disabled on Windows.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
    bool? persist,
  }) {
    return _serialized(() async {
      _cachedAccessToken = accessToken;
      _cachedRefreshToken = refreshToken;
      _memoryHydrated = true;
      final shouldPersist = persist ?? _persistToSecureStorage;
      _persistToSecureStorage = shouldPersist;

      String? expiresAt;
      if (expiresIn != null) {
        expiresAt = DateTime.now()
            .add(Duration(seconds: expiresIn))
            .millisecondsSinceEpoch
            .toString();
        _cachedExpiresAtRaw = expiresAt;
      }

      if (!shouldPersist) {
        await _deletePersistedTokens();
        return;
      }

      await _secureStorage.write(StorageKeys.accessToken, accessToken);
      await _secureStorage.write(StorageKeys.refreshToken, refreshToken);
      if (expiresAt != null) {
        await _secureStorage.write(StorageKeys.tokenExpiresAt, expiresAt);
      }
    });
  }

  Future<void> clearTokens() {
    return _serialized(() async {
      _cachedAccessToken = null;
      _cachedRefreshToken = null;
      _cachedExpiresAtRaw = null;
      _memoryHydrated = true;
      await _deletePersistedTokens();
    });
  }

  Future<void> _deletePersistedTokens() async {
    await _secureStorage.delete(StorageKeys.accessToken);
    await _secureStorage.delete(StorageKeys.refreshToken);
    await _secureStorage.delete(StorageKeys.tokenExpiresAt);
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
