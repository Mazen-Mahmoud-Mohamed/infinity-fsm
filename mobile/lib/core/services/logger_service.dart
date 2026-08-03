import 'package:logger/logger.dart';
import 'package:mobile/core/services/app_log_buffer.dart';

class LoggerService {
  LoggerService({AppLogBuffer? logBuffer})
      : _logBuffer = logBuffer ?? AppLogBuffer(),
        _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
            lineLength: 100,
            colors: true,
            printEmojis: false,
          ),
        );

  final Logger _logger;
  final AppLogBuffer _logBuffer;

  AppLogBuffer get buffer => _logBuffer;

  void debug(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    AppLogCategory category = AppLogCategory.general,
  ]) {
    final safe = sanitizeLogMessage(message);
    _capture(AppLogLevel.debug, safe, category);
    _logger.d(safe, error: error, stackTrace: stackTrace);
  }

  void info(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    AppLogCategory category = AppLogCategory.general,
  ]) {
    final safe = sanitizeLogMessage(message);
    _capture(AppLogLevel.info, safe, category);
    _logger.i(safe, error: error, stackTrace: stackTrace);
  }

  void warning(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    AppLogCategory category = AppLogCategory.general,
  ]) {
    final safe = sanitizeLogMessage(message);
    _capture(AppLogLevel.warning, safe, category);
    _logger.w(safe, error: error, stackTrace: stackTrace);
  }

  void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    AppLogCategory category = AppLogCategory.error,
  ]) {
    final safe = sanitizeLogMessage(message);
    _capture(AppLogLevel.error, safe, category);
    _logger.e(safe, error: error, stackTrace: stackTrace);
  }

  void _capture(AppLogLevel level, String message, AppLogCategory category) {
    _logBuffer.add(
      AppLogEntry(
        timestamp: DateTime.now(),
        level: level,
        category: category,
        message: message,
      ),
    );
  }
}
