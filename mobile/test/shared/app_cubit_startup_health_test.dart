import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/connectivity_status.dart';
import 'package:mobile/core/services/sync_configuration_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simulates a slow /health probe that must not block AppCubit.initialize.
class _SlowHealthConnectivity implements ConnectivityService {
  _SlowHealthConnectivity({
    required this.probeDelay,
    required this.probeResult,
  });

  final Duration probeDelay;
  final ConnectivitySnapshot probeResult;
  int refreshCalls = 0;
  final _statusController = StreamController<ConnectivitySnapshot>.broadcast();

  @override
  ConnectivitySnapshot get currentSnapshot => ConnectivitySnapshot.unknown;

  @override
  Future<bool> get isConnected async => probeResult.canSync;

  @override
  Future<List<ConnectivityResult>> get connectionTypes async =>
      const [ConnectivityResult.none];

  @override
  Stream<bool> get onConnectivityChanged =>
      onStatusChanged.map((s) => s.canSync);

  @override
  Stream<ConnectivitySnapshot> get onStatusChanged => _statusController.stream;

  @override
  Future<ConnectivitySnapshot> refreshStatus({
    String reason = 'manual',
    bool forceApiProbe = false,
  }) async {
    refreshCalls++;
    await Future<void>.delayed(probeDelay);
    _statusController.add(probeResult);
    return probeResult;
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
  }

  @override
  void invalidateCachedProbe({String reason = 'invalidate'}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppCubit startup health deferral', () {
    test('initialize becomes ready without waiting for slow /health', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences =
          PreferencesService(await SharedPreferences.getInstance());
      final syncConfiguration = SyncConfigurationService(preferences);
      await syncConfiguration.load();

      final connectivity = _SlowHealthConnectivity(
        probeDelay: const Duration(seconds: 3),
        probeResult: const ConnectivitySnapshot(
          level: ConnectivityLevel.online,
          networkAvailable: true,
          networkType: 'wifi',
          internetReachable: true,
          apiReachable: true,
        ),
      );

      final cubit = AppCubit(connectivity, preferences, syncConfiguration);
      final sw = Stopwatch()..start();
      await cubit.initialize();
      sw.stop();

      expect(cubit.state.startupStatus, AppStartupStatus.ready);
      // Must not wait for the 3s probe (allow small scheduling slack).
      expect(sw.elapsedMilliseconds, lessThan(1500));
      // Until probe finishes, unknown snapshot is not treated as online.
      expect(cubit.state.isOnline, isFalse);
      expect(cubit.state.connectivity.level, ConnectivityLevel.unknown);
      expect(connectivity.refreshCalls, 1);

      await Future<void>.delayed(const Duration(seconds: 4));
      expect(cubit.state.isOnline, isTrue);
      expect(cubit.state.connectivity.apiReachable, isTrue);

      await cubit.close();
      await connectivity.dispose();
    });

    test('failed health probe stays offline (never flipped to online)', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences =
          PreferencesService(await SharedPreferences.getInstance());
      final syncConfiguration = SyncConfigurationService(preferences);
      await syncConfiguration.load();

      final connectivity = _SlowHealthConnectivity(
        probeDelay: const Duration(milliseconds: 50),
        probeResult: const ConnectivitySnapshot(
          level: ConnectivityLevel.apiUnavailable,
          networkAvailable: true,
          networkType: 'wifi',
          internetReachable: true,
        ),
      );

      final cubit = AppCubit(connectivity, preferences, syncConfiguration);
      await cubit.initialize();
      expect(cubit.state.isOnline, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(cubit.state.isOnline, isFalse);
      expect(cubit.state.connectivity.apiReachable, isFalse);
      expect(cubit.state.connectivity.level, ConnectivityLevel.apiUnavailable);

      await cubit.close();
      await connectivity.dispose();
    });

    test('each initialize schedules one deferred refresh', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences =
          PreferencesService(await SharedPreferences.getInstance());
      final syncConfiguration = SyncConfigurationService(preferences);
      await syncConfiguration.load();

      final connectivity = _SlowHealthConnectivity(
        probeDelay: Duration.zero,
        probeResult: ConnectivitySnapshot.unknown,
      );

      final cubit = AppCubit(connectivity, preferences, syncConfiguration);
      await cubit.initialize();
      await cubit.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(connectivity.refreshCalls, 2);

      await cubit.close();
      await connectivity.dispose();
    });
  });
}
