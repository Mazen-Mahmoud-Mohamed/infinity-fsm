import 'package:dio/dio.dart';
import 'package:mobile/core/services/logger_service.dart';
import 'package:mobile/core/storage/token_manager.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenManager);

  final TokenManager _tokenManager;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this._logger);

  final LoggerService _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug('REQUEST ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _logger.debug(
      'RESPONSE ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.error(
      'ERROR ${err.requestOptions.method} ${err.requestOptions.uri}',
      err,
    );
    handler.next(err);
  }
}
