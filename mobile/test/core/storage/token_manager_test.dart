import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/core/storage/token_manager.dart';

void main() {
  late SecureStorageService storage;
  late TokenManager manager;

  setUp(() {
    storage = SecureStorageService.inMemory();
    manager = TokenManager(storage);
  });

  test('saveTokens persists both access and refresh tokens', () async {
    await manager.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      expiresIn: 3600,
    );

    expect(await manager.getAccessToken(), 'access-1');
    expect(await manager.getRefreshToken(), 'refresh-1');
    expect(await storage.read(StorageKeys.accessToken), 'access-1');
    expect(await storage.read(StorageKeys.refreshToken), 'refresh-1');
    expect(await manager.hasValidSession(), isTrue);
  });

  test('persist:false keeps tokens in memory and clears disk', () async {
    await manager.saveTokens(
      accessToken: 'access-old',
      refreshToken: 'refresh-old',
      persist: true,
    );

    await manager.saveTokens(
      accessToken: 'access-mem',
      refreshToken: 'refresh-mem',
      persist: false,
    );

    expect(await manager.getAccessToken(), 'access-mem');
    expect(await manager.getRefreshToken(), 'refresh-mem');
    expect(await storage.read(StorageKeys.accessToken), isNull);
    expect(await storage.read(StorageKeys.refreshToken), isNull);
    expect(await manager.hasValidSession(), isTrue);
  });

  test('refresh without persist argument reuses the last persistence choice',
      () async {
    await manager.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      persist: false,
    );

    await manager.saveTokens(
      accessToken: 'access-2',
      refreshToken: 'refresh-2',
    );

    expect(await manager.getRefreshToken(), 'refresh-2');
    expect(await storage.read(StorageKeys.refreshToken), isNull);
  });

  test('clearTokens removes memory and persisted values', () async {
    await manager.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );
    await manager.clearTokens();

    expect(await manager.getAccessToken(), isNull);
    expect(await manager.getRefreshToken(), isNull);
    expect(await storage.read(StorageKeys.accessToken), isNull);
    expect(await storage.read(StorageKeys.refreshToken), isNull);
    expect(await manager.hasValidSession(), isFalse);
  });

  test('serialized writes keep access and refresh tokens paired', () async {
    await Future.wait([
      for (var i = 0; i < 12; i++)
        manager.saveTokens(
          accessToken: 'access-$i',
          refreshToken: 'refresh-$i',
        ),
    ]);

    final access = await storage.read(StorageKeys.accessToken);
    final refresh = await storage.read(StorageKeys.refreshToken);
    expect(access, isNotNull);
    expect(refresh, isNotNull);
    expect(refresh, 'refresh-${access!.split('-').last}');
  });

  test('password is never written as a storage key', () async {
    await manager.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );

    expect(await storage.read('password'), isNull);
    expect(await storage.read(StorageKeys.accessToken), isNot(contains('password')));
  });
}
