import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/utils/result.dart';

class NetworkErrorMapper {
  NetworkErrorMapper._();

  static Failure<T> map<T>(Object error) {
    if (kDebugMode) {
      debugPrint('Mapped network error: $error');
    }

    if (error is ApiException) {
      final code = error.code ?? _codeForStatus(error.statusCode);
      return Failure(
        _messageKeyForApiException(error, code),
        code: code,
      );
    }

    if (error is DioException) {
      return Failure(
        _messageForDioException(error),
        code: _codeForDioException(error),
      );
    }

    return const Failure(
      'errorGeneric',
      code: 'UNKNOWN',
    );
  }

  /// Prefer stable API error codes so UI never shows raw English text.
  static String _messageKeyForApiException(ApiException error, String? code) {
    // If Dio already classified the transport error into a specific,
    // localized message key, preserve it. Otherwise we'd lose granularity
    // and everything collapses into a generic connectivity message.
    final message = error.message;
    if (_isAlreadySpecificConnectivityKey(message)) {
      return message;
    }

    if (code == 'OFFLINE' ||
        code == 'TIMEOUT' ||
        code == 'NETWORK_ERROR' ||
        _looksTechnical(error.message)) {
      return _friendlyConnectivityMessage(code);
    }

    final apiCode = error.code?.trim();
    if (apiCode != null &&
        apiCode.isNotEmpty &&
        !_isGenericTransportCode(apiCode)) {
      return apiCode;
    }

    switch (error.statusCode) {
      case 401:
        return 'INVALID_EMAIL';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 422:
      case 400:
        return 'VALIDATION_ERROR';
      case 500:
        return 'errorServer';
      default:
        return 'errorGeneric';
    }
  }

  static bool _isGenericTransportCode(String code) {
    return code == 'API_ERROR' ||
        code == 'UNKNOWN' ||
        code == 'NETWORK_ERROR' ||
        code == 'TIMEOUT' ||
        code == 'OFFLINE';
  }

  static bool _looksTechnical(String message) {
    final lower = message.toLowerCase();
    return lower.contains('connection errored') ||
        lower.contains('socketexception') ||
        lower.contains('dioexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection reset') ||
        lower.contains('connection refused') ||
        lower.contains('clientexception') ||
        lower.contains('http request') ||
        lower.contains('xmlhttprequest');
  }

  static bool _isAlreadySpecificConnectivityKey(String? message) {
    if (message == null) return false;
    return message == 'errorNoInternet' ||
        message == 'errorRequestTimeout' ||
        message == 'errorSecureConnectionFailed' ||
        message == 'errorUnableToReachServer' ||
        message == 'errorUnexpectedNetworkError';
  }

  static String _friendlyConnectivityMessage(String? code) {
    switch (code) {
      case 'TIMEOUT':
        return 'errorRequestTimeout';
      case 'OFFLINE':
      case 'NETWORK_ERROR':
      default:
        return 'errorUnableToReachServer';
    }
  }

  static String _codeForStatus(int? statusCode) {
    switch (statusCode) {
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 422:
      case 400:
        return 'VALIDATION_ERROR';
      case 500:
        return 'SERVER_ERROR';
      default:
        return 'API_ERROR';
    }
  }

  static String _messageForDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'errorRequestTimeout';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'errorUnableToReachServer';
      default:
        return 'errorUnableToReachServer';
    }
  }

  static String _codeForDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'TIMEOUT';
      case DioExceptionType.connectionError:
        return 'OFFLINE';
      default:
        return 'NETWORK_ERROR';
    }
  }
}
