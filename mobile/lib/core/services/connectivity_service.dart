import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    InternetConnection? internetConnection,
  })  : _connectivity = connectivity ?? Connectivity(),
        _internetConnection = internetConnection ?? InternetConnection();

  final Connectivity _connectivity;
  final InternetConnection _internetConnection;

  Future<bool> get isConnected async => _internetConnection.hasInternetAccess;

  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.asyncMap((_) => isConnected);
}
