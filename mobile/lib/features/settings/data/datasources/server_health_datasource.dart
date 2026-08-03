import 'package:dio/dio.dart';
import 'package:mobile/core/config/api_endpoint_service.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/features/settings/domain/entities/server_management_entities.dart';

/// Unauthenticated probes against a candidate API base URL.
///
/// Uses a short-lived [Dio] instance so auth interceptors never attach —
/// Ping / Test Connection must not login or touch business data.
class ServerHealthDataSource {
  static const int _pingSamples = 5;

  Dio _probeClient(String apiBaseUrl) {
    return Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: const {
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<ServerPingResult> ping(String rawOrNormalizedUrl) async {
    final baseUrl = ApiUrlNormalizer.normalize(rawOrNormalizedUrl);
    if (baseUrl == null) {
      return const ServerPingResult(
        reachable: false,
        sampleCount: 0,
        errorMessage: 'invalid_url',
      );
    }

    final client = _probeClient(baseUrl);
    final latencies = <int>[];
    var sawTimeout = false;

    try {
      for (var i = 0; i < _pingSamples; i++) {
        final sw = Stopwatch()..start();
        try {
          final response = await client.get<Map<String, dynamic>>('/health');
          sw.stop();
          if (response.statusCode == 200) {
            latencies.add(sw.elapsedMilliseconds);
          }
        } on DioException catch (e) {
          sw.stop();
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            sawTimeout = true;
          }
        }
      }

      if (latencies.isEmpty) {
        return ServerPingResult(
          reachable: false,
          sampleCount: 0,
          quality: ConnectionQuality.unreachable,
          errorMessage: sawTimeout ? 'timeout' : 'unreachable',
          completedAt: DateTime.now(),
        );
      }

      final sum = latencies.fold<int>(0, (a, b) => a + b);
      final avg = sum / latencies.length;
      final min = latencies.reduce((a, b) => a < b ? a : b);
      final max = latencies.reduce((a, b) => a > b ? a : b);

      return ServerPingResult(
        reachable: true,
        sampleCount: latencies.length,
        averageMs: avg,
        minMs: min,
        maxMs: max,
        quality: qualityFromLatencyMs(avg),
        completedAt: DateTime.now(),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<ServerConnectionTestResult> testConnection(
    String rawOrNormalizedUrl, {
    String? accessToken,
  }) async {
    final baseUrl = ApiUrlNormalizer.normalize(rawOrNormalizedUrl);
    if (baseUrl == null) {
      return ServerConnectionTestResult(
        connected: false,
        serverName: ApiUrlNormalizer.serverDisplayName(''),
        responseTimeMs: 0,
        errorMessage: 'invalid_url',
      );
    }

    final client = _probeClient(baseUrl);
    final serverName = ApiUrlNormalizer.serverDisplayName(baseUrl);

    try {
      final sw = Stopwatch()..start();
      final health = await client.get<Map<String, dynamic>>('/health');
      sw.stop();
      final latency = sw.elapsedMilliseconds;

      if (health.statusCode != 200) {
        return ServerConnectionTestResult(
          connected: false,
          serverName: serverName,
          responseTimeMs: latency,
          quality: ConnectionQuality.unreachable,
          errorMessage: 'unreachable',
        );
      }

      final healthData =
          health.data?['data'] as Map<String, dynamic>? ?? const {};
      DateTime? serverTime;
      final utcNow = healthData['utcNow'] ?? healthData['timestamp'];
      if (utcNow is String) {
        serverTime = DateTime.tryParse(utcNow)?.toUtc();
      }

      int? uptimeSeconds;
      final uptimeRaw = healthData['uptime'];
      if (uptimeRaw is num) {
        uptimeSeconds = uptimeRaw.round();
      }

      String? databaseStatus;
      try {
        final ready = await client.get<Map<String, dynamic>>('/health/ready');
        final readyData =
            ready.data?['data'] as Map<String, dynamic>? ?? const {};
        databaseStatus = readyData['mongodb']?.toString() ??
            (ready.statusCode == 200 ? 'connected' : 'disconnected');
      } on DioException {
        databaseStatus = 'disconnected';
      }

      String? backendVersion;
      String? environment;
      String? region;
      String? apiStatus = healthData['status']?.toString() ?? 'ok';

      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          final system = await client.get<Map<String, dynamic>>(
            ApiConstants.settingsSystem,
            options: Options(
              headers: {'Authorization': 'Bearer $accessToken'},
            ),
          );
          final data =
              system.data?['data'] as Map<String, dynamic>? ?? const {};
          backendVersion = data['backendVersion']?.toString();
          environment = data['environment']?.toString();
          region = data['region']?.toString() ?? data['serverRegion']?.toString();
          apiStatus = data['apiStatus']?.toString() ?? apiStatus;
          databaseStatus =
              data['databaseStatus']?.toString() ?? databaseStatus;
          final sysUptime = data['uptimeSeconds'];
          if (sysUptime is num) {
            uptimeSeconds = sysUptime.round();
          }
        } on DioException {
          // Optional enrichment — health alone is enough for connectivity.
        }
      }

      return ServerConnectionTestResult(
        connected: true,
        serverName: serverName,
        responseTimeMs: latency,
        backendVersion: backendVersion,
        environment: environment,
        apiStatus: apiStatus,
        databaseStatus: databaseStatus,
        serverTimeUtc: serverTime,
        serverUptimeSeconds: uptimeSeconds,
        region: region,
        quality: qualityFromLatencyMs(latency),
      );
    } on DioException catch (e) {
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      return ServerConnectionTestResult(
        connected: false,
        serverName: serverName,
        responseTimeMs: 0,
        quality: ConnectionQuality.unreachable,
        errorMessage: isTimeout ? 'timeout' : 'unreachable',
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Request timeout shown in diagnostics (matches app client).
  int get requestTimeoutSeconds => AppConfig.connectTimeout.inSeconds;
}
