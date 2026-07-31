class EnvConfig {
  EnvConfig({
    required this.apiBaseUrl,
    required this.enableNetworkLogging,
  });

  factory EnvConfig.development() => EnvConfig(
        apiBaseUrl: 'http://192.168.1.16:3000/api/v1',
        enableNetworkLogging: true,
      );

  factory EnvConfig.production() => EnvConfig(
        apiBaseUrl: const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://api.infinity-fsm.com/api/v1',
        ),
        enableNetworkLogging: false,
      );

  final String apiBaseUrl;
  final bool enableNetworkLogging;

  static EnvConfig get current {
    const environment = String.fromEnvironment(
      'ENV',
      defaultValue: 'development',
    );
    return environment == 'production'
        ? EnvConfig.production()
        : EnvConfig.development();
  }
}
