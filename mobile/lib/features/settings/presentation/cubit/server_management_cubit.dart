import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/config/api_endpoint_service.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/services/app_package_info.dart';
import 'package:mobile/core/services/app_runtime_info.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/storage/token_manager.dart';
import 'package:mobile/features/settings/data/datasources/server_health_datasource.dart';
import 'package:mobile/features/settings/domain/entities/server_management_entities.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ServerManagementStatus { idle, testing, pinging, saving, exporting }

class ServerManagementState extends Equatable {
  const ServerManagementState({
    this.status = ServerManagementStatus.idle,
    this.urlInput = '',
    this.urlError,
    this.activeBaseUrl = '',
    this.defaultBaseUrl = '',
    this.connectionTest,
    this.pingResult,
    this.diagnostics,
    this.message,
    this.isError = false,
    this.isDirty = false,
  });

  final ServerManagementStatus status;
  final String urlInput;
  final String? urlError;
  final String activeBaseUrl;
  final String defaultBaseUrl;
  final ServerConnectionTestResult? connectionTest;
  final ServerPingResult? pingResult;
  final ServerDiagnosticsSnapshot? diagnostics;
  final String? message;
  final bool isError;
  final bool isDirty;

  bool get isBusy =>
      status == ServerManagementStatus.testing ||
      status == ServerManagementStatus.pinging ||
      status == ServerManagementStatus.saving ||
      status == ServerManagementStatus.exporting;

  ServerManagementState copyWith({
    ServerManagementStatus? status,
    String? urlInput,
    String? urlError,
    bool clearUrlError = false,
    String? activeBaseUrl,
    String? defaultBaseUrl,
    ServerConnectionTestResult? connectionTest,
    ServerPingResult? pingResult,
    ServerDiagnosticsSnapshot? diagnostics,
    String? message,
    bool clearMessage = false,
    bool? isError,
    bool? isDirty,
  }) {
    return ServerManagementState(
      status: status ?? this.status,
      urlInput: urlInput ?? this.urlInput,
      urlError: clearUrlError ? null : (urlError ?? this.urlError),
      activeBaseUrl: activeBaseUrl ?? this.activeBaseUrl,
      defaultBaseUrl: defaultBaseUrl ?? this.defaultBaseUrl,
      connectionTest: connectionTest ?? this.connectionTest,
      pingResult: pingResult ?? this.pingResult,
      diagnostics: diagnostics ?? this.diagnostics,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props => [
        status,
        urlInput,
        urlError,
        activeBaseUrl,
        defaultBaseUrl,
        connectionTest,
        pingResult,
        diagnostics,
        message,
        isError,
        isDirty,
      ];
}

class ServerManagementCubit extends Cubit<ServerManagementState> {
  ServerManagementCubit({
    required ApiEndpointService apiEndpointService,
    required ServerHealthDataSource healthDataSource,
    required TokenManager tokenManager,
    required ConnectivityService connectivityService,
    required AppRuntimeInfo appRuntimeInfo,
    DeviceInfoPlugin? deviceInfo,
  })  : _api = apiEndpointService,
        _health = healthDataSource,
        _tokens = tokenManager,
        _connectivity = connectivityService,
        _runtime = appRuntimeInfo,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        super(const ServerManagementState());

  final ApiEndpointService _api;
  final ServerHealthDataSource _health;
  final TokenManager _tokens;
  final ConnectivityService _connectivity;
  final AppRuntimeInfo _runtime;
  final DeviceInfoPlugin _deviceInfo;

  String? _userRole;
  String? _userDisplayName;
  int _pendingSyncCount = 0;
  String? _androidVersion;
  String? _deviceModel;

  void configureContext({
    required String? userRole,
    required String? userDisplayName,
    required int pendingSyncCount,
  }) {
    _userRole = userRole;
    _userDisplayName = userDisplayName;
    _pendingSyncCount = pendingSyncCount;
  }

  Future<void> load() async {
    await _loadDeviceInfo();
    final active = _api.effectiveBaseUrl;
    emit(
      state.copyWith(
        urlInput: active,
        activeBaseUrl: active,
        defaultBaseUrl: _api.defaultBaseUrl,
        isDirty: false,
        clearUrlError: true,
        clearMessage: true,
      ),
    );
    await refreshDiagnostics();
  }

  Future<void> _loadDeviceInfo() async {
    if (kIsWeb) {
      _deviceModel = 'Web';
      _androidVersion = null;
      return;
    }
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        _androidVersion = 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
        _deviceModel = '${info.manufacturer} ${info.model}'.trim();
      } else if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        _deviceModel = info.computerName;
        _androidVersion = null;
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        _deviceModel = info.utsname.machine;
        _androidVersion = 'iOS ${info.systemVersion}';
      } else {
        _deviceModel = Platform.operatingSystem;
      }
    } catch (_) {
      _deviceModel = null;
      _androidVersion = null;
    }
  }

  void onUrlChanged(String value) {
    emit(
      state.copyWith(
        urlInput: value,
        isDirty: value.trim() != state.activeBaseUrl,
        clearUrlError: true,
        clearMessage: true,
      ),
    );
  }

  void clearUrl() {
    emit(
      state.copyWith(
        urlInput: '',
        isDirty: true,
        clearUrlError: true,
        clearMessage: true,
      ),
    );
  }

  void applyPastedUrl(String raw) {
    onUrlChanged(raw.trim());
  }

  Future<void> testConnection() async {
    final normalized = ApiUrlNormalizer.normalize(state.urlInput);
    if (normalized == null) {
      emit(
        state.copyWith(
          urlError: 'invalid_url',
          isError: true,
          message: 'serverMgmtInvalidUrl',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ServerManagementStatus.testing,
        clearMessage: true,
        clearUrlError: true,
      ),
    );

    final token = await _tokens.getAccessToken();
    final result = await _health.testConnection(
      normalized,
      accessToken: token,
    );

    if (result.connected) {
      await _api.markSuccessfulConnection();
    }

    final message = switch (result.errorMessage) {
      'timeout' => 'serverMgmtTimeout',
      'invalid_url' => 'serverMgmtInvalidUrl',
      _ => result.connected
          ? 'serverMgmtTestSuccess'
          : 'serverMgmtTestFailed',
    };

    emit(
      state.copyWith(
        status: ServerManagementStatus.idle,
        connectionTest: result,
        isError: !result.connected,
        message: message,
      ),
    );
    await refreshDiagnostics(connection: result, ping: state.pingResult);
  }

  Future<void> pingServer() async {
    final normalized = ApiUrlNormalizer.normalize(state.urlInput);
    if (normalized == null) {
      emit(
        state.copyWith(
          urlError: 'invalid_url',
          isError: true,
          message: 'serverMgmtInvalidUrl',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ServerManagementStatus.pinging,
        clearMessage: true,
        clearUrlError: true,
      ),
    );

    final result = await _health.ping(normalized);

    if (result.reachable) {
      await _api.markSuccessfulConnection();
    }

    final message = switch (result.errorMessage) {
      'timeout' => 'serverMgmtTimeout',
      _ => result.reachable
          ? 'serverMgmtPingSuccess'
          : 'serverMgmtPingFailed',
    };

    emit(
      state.copyWith(
        status: ServerManagementStatus.idle,
        pingResult: result,
        isError: !result.reachable,
        message: message,
      ),
    );
    await refreshDiagnostics(connection: state.connectionTest, ping: result);
  }

  Future<void> save() async {
    final normalized = ApiUrlNormalizer.normalize(state.urlInput);
    if (normalized == null) {
      emit(
        state.copyWith(
          urlError: 'invalid_url',
          isError: true,
          message: 'serverMgmtInvalidUrl',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ServerManagementStatus.saving,
        clearMessage: true,
        clearUrlError: true,
      ),
    );

    try {
      final applied = await _api.saveAndApply(normalized);
      emit(
        state.copyWith(
          status: ServerManagementStatus.idle,
          urlInput: applied,
          activeBaseUrl: applied,
          isDirty: false,
          isError: false,
          message: 'serverMgmtSaveSuccess',
        ),
      );
      await refreshDiagnostics();
    } catch (_) {
      emit(
        state.copyWith(
          status: ServerManagementStatus.idle,
          isError: true,
          message: 'serverMgmtSaveFailed',
        ),
      );
    }
  }

  Future<void> restoreDefault() async {
    emit(
      state.copyWith(
        status: ServerManagementStatus.saving,
        clearMessage: true,
      ),
    );
    final restored = await _api.restoreDefault();
    emit(
      state.copyWith(
        status: ServerManagementStatus.idle,
        urlInput: restored,
        activeBaseUrl: restored,
        isDirty: false,
        isError: false,
        message: 'serverMgmtRestoreSuccess',
      ),
    );
    await refreshDiagnostics();
  }

  void clearFeedback() {
    emit(state.copyWith(clearMessage: true, isError: false));
  }

  /// Human-readable report for clipboard (no secrets).
  String buildCopyReport() {
    final d = state.diagnostics;
    final t = state.connectionTest;
    final p = state.pingResult;
    final buf = StringBuffer()
      ..writeln('Infinity FSM — Server Report')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('Current Server: ${t?.serverName ?? 'Unknown'}')
      ..writeln(
        'Status: ${t == null ? 'Not tested' : (t.connected ? 'Connected' : 'Unreachable')}',
      )
      ..writeln(
        'Backend Version: ${formatBackendVersion(t?.backendVersion)}',
      )
      ..writeln(
        'Environment: ${formatEnvironmentLabel(t?.environment ?? d?.environmentLabel)}',
      )
      ..writeln('API URL: ${d?.currentApiUrl ?? state.activeBaseUrl}')
      ..writeln('Database: ${t?.databaseStatus ?? d?.databaseConnectivity ?? 'Unknown'}')
      ..writeln('Region: ${t?.region ?? d?.region ?? 'Unknown'}')
      ..writeln(
        'Uptime: ${formatServerUptime(t?.serverUptimeSeconds ?? d?.serverUptimeSeconds)}',
      )
      ..writeln(
        'Latency: ${t != null && t.connected ? '${t.responseTimeMs} ms' : (p?.averageMs != null ? '${p!.averageMs!.round()} ms' : 'Unknown')}',
      )
      ..writeln(
        'Quality: ${p?.quality.name ?? t?.quality.name ?? 'unknown'}',
      )
      ..writeln()
      ..writeln('App Version: ${d?.appVersion ?? AppConfig.appVersionFallback}')
      ..writeln('Build: ${d?.buildNumber ?? AppConfig.buildNumberFallback}')
      ..writeln('Platform: ${d?.platform ?? '-'}')
      ..writeln('Device: ${d?.deviceModel ?? '-'}')
      ..writeln('Network: ${d?.networkType ?? '-'}')
      ..writeln('User: ${d?.userDisplayName ?? '-'}')
      ..writeln('Role: ${d?.userRole ?? '-'}')
      ..writeln('Pending Sync: ${d?.pendingSyncCount ?? 0}');
    return buf.toString();
  }

  /// Exports diagnostics JSON via the platform share sheet (no secrets).
  Future<void> exportDiagnostics() async {
    emit(
      state.copyWith(
        status: ServerManagementStatus.exporting,
        clearMessage: true,
      ),
    );
    try {
      await refreshDiagnostics();
      final payload = _buildDiagnosticsMap();
      final json = const JsonEncoder.withIndent('  ').convert(payload);
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final file = File('${dir.path}${Platform.pathSeparator}diagnostics_$stamp.json');
      await file.writeAsString(json);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Infinity FSM Diagnostics',
          text: 'Server management diagnostics export',
        ),
      );

      emit(
        state.copyWith(
          status: ServerManagementStatus.idle,
          isError: false,
          message: 'serverMgmtExportSuccess',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ServerManagementStatus.idle,
          isError: true,
          message: 'serverMgmtExportFailed',
        ),
      );
    }
  }

  Map<String, Object?> _buildDiagnosticsMap() {
    final d = state.diagnostics;
    final t = state.connectionTest;
    final p = state.pingResult;
    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'appVersion': d?.appVersion ?? AppConfig.appVersionFallback,
      'buildNumber': d?.buildNumber ?? AppConfig.buildNumberFallback,
      'platform': d?.platform,
      'deviceModel': d?.deviceModel,
      'androidVersion': d?.androidVersion,
      'apiUrl': d?.currentApiUrl ?? state.activeBaseUrl,
      'serverVersion': formatBackendVersion(t?.backendVersion ?? d?.backendVersion),
      'environment': formatEnvironmentLabel(
        t?.environment ?? d?.environmentLabel,
      ),
      'databaseStatus': t?.databaseStatus ?? d?.databaseConnectivity,
      'region': t?.region ?? d?.region ?? 'Unknown',
      'latencyMs': t?.responseTimeMs ?? p?.averageMs?.round(),
      'averageLatencyMs': p?.averageMs ?? t?.responseTimeMs.toDouble(),
      'minLatencyMs': p?.minMs,
      'maxLatencyMs': p?.maxMs,
      'connectionQuality': (p?.quality ?? t?.quality)?.name,
      'pingSamples': p?.sampleCount,
      'user': d?.userDisplayName,
      'role': d?.userRole,
      'network': d?.networkType,
      'syncQueue': d?.pendingSyncCount,
      'apiHealth': d?.apiHealth.name,
      'backendReachable': d?.backendReachable,
      'localTime': d?.deviceLocalTime.toIso8601String(),
      'serverTime': d?.serverTime?.toIso8601String(),
      'clockDifferenceSeconds': d?.clockDifference?.inSeconds,
      'lastSuccessfulSync': d?.lastSuccessfulSync?.toIso8601String(),
      'lastSuccessfulPing': d?.lastSuccessfulPing?.toIso8601String(),
      'serverUptimeSeconds': t?.serverUptimeSeconds ?? d?.serverUptimeSeconds,
      'requestTimeoutSeconds': d?.requestTimeoutSeconds,
      'appUptimeSeconds': d?.appUptime.inSeconds,
    };
  }

  Future<void> refreshDiagnostics({
    ServerConnectionTestResult? connection,
    ServerPingResult? ping,
  }) async {
    final conn = connection ?? state.connectionTest;
    final pingResult = ping ?? state.pingResult;
    final online = await _connectivity.isConnected;
    final types = await _connectivity.connectionTypes;
    final networkType = _describeNetwork(types);

    final serverTime = conn?.serverTimeUtc?.toLocal();
    final now = DateTime.now();
    Duration? clockDiff;
    if (serverTime != null) {
      clockDiff = now.difference(serverTime).abs();
    }

    ApiHealthStatus health = ApiHealthStatus.unknown;
    if (conn != null) {
      if (!conn.connected) {
        health = ApiHealthStatus.error;
      } else if ((conn.databaseStatus ?? '') == 'disconnected') {
        health = ApiHealthStatus.warning;
      } else {
        health = ApiHealthStatus.healthy;
      }
    } else if (pingResult != null) {
      health = pingResult.reachable
          ? ApiHealthStatus.healthy
          : ApiHealthStatus.error;
    }

    final packageInfo = await AppPackageInfo.load();

    emit(
      state.copyWith(
        diagnostics: ServerDiagnosticsSnapshot(
          appVersion: packageInfo.version,
          buildNumber: packageInfo.buildNumber,
          platform: _platformLabel(),
          androidVersion: _androidVersion,
          deviceModel: _deviceModel,
          currentApiUrl: _api.effectiveBaseUrl,
          // Never invent environment — backend only, else Unknown.
          environmentLabel: formatEnvironmentLabel(conn?.environment),
          backendVersion: formatBackendVersion(conn?.backendVersion),
          deviceLocalTime: now,
          deviceTimezone: now.timeZoneName,
          serverTime: serverTime,
          serverTimezone: serverTime != null ? 'UTC' : null,
          clockDifference: clockDiff,
          isOnline: online,
          networkType: networkType,
          userRole: _userRole ?? 'Unknown',
          userDisplayName: _userDisplayName ?? 'Unknown',
          lastSuccessfulSync: _api.lastSuccessfulConnectionAt,
          lastSuccessfulPing: pingResult?.completedAt,
          pendingSyncCount: _pendingSyncCount,
          backendReachable: conn?.connected == true ||
              pingResult?.reachable == true,
          apiHealth: health,
          databaseConnectivity: conn?.databaseStatus ?? 'Unknown',
          averageLatencyMs: pingResult?.averageMs ??
              conn?.responseTimeMs.toDouble(),
          minLatencyMs: pingResult?.minMs,
          maxLatencyMs: pingResult?.maxMs,
          connectionQuality: pingResult?.quality ?? conn?.quality,
          requestTimeoutSeconds: AppConfig.connectTimeout.inSeconds,
          appUptime: _runtime.uptime,
          serverUptimeSeconds: conn?.serverUptimeSeconds,
          region: conn?.region,
        ),
      ),
    );
  }

  String _platformLabel() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return defaultTargetPlatform.name;
  }

  String _describeNetwork(List<ConnectivityResult> types) {
    if (types.isEmpty || types.contains(ConnectivityResult.none)) {
      return 'None';
    }
    final labels = <String>[];
    for (final t in types) {
      switch (t) {
        case ConnectivityResult.wifi:
          labels.add('Wi-Fi');
        case ConnectivityResult.mobile:
          labels.add('Mobile');
        case ConnectivityResult.ethernet:
          labels.add('Ethernet');
        case ConnectivityResult.vpn:
          labels.add('VPN');
        case ConnectivityResult.other:
          labels.add('Other');
        case ConnectivityResult.bluetooth:
          labels.add('Bluetooth');
        case ConnectivityResult.satellite:
          labels.add('Satellite');
        case ConnectivityResult.none:
          break;
      }
    }
    return labels.isEmpty ? 'None' : labels.join(', ');
  }
}
