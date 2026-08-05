import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/core/services/app_log_buffer.dart';
import 'package:mobile/core/services/logger_service.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/storage/preferences_service.dart';

/// Runtime API base-URL manager.
///
/// Default comes from [EnvConfig.resolvedApiBaseUrl]. Admins may override
/// via Server Management; the override is persisted and applied to Dio
/// immediately without rebuilding the app.
class ApiEndpointService {
  ApiEndpointService({
    required EnvConfig envConfig,
    required DioClient dioClient,
    required PreferencesService preferences,
    LoggerService? logger,
  })  : _envConfig = envConfig,
        _dioClient = dioClient,
        _preferences = preferences,
        _logger = logger;

  final EnvConfig _envConfig;
  final DioClient _dioClient;
  final PreferencesService _preferences;
  final LoggerService? _logger;

  /// Compile-time / dart-define default (includes `/api/v1`).
  String get defaultBaseUrl => EnvConfig.resolvedApiBaseUrl;

  /// Currently active API base URL used by Dio.
  String get effectiveBaseUrl => _envConfig.apiBaseUrl;

  /// Whether a custom URL is persisted (differs from wiping prefs).
  bool get hasCustomOverride {
    final saved = _preferences.getString(StorageKeys.customApiBaseUrl);
    return saved != null && saved.trim().isNotEmpty;
  }

  DateTime? get lastSuccessfulConnectionAt {
    final ms = _preferences.getInt(StorageKeys.lastSuccessfulApiConnectionMs);
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }

  /// Load persisted override (if any) and apply before the first request.
  Future<void> bootstrap() async {
    final saved = _preferences.getString(StorageKeys.customApiBaseUrl);
    _logger?.debug(
      'ApiEndpointService.bootstrap: hasCustomOverride=${hasCustomOverride}, saved="$saved"',
      null,
      null,
      AppLogCategory.network,
    );
    if (saved == null || saved.trim().isEmpty) {
      return;
    }
    final normalized = ApiUrlNormalizer.normalize(saved);
    if (normalized == null) {
      await _preferences.remove(StorageKeys.customApiBaseUrl);
      return;
    }
    _applyInMemory(normalized);
    _logger?.info(
      'ApiEndpointService.bootstrap applied effectiveBaseUrl="${effectiveBaseUrl}"',
      null,
      null,
      AppLogCategory.network,
    );
  }

  /// Persist + apply a new base URL. Does not restart the app.
  Future<String> saveAndApply(String rawUrl) async {
    final normalized = ApiUrlNormalizer.normalize(rawUrl);
    if (normalized == null) {
      throw ArgumentError('Invalid API base URL');
    }
    await _preferences.setString(StorageKeys.customApiBaseUrl, normalized);
    _applyInMemory(normalized);
    _logger?.info(
      'ApiEndpointService.saveAndApply applied effectiveBaseUrl="$normalized"',
      null,
      null,
      AppLogCategory.network,
    );
    return normalized;
  }

  /// Clear override and restore the compile-time default.
  Future<String> restoreDefault() async {
    await _preferences.remove(StorageKeys.customApiBaseUrl);
    _applyInMemory(defaultBaseUrl);
    _logger?.info(
      'ApiEndpointService.restoreDefault effectiveBaseUrl="$defaultBaseUrl"',
      null,
      null,
      AppLogCategory.network,
    );
    return defaultBaseUrl;
  }

  Future<void> markSuccessfulConnection() async {
    await _preferences.setInt(
      StorageKeys.lastSuccessfulApiConnectionMs,
      DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  void _applyInMemory(String normalizedBaseUrl) {
    _envConfig.applyApiBaseUrl(normalizedBaseUrl);
    _dioClient.applyBaseUrl(normalizedBaseUrl);
    _logger?.debug(
      'ApiEndpointService._applyInMemory => "$normalizedBaseUrl"',
      null,
      null,
      AppLogCategory.network,
    );
  }
}

/// Validates and normalizes backend URLs to `scheme://host[:port]/api/v1`.
class ApiUrlNormalizer {
  ApiUrlNormalizer._();

  static const String apiPathSuffix = '/api/v1';

  /// Returns normalized base URL or `null` when invalid.
  static String? normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    var path = uri.path;
    while (path.endsWith('/') && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }
    if (path.isEmpty || path == '/') {
      path = apiPathSuffix;
    } else if (path == apiPathSuffix || path.endsWith(apiPathSuffix)) {
      // already correct
    } else if (path.endsWith('/api/v1/')) {
      path = apiPathSuffix;
    } else if (!path.contains('/api/')) {
      path = '$path$apiPathSuffix';
    }

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: path,
    ).toString();
  }

  static bool isValid(String raw) => normalize(raw) != null;

  /// Human-friendly server label from host.
  static String serverDisplayName(String apiBaseUrl) {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || uri.host.isEmpty) {
      return AppConfig.appName;
    }
    final host = uri.host.toLowerCase();
    if (host.contains('onrender.com') ||
        host.contains('infinity-fsm-api')) {
      return 'Infinity FSM Production';
    }
    if (host.contains('localhost') || host.contains('127.0.0.1')) {
      return 'Infinity FSM Local';
    }
    return 'Infinity FSM ($host)';
  }
}
