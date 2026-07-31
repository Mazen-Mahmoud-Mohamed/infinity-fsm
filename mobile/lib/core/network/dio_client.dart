import 'package:dio/dio.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:mobile/core/network/interceptors/refresh_token_interceptor.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/services/logger_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/storage/token_manager.dart';

class DioClient {
  DioClient({
    required EnvConfig envConfig,
    required TokenManager tokenManager,
    required PreferencesService preferencesService,
    required LoggerService logger,
    required AuthSessionService authSessionService,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: envConfig.apiBaseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            sendTimeout: AppConfig.sendTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    if (envConfig.enableNetworkLogging) {
      _dio.interceptors.add(LoggingInterceptor(logger));
    }

    _dio.interceptors.add(AuthInterceptor(tokenManager));
    _dio.interceptors.add(
      RefreshTokenInterceptor(
        dio: _dio,
        tokenManager: tokenManager,
        preferencesService: preferencesService,
        logger: logger,
        authSessionService: authSessionService,
      ),
    );
  }

  final Dio _dio;

  Dio get instance => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _handle(() => _dio.get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _handle(() => _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _handle(() => _dio.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _handle(() => _dio.patch<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _handle(() => _dio.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  Future<Response<T>> _handle<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      if (error.response != null) {
        throw ApiException.fromResponse(
          statusCode: error.response!.statusCode ?? 500,
          data: error.response!.data,
        );
      }

      final isTimeout = error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
      final isOffline = error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;

      throw ApiException(
        message: isTimeout ? 'errorRequestTimeout' : 'errorUnableToReachServer',
        code: isTimeout
            ? 'TIMEOUT'
            : (isOffline ? 'OFFLINE' : 'NETWORK_ERROR'),
      );
    }
  }
}
