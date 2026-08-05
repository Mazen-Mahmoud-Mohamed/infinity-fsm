import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/features/auth/data/dto/login_request_dto.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required ConnectivityService connectivityService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _connectivityService = connectivityService;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  bool _isConnectivityFailure(String? code) {
    return code == 'OFFLINE' ||
        code == 'TIMEOUT' ||
        code == 'NETWORK_ERROR';
  }

  @override
  Future<Result<bool>> hasSession() async {
    try {
      final hasSession = await _localDataSource.hasSession();
      return Success(hasSession);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<CurrentUser>> login(LoginParams params) async {
    try {
      final response = await _remoteDataSource.login(
        LoginRequestDto(
          email: params.email.trim(),
          password: params.password,
          deviceId: params.deviceId,
          deviceInfo: params.deviceInfo,
        ),
      );

      await _localDataSource.saveTokens(
        accessToken: response.tokens.accessToken,
        refreshToken: response.tokens.refreshToken,
        expiresIn: response.tokens.expiresIn,
      );

      await _localDataSource.saveRememberMe(
        rememberMe: params.rememberMe,
        email: params.email.trim(),
      );

      final user = await _remoteDataSource.getCurrentUser();
      await _localDataSource.saveCachedUser(user);
      return Success(user);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<CurrentUser>> restoreSession() async {
    try {
      final hasSession = await _localDataSource.hasSession();
      if (!hasSession) {
        return const Failure('authNoActiveSession', code: 'NO_SESSION');
      }

      final cachedUser = _localDataSource.readCachedUser();
      final tokenExpired = await _localDataSource.isAccessTokenExpired();

      // Refresh token must be decided by the actual API request, not by
      // InternetConnectionChecker false-negatives.
      if (tokenExpired) {
        final refreshResult = await refreshTokens();
        if (refreshResult is Failure) {
          if (_isConnectivityFailure(refreshResult.code) &&
              cachedUser != null) {
            return Success(cachedUser);
          }
          await _localDataSource.clearSession();
          return Failure(
            refreshResult.message,
            code: refreshResult.code,
          );
        }
      }

      final isOnline = await _connectivityService.isConnected;
      // If token is still valid and connectivity is likely offline, we can
      // open from cache as an optimization.
      if (!tokenExpired && !isOnline) {
        if (cachedUser != null) {
          return Success(cachedUser);
        }
        return const Failure(
          'authOfflineRestoreProfile',
          code: 'OFFLINE',
        );
      }

      final user = await _remoteDataSource.getCurrentUser();
      await _localDataSource.saveCachedUser(user);
      return Success(user);
    } on Object catch (error) {
      final failure = NetworkErrorMapper.map<CurrentUser>(error);
      final cachedUser = _localDataSource.readCachedUser();
      if (_isConnectivityFailure(failure.code) && cachedUser != null) {
        return Success(cachedUser);
      }
      if (failure.code == 'UNAUTHORIZED' || failure.code == 'SESSION_EXPIRED') {
        await _localDataSource.clearSession();
      }
      return failure;
    }
  }

  @override
  Future<Result<CurrentUser>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      await _localDataSource.saveCachedUser(user);
      return Success(user);
    } on Object catch (error) {
      final failure = NetworkErrorMapper.map<CurrentUser>(error);
      final cachedUser = _localDataSource.readCachedUser();
      if (_isConnectivityFailure(failure.code) && cachedUser != null) {
        return Success(cachedUser);
      }
      return failure;
    }
  }

  @override
  Future<Result<void>> refreshTokens() async {
    try {
      final refreshToken = await _localDataSource.getRefreshToken();
      final deviceId = await _localDataSource.getDeviceId();

      if (refreshToken == null || deviceId == null) {
        return const Failure('sessionExpired', code: 'SESSION_EXPIRED');
      }

      final tokens = await _remoteDataSource.refresh(
        refreshToken: refreshToken,
        deviceId: deviceId,
      );

      await _localDataSource.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresIn: tokens.expiresIn,
      );

      return const Success(null);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final refreshToken = await _localDataSource.getRefreshToken();
      final deviceId = await _localDataSource.getDeviceId();

      if (refreshToken != null && deviceId != null) {
        if (await _connectivityService.isConnected) {
          await _remoteDataSource.logout(
            refreshToken: refreshToken,
            deviceId: deviceId,
          );
        }
      }

      await _localDataSource.clearSession();
      return const Success(null);
    } on Object catch (error) {
      await _localDataSource.clearSession();
      return NetworkErrorMapper.map(error);
    }
  }
}
