import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobile/core/services/app_log_buffer.dart';
import 'package:mobile/core/services/logger_service.dart';

class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    InternetConnection? internetConnection,
    LoggerService? logger,
  })  : _connectivity = connectivity ?? Connectivity(),
        _internetConnection = internetConnection ?? InternetConnection(),
        _logger = logger;

  final Connectivity _connectivity;
  final InternetConnection _internetConnection;
  final LoggerService? _logger;

  Future<bool> get isConnected async {
    final ok = await _internetConnection.hasInternetAccess;
    _logger?.debug(
      'ConnectivityService.isConnected => $ok',
      null,
      null,
      AppLogCategory.network,
    );
    return ok;
  }

  /// Active link types (wifi / mobile / ethernet / none / other).
  Future<List<ConnectivityResult>> get connectionTypes async {
    final types = await _connectivity.checkConnectivity();
    _logger?.debug(
      'ConnectivityService.connectionTypes => $types',
      null,
      null,
      AppLogCategory.network,
    );
    return types;
  }

  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.asyncMap((_) => isConnected);
}
