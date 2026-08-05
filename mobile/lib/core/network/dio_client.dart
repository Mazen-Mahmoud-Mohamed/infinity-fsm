import 'package:dio/dio.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:mobile/core/network/interceptors/refresh_token_interceptor.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/services/app_log_buffer.dart';
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
    _logger = logger;
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
  late final LoggerService _logger;

  Dio get instance => _dio;

  /// Hot-swap the API base URL for all subsequent requests.
  void applyBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _handle('GET', path, () => _dio.get<T>(
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
    return _handle('POST', path, () => _dio.post<T>(
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
    return _handle('PUT', path, () => _dio.put<T>(
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
    return _handle('PATCH', path, () => _dio.patch<T>(
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
    return _handle('DELETE', path, () => _dio.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  String _fullUrl(String path) {
    final base = _dio.options.baseUrl.toString();
    if (base.isEmpty) return path;
    final baseWithSlash = base.endsWith('/') ? base : '$base/';
    final normalizedPath =
        path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(baseWithSlash).resolve(normalizedPath).toString();
  }

  Future<Response<T>> _handle<T>(
    String method,
    String path,
    Future<Response<T>> Function() request,
  ) async {
    try {
      _logger.debug(
        'Dio request: $method ${_fullUrl(path)}',
        null,
        null,
        AppLogCategory.network,
      );
      return await request();
    } on DioException catch (error) {
      if (error.response != null) {
        _logger.warning(
          'Dio http error: $method ${_fullUrl(path)} '
          'status=${error.response?.statusCode} '
          'message=${error.message}',
          null,
          null,
          AppLogCategory.network,
        );
        throw ApiException.fromResponse(
          statusCode: error.response!.statusCode ?? 500,
          data: error.response!.data,
        );
      }

      final isTimeout = error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
      final errText = (error.error?.toString() ?? '').toLowerCase();

      // Transport-level classification. Do NOT rely only on DioExceptionType
      // because multiple underlying socket/TLS failures map to the same type.
      final isSocketException = errText.contains('socketexception');
      final isConnectionRefused = errText.contains('connection refused');
      final isHandshakeException =
          errText.contains('handshakeexception') ||
              (errText.contains('ssl') && errText.contains('handshake')) ||
              (errText.contains('certificate') && errText.contains('verify'));
      final isDnsFailure = errText.contains('failed host lookup') ||
          errText.contains('name or service not known') ||
          errText.contains('dns') ||
          errText.contains('nodename nor servname');

      final mappedMessageKey = switch ((
        isTimeout,
        isSocketException || isConnectionRefused,
        isHandshakeException,
        isDnsFailure,
        error.type == DioExceptionType.unknown
      )) {
        (true, _, _, _, _) => 'errorRequestTimeout',
        (false, true, _, _, _) => 'errorNoInternet',
        (false, _, true, _, _) => 'errorSecureConnectionFailed',
        (false, _, _, true, _) => 'errorUnableToReachServer',
        (false, _, _, _, true) => 'errorUnexpectedNetworkError',
        _ => 'errorUnableToReachServer',
      };

      final mappedCode = switch (mappedMessageKey) {
        'errorRequestTimeout' => 'TIMEOUT',
        'errorNoInternet' ||
        'errorSecureConnectionFailed' ||
        'errorUnableToReachServer' =>
          'OFFLINE',
        'errorUnexpectedNetworkError' => 'NETWORK_ERROR',
        _ => 'NETWORK_ERROR',
      };

      _logger.error(
        'Dio exception: $method ${_fullUrl(path)} '
        'type=${error.type} '
        'message=${error.message} '
        'requestUri=${error.requestOptions.uri} '
        'error=${error.error}',
        error,
        error.stackTrace,
        AppLogCategory.network,
      );

      _logger.info(
        'Dio exception mapped => messageKey=$mappedMessageKey code=$mappedCode',
        null,
        null,
        AppLogCategory.network,
      );

      throw ApiException(
        message: mappedMessageKey,
        code: mappedCode,
      );
    }
  }
}
