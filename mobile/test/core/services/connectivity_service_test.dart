import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/core/services/api_reachability_probe.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/connectivity_status.dart';

class _FakeConnectivityPlugin extends Fake implements Connectivity {
  _FakeConnectivityPlugin(this._types);

  List<ConnectivityResult> _types;
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  void setTypes(List<ConnectivityResult> types) {
    _types = types;
    _controller.add(_types);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _types;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  Future<void> dispose() => _controller.close();
}

class _FakeInternetConnection extends Fake implements InternetConnection {
  _FakeInternetConnection({this.hasAccess = true});

  bool hasAccess;

  @override
  Future<bool> get hasInternetAccess async => hasAccess;
}

class _FakeApiProbe extends Fake implements ApiReachabilityProbe {
  _FakeApiProbe({this.reachable = true, this.reason});

  bool reachable;
  String? reason;

  @override
  Future<ApiReachabilityResult> check({String? baseUrlOverride}) async {
    return ApiReachabilityResult(
      reachable: reachable,
      reason: reason,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeConnectivityPlugin connectivityPlugin;
  late _FakeInternetConnection internet;
  late _FakeApiProbe apiProbe;
  late ConnectivityService service;

  setUp(() {
    connectivityPlugin = _FakeConnectivityPlugin([ConnectivityResult.wifi]);
    internet = _FakeInternetConnection(hasAccess: true);
    apiProbe = _FakeApiProbe(reachable: true);
    service = ConnectivityService(
      envConfig: EnvConfig(
        apiBaseUrl: 'https://example.com/api/v1',
        enableNetworkLogging: false,
      ),
      connectivity: connectivityPlugin,
      internetConnection: internet,
      apiProbe: apiProbe,
    );
  });

  tearDown(() async {
    await connectivityPlugin.dispose();
    await service.dispose();
  });

  test('wifi + API reachable => online', () async {
    final snapshot = await service.refreshStatus(reason: 'test');

    expect(snapshot.level, ConnectivityLevel.online);
    expect(snapshot.canSync, isTrue);
    expect(snapshot.networkType, 'wifi');
  });

  test('wifi + API unreachable + internet ok => apiUnavailable', () async {
    apiProbe.reachable = false;
    apiProbe.reason = 'timeout';

    final snapshot = await service.refreshStatus(reason: 'test');

    expect(snapshot.level, ConnectivityLevel.apiUnavailable);
    expect(snapshot.canSync, isFalse);
    expect(snapshot.reason, 'timeout');
  });

  test('no network interface => networkUnavailable', () async {
    connectivityPlugin.setTypes([ConnectivityResult.none]);

    final snapshot = await service.refreshStatus(reason: 'test');

    expect(snapshot.level, ConnectivityLevel.networkUnavailable);
    expect(snapshot.canSync, isFalse);
  });

  test('wifi + API unreachable + no internet => internetUnavailable', () async {
    apiProbe.reachable = false;
    internet.hasAccess = false;

    final snapshot = await service.refreshStatus(reason: 'test');

    expect(snapshot.level, ConnectivityLevel.internetUnavailable);
    expect(snapshot.canSync, isFalse);
  });

  test('API recovery emits onConnectivityChanged true', () async {
    apiProbe.reachable = false;
    await service.refreshStatus(reason: 'test');

    final events = <bool>[];
    final sub = service.onConnectivityChanged.listen(events.add);

    apiProbe.reachable = true;
    await service.refreshStatus(reason: 'test_recovery');

    await Future<void>.delayed(Duration.zero);
    expect(events, contains(true));

    await sub.cancel();
  });

  test('transient internet probe failure does not block when API reachable',
      () async {
    internet.hasAccess = false;
    apiProbe.reachable = true;

    final snapshot = await service.refreshStatus(reason: 'windows_case');

    expect(snapshot.level, ConnectivityLevel.online);
    expect(snapshot.canSync, isTrue);
  });
}
