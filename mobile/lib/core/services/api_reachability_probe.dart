import 'package:dio/dio.dart';
import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/core/services/app_log_buffer.dart';
import 'package:mobile/core/services/logger_service.dart';

/// Result of a lightweight GET /health probe against the Infinity API.
class ApiReachabilityResult {
  const ApiReachabilityResult({
    required this.reachable,
    this.reason,
    this.latencyMs,
  });

  final bool reachable;
  final String? reason;
  final int? latencyMs;
}

/// Unauthenticated backend health probe — no auth interceptors attached.
class ApiReachabilityProbe {
  ApiReachabilityProbe({
    required EnvConfig envConfig,
    LoggerService? logger,
    Duration? timeout,
  })  : _envConfig = envConfig,
        _logger = logger,
        _timeout = timeout ?? const Duration(seconds: 15);

  final EnvConfig _envConfig;
  final LoggerService? _logger;
  final Duration _timeout;

  Future<ApiReachabilityResult> check({String? baseUrlOverride}) async {
    final baseUrl = baseUrlOverride ?? _envConfig.apiBaseUrl;
    final client = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
        headers: const {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    final sw = Stopwatch()..start();
    try {
      final response = await client.get<Map<String, dynamic>>('/health');
      sw.stop();

      if (response.statusCode == 200) {
        _logger?.debug(
          'API_REACHABILITY ok latencyMs=${sw.elapsedMilliseconds}',
          null,
          null,
          AppLogCategory.network,
        );
        return ApiReachabilityResult(
          reachable: true,
          latencyMs: sw.elapsedMilliseconds,
        );
      }

      return ApiReachabilityResult(
        reachable: false,
        reason: 'http_${response.statusCode}',
        latencyMs: sw.elapsedMilliseconds,
      );
    } on DioException catch (error) {
      sw.stop();
      final reason = _mapDioReason(error);
      _logger?.debug(
        'API_REACHABILITY failed reason=$reason',
        error.message,
        null,
        AppLogCategory.network,
      );
      return ApiReachabilityResult(
        reachable: false,
        reason: reason,
        latencyMs: sw.elapsedMilliseconds,
      );
    } on Object catch (error) {
      sw.stop();
      return ApiReachabilityResult(
        reachable: false,
        reason: error.toString(),
        latencyMs: sw.elapsedMilliseconds,
      );
    } finally {
      client.close(force: true);
    }
  }

  String _mapDioReason(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'timeout',
      DioExceptionType.connectionError =>
        _connectionErrorReason(error),
      DioExceptionType.badCertificate => 'certificate',
      DioExceptionType.unknown => 'unknown',
      _ => error.type.name,
    };
  }

  String _connectionErrorReason(DioException error) {
    final message = (error.message ?? '').toLowerCase();
    if (message.contains('failed host lookup') ||
        message.contains('getaddrinfo') ||
        message.contains('name resolution')) {
      return 'dns';
    }
    if (message.contains('connection refused')) {
      return 'connection_refused';
    }
    if (message.contains('connection reset')) {
      return 'connection_reset';
    }
    return 'connection_error';
  }
}
