import 'package:equatable/equatable.dart';

enum ConnectionQuality { excellent, good, fair, slow, poor, unreachable }

enum ApiHealthStatus { healthy, warning, error, unknown }

class ServerPingResult extends Equatable {
  const ServerPingResult({
    required this.reachable,
    required this.sampleCount,
    this.averageMs,
    this.minMs,
    this.maxMs,
    this.quality = ConnectionQuality.unreachable,
    this.errorMessage,
    this.completedAt,
  });

  final bool reachable;
  final int sampleCount;
  final double? averageMs;
  final int? minMs;
  final int? maxMs;
  final ConnectionQuality quality;
  final String? errorMessage;
  final DateTime? completedAt;

  @override
  List<Object?> get props => [
        reachable,
        sampleCount,
        averageMs,
        minMs,
        maxMs,
        quality,
        errorMessage,
        completedAt,
      ];
}

class ServerConnectionTestResult extends Equatable {
  const ServerConnectionTestResult({
    required this.connected,
    required this.serverName,
    required this.responseTimeMs,
    this.backendVersion,
    this.environment,
    this.apiStatus,
    this.databaseStatus,
    this.serverTimeUtc,
    this.serverUptimeSeconds,
    this.region,
    this.quality = ConnectionQuality.unreachable,
    this.errorMessage,
  });

  final bool connected;
  final String serverName;
  final int responseTimeMs;
  final String? backendVersion;
  final String? environment;
  final String? apiStatus;
  final String? databaseStatus;
  final DateTime? serverTimeUtc;
  final int? serverUptimeSeconds;
  final String? region;
  final ConnectionQuality quality;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        connected,
        serverName,
        responseTimeMs,
        backendVersion,
        environment,
        apiStatus,
        databaseStatus,
        serverTimeUtc,
        serverUptimeSeconds,
        region,
        quality,
        errorMessage,
      ];
}

class ServerDiagnosticsSnapshot extends Equatable {
  const ServerDiagnosticsSnapshot({
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.currentApiUrl,
    required this.environmentLabel,
    required this.deviceLocalTime,
    required this.deviceTimezone,
    required this.isOnline,
    required this.networkType,
    required this.userRole,
    required this.userDisplayName,
    required this.pendingSyncCount,
    required this.backendReachable,
    required this.apiHealth,
    required this.databaseConnectivity,
    required this.requestTimeoutSeconds,
    required this.appUptime,
    this.androidVersion,
    this.deviceModel,
    this.serverTime,
    this.serverTimezone,
    this.clockDifference,
    this.lastSuccessfulSync,
    this.lastSuccessfulPing,
    this.averageLatencyMs,
    this.minLatencyMs,
    this.maxLatencyMs,
    this.backendVersion,
    this.connectionQuality,
    this.serverUptimeSeconds,
    this.region,
  });

  final String appVersion;
  final String buildNumber;
  final String platform;
  final String? androidVersion;
  final String? deviceModel;
  final String currentApiUrl;
  final String environmentLabel;
  final String? backendVersion;
  final DateTime deviceLocalTime;
  final String deviceTimezone;
  final DateTime? serverTime;
  final String? serverTimezone;
  final Duration? clockDifference;
  final bool isOnline;
  final String networkType;
  final String userRole;
  final String userDisplayName;
  final DateTime? lastSuccessfulSync;
  final DateTime? lastSuccessfulPing;
  final int pendingSyncCount;
  final bool backendReachable;
  final ApiHealthStatus apiHealth;
  final String databaseConnectivity;
  final double? averageLatencyMs;
  final int? minLatencyMs;
  final int? maxLatencyMs;
  final ConnectionQuality? connectionQuality;
  final int requestTimeoutSeconds;
  final Duration appUptime;
  final int? serverUptimeSeconds;
  final String? region;

  @override
  List<Object?> get props => [
        appVersion,
        buildNumber,
        platform,
        androidVersion,
        deviceModel,
        currentApiUrl,
        environmentLabel,
        backendVersion,
        deviceLocalTime,
        deviceTimezone,
        serverTime,
        serverTimezone,
        clockDifference,
        isOnline,
        networkType,
        userRole,
        userDisplayName,
        lastSuccessfulSync,
        lastSuccessfulPing,
        pendingSyncCount,
        backendReachable,
        apiHealth,
        databaseConnectivity,
        averageLatencyMs,
        minLatencyMs,
        maxLatencyMs,
        connectionQuality,
        requestTimeoutSeconds,
        appUptime,
        serverUptimeSeconds,
        region,
      ];
}

ConnectionQuality qualityFromLatencyMs(num ms) {
  if (ms < 100) return ConnectionQuality.excellent;
  if (ms < 250) return ConnectionQuality.good;
  if (ms < 500) return ConnectionQuality.fair;
  if (ms <= 1000) return ConnectionQuality.slow;
  return ConnectionQuality.poor;
}

String formatEnvironmentLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Unknown';
  final v = raw.trim().toLowerCase();
  if (v == 'production' || v == 'prod') return 'Production';
  if (v == 'staging' || v == 'stage') return 'Staging';
  if (v == 'development' || v == 'dev') return 'Development';
  if (v == 'unknown') return 'Unknown';
  // Preserve custom backend values with title-case-ish display.
  return raw.trim();
}

String formatBackendVersion(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Unknown';
  final v = raw.trim();
  if (v.toLowerCase() == 'unknown') return 'Unknown';
  return v.startsWith('v') || v.startsWith('V') ? v : 'v$v';
}

String formatServerUptime(int? seconds) {
  if (seconds == null || seconds < 0) return 'Unknown';
  final d = Duration(seconds: seconds);
  final days = d.inDays;
  final hours = d.inHours.remainder(24);
  final mins = d.inMinutes.remainder(60);
  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${mins}m';
  return '${mins}m';
}
