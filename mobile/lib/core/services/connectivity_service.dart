import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/core/services/api_reachability_probe.dart';
import 'package:mobile/core/services/app_log_buffer.dart';
import 'package:mobile/core/services/connectivity_status.dart';
import 'package:mobile/core/services/logger_service.dart';

/// Network / internet / API reachability with backend health verification.
///
/// Sync decisions use [ConnectivitySnapshot.canSync] (API reachable).
/// Windows desktops may report false negatives from generic internet probes;
/// the API health check is authoritative for this app.
class ConnectivityService {
  ConnectivityService({
    required EnvConfig envConfig,
    Connectivity? connectivity,
    InternetConnection? internetConnection,
    ApiReachabilityProbe? apiProbe,
    LoggerService? logger,
  })  : _envConfig = envConfig,
        _connectivity = connectivity ?? Connectivity(),
        _internetConnection = internetConnection ?? InternetConnection(),
        _apiProbe = apiProbe ??
            ApiReachabilityProbe(envConfig: envConfig, logger: logger),
        _logger = logger {
    _interfaceSubscription = _connectivity.onConnectivityChanged.listen((_) {
      _scheduleRefresh(reason: 'interface_changed');
    });
  }

  final EnvConfig _envConfig;
  final Connectivity _connectivity;
  final InternetConnection _internetConnection;
  final ApiReachabilityProbe _apiProbe;
  final LoggerService? _logger;

  ConnectivitySnapshot _snapshot = ConnectivitySnapshot.unknown;
  StreamSubscription<List<ConnectivityResult>>? _interfaceSubscription;
  Timer? _debounceTimer;
  bool _refreshInFlight = false;

  static const Duration _debounceDelay = Duration(milliseconds: 750);

  ConnectivitySnapshot get currentSnapshot => _snapshot;

  final _statusController = StreamController<ConnectivitySnapshot>.broadcast();
  final _apiReachableController = StreamController<bool>.broadcast();

  Stream<ConnectivitySnapshot> get onStatusChanged => _statusController.stream;

  /// Emits when API reachability changes — used by sync schedulers.
  Stream<bool> get onConnectivityChanged => _apiReachableController.stream;

  /// True when the Infinity API health endpoint responds successfully.
  Future<bool> get isConnected async {
    final fresh = await refreshStatus();
    return fresh.canSync;
  }

  Future<List<ConnectivityResult>> get connectionTypes async {
    return _connectivity.checkConnectivity();
  }

  void _scheduleRefresh({required String reason}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      unawaited(refreshStatus(reason: reason));
    });
  }

  Future<ConnectivitySnapshot> refreshStatus({
    String reason = 'manual',
    bool forceApiProbe = false,
  }) async {
    if (_refreshInFlight) {
      // Coalesce concurrent probes — callers share the same result.
      while (_refreshInFlight) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      return _snapshot;
    }
    _refreshInFlight = true;

    try {
      final types = await _connectivity.checkConnectivity();
      final networkAvailable = _hasNetworkInterface(types);
      final networkType = _networkTypeLabel(types);

      if (!networkAvailable) {
        return _emit(
          ConnectivitySnapshot(
            level: ConnectivityLevel.networkUnavailable,
            networkAvailable: false,
            networkType: networkType,
            internetReachable: false,
            apiReachable: false,
            reason: 'no_interface',
            checkedAt: DateTime.now(),
          ),
          reason: reason,
        );
      }

      final apiResult = await _apiProbe.check(
        baseUrlOverride: _envConfig.apiBaseUrl,
      );

      if (apiResult.reachable) {
        final internet = await _internetConnection.hasInternetAccess;
        return _emit(
          ConnectivitySnapshot(
            level: ConnectivityLevel.online,
            networkAvailable: true,
            networkType: networkType,
            internetReachable: internet,
            apiReachable: true,
            checkedAt: DateTime.now(),
          ),
          reason: reason,
        );
      }

      final internet = forceApiProbe
          ? await _internetConnection.hasInternetAccess
          : await _internetConnection.hasInternetAccess;

      final level = internet
          ? ConnectivityLevel.apiUnavailable
          : ConnectivityLevel.internetUnavailable;

      return _emit(
        ConnectivitySnapshot(
          level: level,
          networkAvailable: true,
          networkType: networkType,
          internetReachable: internet,
          apiReachable: false,
          reason: apiResult.reason ?? 'api_unreachable',
          checkedAt: DateTime.now(),
        ),
        reason: reason,
      );
    } on Object catch (error) {
      _logger?.warning(
        'CONNECTIVITY refresh failed',
        error,
        null,
        AppLogCategory.network,
      );
      return _snapshot;
    } finally {
      _refreshInFlight = false;
    }
  }

  ConnectivitySnapshot _emit(
    ConnectivitySnapshot next, {
    required String reason,
  }) {
    _logNetworkStatus(next, reason: reason);

    final previousApi = _snapshot.apiReachable;
    _snapshot = next;
    _statusController.add(next);

    if (previousApi != next.apiReachable) {
      _apiReachableController.add(next.apiReachable);
      _logger?.info(
        'CONNECTIVITY apiReachable=${next.apiReachable} reason=$reason',
        null,
        null,
        AppLogCategory.network,
      );
    }

    return next;
  }

  void _logNetworkStatus(
    ConnectivitySnapshot snapshot, {
    required String reason,
  }) {
    _logger?.debug(
      'NETWORK_STATUS '
      'networkAvailable=${snapshot.networkAvailable} '
      'networkType=${snapshot.networkType} '
      'internetReachable=${snapshot.internetReachable} '
      'apiReachable=${snapshot.apiReachable} '
      'level=${snapshot.level.name} '
      'trigger=$reason '
      'detail=${snapshot.reason ?? 'none'}',
      null,
      null,
      AppLogCategory.network,
    );
  }

  bool _hasNetworkInterface(List<ConnectivityResult> types) {
    if (types.isEmpty) {
      return false;
    }
    return types.any(
      (type) =>
          type == ConnectivityResult.wifi ||
          type == ConnectivityResult.mobile ||
          type == ConnectivityResult.ethernet ||
          type == ConnectivityResult.vpn ||
          type == ConnectivityResult.other,
    );
  }

  String _networkTypeLabel(List<ConnectivityResult> types) {
    if (types.contains(ConnectivityResult.wifi)) return 'wifi';
    if (types.contains(ConnectivityResult.ethernet)) return 'ethernet';
    if (types.contains(ConnectivityResult.mobile)) return 'mobile';
    if (types.contains(ConnectivityResult.vpn)) return 'vpn';
    if (types.contains(ConnectivityResult.other)) return 'other';
    if (types.contains(ConnectivityResult.none)) return 'none';
    return 'unknown';
  }

  Future<void> dispose() async {
    await _interfaceSubscription?.cancel();
    _debounceTimer?.cancel();
    await _statusController.close();
    await _apiReachableController.close();
  }
}
