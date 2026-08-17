import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? storage,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              wOptions: WindowsOptions(),
            ),
        _memory = null;

  @visibleForTesting
  SecureStorageService.inMemory()
      : _storage = null,
        _memory = <String, String>{};

  final FlutterSecureStorage? _storage;
  final Map<String, String>? _memory;

  Future<void> write(String key, String value) async {
    final memory = _memory;
    if (memory != null) {
      memory[key] = value;
      return;
    }
    await _storage!.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    final memory = _memory;
    if (memory != null) {
      return memory[key];
    }
    return _storage!.read(key: key);
  }

  Future<void> delete(String key) async {
    final memory = _memory;
    if (memory != null) {
      memory.remove(key);
      return;
    }
    await _storage!.delete(key: key);
  }

  Future<void> deleteAll() async {
    final memory = _memory;
    if (memory != null) {
      memory.clear();
      return;
    }
    await _storage!.deleteAll();
  }
}
