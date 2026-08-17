import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/core/storage/token_manager.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/features/auth/data/dto/auth_tokens_dto.dart';
import 'package:mobile/features/auth/data/dto/login_request_dto.dart';
import 'package:mobile/features/auth/data/dto/login_response_dto.dart';
import 'package:mobile/features/auth/data/models/current_user_model.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemote extends Fake implements AuthRemoteDataSource {
  AuthTokensDto tokens = const AuthTokensDto(
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    expiresIn: 3600,
  );

  Object? refreshError;
  int refreshCalls = 0;

  static const user = CurrentUserModel(
    id: 'u1',
    companyId: 'c1',
    email: 'admin@example.com',
    firstName: 'Admin',
    lastName: 'User',
    fullName: 'Admin User',
    roles: ['ADMIN'],
    permissions: [],
  );

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    return LoginResponseDto(tokens: tokens, user: user);
  }

  @override
  Future<CurrentUserModel> getCurrentUser() async => user;

  @override
  Future<void> logout({
    required String refreshToken,
    required String deviceId,
  }) async {}

  @override
  Future<AuthTokensDto> refresh({
    required String refreshToken,
    required String deviceId,
  }) async {
    refreshCalls += 1;
    final error = refreshError;
    if (error != null) {
      throw error;
    }
    return AuthTokensDto(
      accessToken: 'access-2',
      refreshToken: 'refresh-2',
      expiresIn: 3600,
    );
  }
}

class _OnlineConnectivity extends Fake implements ConnectivityService {
  @override
  Future<bool> get isConnected async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRemote remote;
  late AuthLocalDataSource local;
  late SecureStorageService storage;
  late AuthRepositoryImpl repository;

  Future<void> setUpRepo({
    required bool Function({required bool rememberMe}) persistPolicy,
    required bool Function() requireRememberMe,
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.deviceId: 'device-1',
      ...prefs,
    });
    final preferences = PreferencesService(await SharedPreferences.getInstance());
    storage = SecureStorageService.inMemory();
    local = AuthLocalDataSource(
      tokenManager: TokenManager(storage),
      preferencesService: preferences,
    );
    remote = _FakeRemote();
    repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      connectivityService: _OnlineConnectivity(),
      shouldPersistTokens: persistPolicy,
      requiresRememberMeToRestore: requireRememberMe,
    );
  }

  test('Remember Me ON persists refresh token and never stores the password',
      () async {
    await setUpRepo(
      persistPolicy: ({required rememberMe}) => rememberMe,
      requireRememberMe: () => true,
    );

    final result = await repository.login(
      const LoginParams(
        email: 'admin@example.com',
        password: 'super-secret-password',
        rememberMe: true,
        deviceId: 'device-1',
        deviceInfo: {'platform': 'windows'},
      ),
    );

    expect(result, isA<Success>());
    expect(await storage.read(StorageKeys.refreshToken), 'refresh-1');
    expect(await storage.read(StorageKeys.accessToken), 'access-1');
    expect(local.getRememberedEmail(), 'admin@example.com');
    expect(local.getRememberMe(), isTrue);
    expect(await storage.read('password'), isNull);
    expect(
      await storage.read(StorageKeys.refreshToken),
      isNot('super-secret-password'),
    );

    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      expect(prefs.get(key)?.toString(), isNot('super-secret-password'));
    }
  });

  test('Remember Me OFF keeps a live session but does not persist tokens',
      () async {
    await setUpRepo(
      persistPolicy: ({required rememberMe}) => rememberMe,
      requireRememberMe: () => true,
    );

    await repository.login(
      const LoginParams(
        email: 'admin@example.com',
        password: 'super-secret-password',
        rememberMe: false,
        deviceId: 'device-1',
        deviceInfo: {'platform': 'windows'},
      ),
    );

    expect(await local.getRefreshToken(), 'refresh-1');
    expect(await storage.read(StorageKeys.refreshToken), isNull);
    expect(local.getRememberMe(), isFalse);

    final restarted = TokenManager(storage);
    expect(await restarted.hasValidSession(), isFalse);
  });

  test('Windows restore without Remember Me clears leftover tokens', () async {
    await setUpRepo(
      persistPolicy: ({required rememberMe}) => true,
      requireRememberMe: () => true,
    );
    await local.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );

    final restored = await repository.restoreSession();

    expect(restored, isA<Failure>());
    expect((restored as Failure).code, 'NO_SESSION');
    expect(await storage.read(StorageKeys.refreshToken), isNull);
  });

  test('Remember Me ON restores the persisted session', () async {
    await setUpRepo(
      persistPolicy: ({required rememberMe}) => rememberMe,
      requireRememberMe: () => true,
      prefs: {StorageKeys.rememberMe: true},
    );
    await local.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );

    final restored = await repository.restoreSession();

    expect(restored, isA<Success>());
    expect((restored as Success).data.email, 'admin@example.com');
  });

  test('expired access token is refreshed from the persisted refresh token',
      () async {
    await setUpRepo(
      persistPolicy: ({required rememberMe}) => true,
      requireRememberMe: () => true,
      prefs: {StorageKeys.rememberMe: true},
    );
    await local.saveTokens(
      accessToken: 'eyJhbGciOiJub25lIn0.eyJleHAiOjF9.sig',
      refreshToken: 'refresh-1',
    );

    final restored = await repository.restoreSession();

    expect(restored, isA<Success>());
    expect(remote.refreshCalls, 1);
    expect(await storage.read(StorageKeys.refreshToken), 'refresh-2');
    expect(await storage.read(StorageKeys.accessToken), 'access-2');
  });

  test('invalid refresh token clears the persisted session', () async {
    await setUpRepo(
      persistPolicy: ({required rememberMe}) => true,
      requireRememberMe: () => true,
      prefs: {StorageKeys.rememberMe: true},
    );
    await local.saveTokens(
      accessToken: 'eyJhbGciOiJub25lIn0.eyJleHAiOjF9.sig',
      refreshToken: 'revoked-refresh',
    );
    remote.refreshError = ApiException(
      message: 'sessionExpired',
      statusCode: 401,
      code: 'UNAUTHORIZED',
    );

    final restored = await repository.restoreSession();

    expect(restored, isA<Failure>());
    expect(await storage.read(StorageKeys.refreshToken), isNull);
    expect(await local.hasSession(), isFalse);
  });

  test('logout clears persisted tokens so the next launch is signed out',
      () async {
    await setUpRepo(
      persistPolicy: ({required rememberMe}) => true,
      requireRememberMe: () => true,
      prefs: {StorageKeys.rememberMe: true},
    );
    await repository.login(
      const LoginParams(
        email: 'admin@example.com',
        password: 'super-secret-password',
        rememberMe: true,
        deviceId: 'device-1',
        deviceInfo: {'platform': 'windows'},
      ),
    );

    await repository.logout();

    expect(await storage.read(StorageKeys.refreshToken), isNull);
    expect(await local.hasSession(), isFalse);
  });
}
