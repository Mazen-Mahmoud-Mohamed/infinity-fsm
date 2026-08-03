import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile/core/services/connectivity_service.dart';

/// Device telemetry captured with each overtime checkpoint.
class CheckpointTelemetry {
  const CheckpointTelemetry({
    this.batteryLevel,
    required this.networkStatus,
  });

  final int? batteryLevel;
  final String networkStatus;
}

/// Collects battery + network snapshot for overtime checkpoints.
class CheckpointTelemetryService {
  CheckpointTelemetryService({
    required ConnectivityService connectivityService,
    Battery? battery,
    Connectivity? connectivity,
  })  : _connectivityService = connectivityService,
        _battery = battery ?? Battery(),
        _connectivity = connectivity ?? Connectivity();

  final ConnectivityService _connectivityService;
  final Battery _battery;
  final Connectivity _connectivity;

  Future<CheckpointTelemetry> capture() async {
    final online = await _connectivityService.isConnected;
    final results = await _connectivity.checkConnectivity();
    final networkStatus = _mapNetworkStatus(online: online, results: results);

    int? batteryLevel;
    try {
      final level = await _battery.batteryLevel;
      if (level >= 0 && level <= 100) {
        batteryLevel = level;
      }
    } on Object {
      batteryLevel = null;
    }

    return CheckpointTelemetry(
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
    );
  }

  String _mapNetworkStatus({
    required bool online,
    required List<ConnectivityResult> results,
  }) {
    if (!online) {
      return 'offline';
    }
    if (results.contains(ConnectivityResult.wifi)) {
      return 'wifi';
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return 'mobile';
    }
    if (results.contains(ConnectivityResult.ethernet)) {
      return 'ethernet';
    }
    if (results.contains(ConnectivityResult.vpn)) {
      return 'vpn';
    }
    if (results.contains(ConnectivityResult.other)) {
      return 'online';
    }
    return 'online';
  }
}
