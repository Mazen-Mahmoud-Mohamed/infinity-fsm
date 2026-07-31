class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  factory ApiException.fromResponse({
    required int statusCode,
    required dynamic data,
  }) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return ApiException(
          message: error['message'] as String? ?? 'errorRequestFailed',
          statusCode: statusCode,
          code: error['code'] as String?,
        );
      }
    }

    return ApiException(
      message: 'errorRequestFailed',
      statusCode: statusCode,
    );
  }

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
