import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/services/logger_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/storage/token_manager.dart';

class RefreshTokenInterceptor extends QueuedInterceptor {
  RefreshTokenInterceptor({
    required this._dio,
    required this._tokenManager,
    required this._preferencesService,
    required this._logger,
    required this._authSessionService,
  });

  final Dio _dio;
  final TokenManager _tokenManager;
  final PreferencesService _preferencesService;
  final LoggerService _logger;
  final AuthSessionService _authSessionService;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final path = err.requestOptions.path;
    if (path.contains(ApiConstants.authLogin) ||
        path.contains(ApiConstants.authRefresh)) {
      return handler.next(err);
    }

    try {
      final refreshed = await _refreshToken();
      if (!refreshed) {
        await _handleSessionExpired();
        return handler.next(err);
      }

      final accessToken = await _tokenManager.getAccessToken();
      final requestOptions = err.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $accessToken';

      final response = await _dio.fetch<dynamic>(requestOptions);
      return handler.resolve(response);
    } on Object catch (error, stackTrace) {
      _logger.error('Token refresh failed', error, stackTrace);
      await _handleSessionExpired();
      return handler.next(err);
    }
  }

  Future<void> _handleSessionExpired() async {
    await _tokenManager.clearTokens();
    _authSessionService.notifySessionExpired();
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _tokenManager.getRefreshToken();
    final deviceId = _preferencesService.getString(StorageKeys.deviceId);

    if (refreshToken == null || deviceId == null) {
      return false;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.authRefresh,
      data: {
        'refreshToken': refreshToken,
        'deviceId': deviceId,
      },
      options: Options(extra: {'skipRefresh': true}),
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      return false;
    }

    final tokens = data['tokens'] as Map<String, dynamic>? ?? data;
    final newAccess = tokens['accessToken'] as String?;
    final newRefresh = tokens['refreshToken'] as String?;
    final expiresIn = tokens['expiresIn'] as int?;

    if (newAccess == null || newRefresh == null) {
      return false;
    }

    await _tokenManager.saveTokens(
      accessToken: newAccess,
      refreshToken: newRefresh,
      expiresIn: expiresIn,
    );
    return true;
  }
}
