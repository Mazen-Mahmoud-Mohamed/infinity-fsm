/// Centralized environment / API configuration for Infinity FSM.
///
/// This is the **single source of truth** for the backend base URL.
/// Dio, repositories, and datasources must consume [apiBaseUrl] via DI —
/// never hardcode hosts elsewhere.
///
/// Override at build/run time:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
/// flutter run --dart-define=ENV=production
/// ```
class EnvConfig {
  EnvConfig({
    required String apiBaseUrl,
    required this.enableNetworkLogging,
  }) : _apiBaseUrl = apiBaseUrl;

  /// Production Render API (includes `/api/v1`).
  static const String productionApiBaseUrl =
      'https://infinity-fsm-api.onrender.com/api/v1';

  /// Resolved base URL: `--dart-define=API_BASE_URL=...` or [productionApiBaseUrl].
  static const String resolvedApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionApiBaseUrl,
  );

  factory EnvConfig.development() => EnvConfig(
        apiBaseUrl: resolvedApiBaseUrl,
        enableNetworkLogging: true,
      );

  factory EnvConfig.production() => EnvConfig(
        apiBaseUrl: resolvedApiBaseUrl,
        enableNetworkLogging: false,
      );

  String _apiBaseUrl;

  /// REST API base URL, e.g. `https://host/api/v1`.
  ///
  /// Mutable so [ApiEndpointService] can switch hosts at runtime without
  /// rebuilding Dio's interceptor stack.
  String get apiBaseUrl => _apiBaseUrl;

  void applyApiBaseUrl(String url) {
    _apiBaseUrl = url;
  }

  final bool enableNetworkLogging;

  /// Socket.IO server origin (scheme + host[+port]), derived from [apiBaseUrl].
  ///
  /// Example: `https://infinity-fsm-api.onrender.com`
  String get socketBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    if (!uri.hasScheme || uri.host.isEmpty) {
      return apiBaseUrl;
    }
    return uri.origin;
  }

  static EnvConfig get current {
    const environment = String.fromEnvironment(
      'ENV',
      defaultValue: 'production',
    );
    return environment == 'development'
        ? EnvConfig.development()
        : EnvConfig.production();
  }
}
