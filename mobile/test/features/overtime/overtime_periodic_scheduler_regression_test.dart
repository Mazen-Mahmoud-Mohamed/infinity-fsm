import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/connectivity_status.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/services/sync_configuration_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/services/overtime_upload_policy_service.dart';
import 'package:mobile/features/overtime/domain/usecases/sync_pending_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

GpsSnapshot _gps() => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.7,
      accuracy: 8,
      recordedAt: DateTime.utc(2026, 8, 24, 10),
      provider: 'gps',
    );

PendingOvertimeAction _arrived(String id) => PendingOvertimeAction(
      id: id,
      type: PendingOvertimeActionType.arrivedAtWorkSite,
      sessionId: 'server-ot-1',
      gps: _gps(),
      photoBytes: const [1, 2, 3],
      deviceId: 'device-1',
      clientRequestId: id,
      createdAt: DateTime.utc(2026, 8, 24, 10, 1),
    );

class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity({this.online = true});

  bool online;
  final _controller = StreamController<bool>.broadcast();

  ConnectivitySnapshot get _snapshot => online
      ? const ConnectivitySnapshot(
          level: ConnectivityLevel.online,
          networkAvailable: true,
          networkType: 'wifi',
          internetReachable: true,
          apiReachable: true,
        )
      : const ConnectivitySnapshot(
          level: ConnectivityLevel.apiUnavailable,
          networkAvailable: true,
          networkType: 'wifi',
          internetReachable: true,
          apiReachable: false,
          reason: 'timeout',
        );

  @override
  ConnectivitySnapshot get currentSnapshot => _snapshot;

  @override
  Future<bool> get isConnected async => online;

  @override
  Future<List<ConnectivityResult>> get connectionTypes async =>
      const [ConnectivityResult.wifi];

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Stream<ConnectivitySnapshot> get onStatusChanged => const Stream.empty();

  @override
  Future<ConnectivitySnapshot> refreshStatus({
    String reason = 'manual',
    bool forceApiProbe = false,
  }) async =>
      _snapshot;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  void invalidateCachedProbe({String reason = 'invalidate'}) {}
}

class _FakeGpsAddressSync extends Fake implements GpsAddressSyncService {
  @override
  Future<void> enqueueOvertime({
    required String sessionId,
    required String point,
    required GpsSnapshot gps,
  }) async {}

  @override
  Future<void> processQueue() async {}
}

/// Blocks auto-sync policy — reproduces production manual/wifi gates.
class _ManualUploadPolicy extends Fake implements OvertimeUploadPolicyService {
  @override
  Future<bool> shouldAttemptImmediateUpload({bool force = false}) async =>
      false;

  @override
  Future<bool> shouldAutoSync() async => false;

  @override
  Future<bool> get isWifi async => true;
}

class _QueueRepo extends Fake implements OvertimeRepository {
  final List<PendingOvertimeAction> queue = [];
  final List<String> uploaded = [];
  var syncCalls = 0;
  Result<int>? nextFailure;

  void enqueue(PendingOvertimeAction action) {
    queue.removeWhere((e) => e.id == action.id);
    queue.add(action);
  }

  @override
  Future<List<PendingOvertimeAction>> getPendingActions() async =>
      List.unmodifiable(queue);

  @override
  Future<Result<int>> syncPendingActions() async {
    syncCalls += 1;
    if (nextFailure != null) {
      final failure = nextFailure!;
      nextFailure = null;
      return failure;
    }
    var synced = 0;
    final snapshot = [...queue];
    for (final action in snapshot) {
      uploaded.add('${action.type.name}:${action.id}');
      queue.removeWhere((e) => e.id == action.id);
      synced += 1;
    }
    return Success(synced);
  }

  @override
  Future<Result<OvertimeSession?>> getRunningSession() async {
    return const Success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeConnectivity connectivity;
  late _QueueRepo repository;
  late SyncConfigurationService syncConfiguration;
  late OvertimeSyncCubit cubit;

  Future<void> buildCubit({
    Duration? periodicOverride,
    OvertimeUploadPolicyService? policy,
  }) async {
    SharedPreferences.setMockInitialValues({});
    connectivity = _FakeConnectivity(online: true);
    repository = _QueueRepo();
    syncConfiguration = SyncConfigurationService(
      PreferencesService(await SharedPreferences.getInstance()),
    );
    await syncConfiguration.load();
    await syncConfiguration.update(intervalMinutes: 5, autoSync: true);

    cubit = OvertimeSyncCubit(
      syncUseCase: SyncPendingOvertimeUseCase(repository),
      repository: repository,
      connectivity: connectivity,
      gpsAddressSync: _FakeGpsAddressSync(),
      uploadPolicy: policy ?? _ManualUploadPolicy(),
      syncConfiguration: syncConfiguration,
      periodicIntervalOverride: periodicOverride,
    );
  }

  tearDown(() async {
    await cubit.close();
    await connectivity.dispose();
    syncConfiguration.dispose();
  });

  group('periodic scheduler — ARRIVED without app restart', () {
    test(
      'periodic tick uploads pending ARRIVED without calling resume again',
      () {
        fakeAsync((async) {
          var built = false;
          buildCubit(periodicOverride: const Duration(minutes: 5)).then((_) {
            built = true;
          });
          async.flushMicrotasks();
          expect(built, isTrue);

          cubit.resumeAuthenticatedSync();
          async.flushMicrotasks();
          // Login force-sync with empty queue.
          expect(repository.syncCalls, greaterThanOrEqualTo(0));
          repository.syncCalls = 0;
          repository.uploaded.clear();

          // Enqueue ARRIVED AFTER login — do NOT call resume again.
          repository.enqueue(_arrived('ot-cp-arrived-periodic'));
          expect(cubit.isPeriodicTimerActive, isTrue);

          // Before interval: no timer-driven sync yet.
          async.elapse(const Duration(minutes: 4, seconds: 50));
          async.flushMicrotasks();
          expect(
            repository.uploaded,
            isEmpty,
            reason: 'must wait for full periodic interval',
          );

          // Periodic tick at 5 minutes.
          async.elapse(const Duration(seconds: 15));
          async.flushMicrotasks();

          expect(repository.syncCalls, greaterThanOrEqualTo(1));
          expect(
            repository.uploaded,
            contains('arrivedAtWorkSite:ot-cp-arrived-periodic'),
          );
          expect(repository.queue, isEmpty);
        });
      },
    );

    test('repeated resume does not reset countdown / create duplicate timers',
        () {
      fakeAsync((async) {
        buildCubit(periodicOverride: const Duration(minutes: 5));
        async.flushMicrotasks();

        cubit.resumeAuthenticatedSync();
        async.flushMicrotasks();
        repository.syncCalls = 0;
        repository.uploaded.clear();

        // Almost at the first tick, then spam resume (bootstrap / auth).
        async.elapse(const Duration(minutes: 4, seconds: 50));
        cubit.resumeAuthenticatedSync();
        cubit.resumeAuthenticatedSync();
        async.flushMicrotasks();

        // Enqueue AFTER resume spam so force:login does not drain it.
        repository.enqueue(_arrived('ot-cp-arrived-keep'));

        // Original timer should still fire ~10s later (5m from first arm).
        async.elapse(const Duration(seconds: 15));
        async.flushMicrotasks();

        expect(
          repository.uploaded,
          contains('arrivedAtWorkSite:ot-cp-arrived-keep'),
          reason: 'countdown must survive repeated resumeAuthenticatedSync',
        );
      });
    });

    test('identical sync-config emissions do not reset the timer', () {
      fakeAsync((async) {
        buildCubit(periodicOverride: const Duration(minutes: 5));
        async.flushMicrotasks();

        cubit.resumeAuthenticatedSync();
        async.flushMicrotasks();
        repository.syncCalls = 0;
        repository.enqueue(_arrived('ot-cp-arrived-config'));

        async.elapse(const Duration(minutes: 4, seconds: 50));
        // Re-emit the same configuration (would previously cancel+recreate).
        unawaited(
          syncConfiguration.update(
            autoSync: true,
            wifiOnlySync: false,
            intervalMinutes: 5,
          ),
        );
        async.flushMicrotasks();

        expect(repository.uploaded, isEmpty);

        async.elapse(const Duration(seconds: 15));
        async.flushMicrotasks();

        expect(
          repository.uploaded,
          contains('arrivedAtWorkSite:ot-cp-arrived-config'),
        );
      });
    });

    test('timer drains ARRIVED even when upload policy shouldAutoSync=false',
        () {
      fakeAsync((async) {
        // Manual policy: capture queues, but Sync Settings autoSync must still
        // drain via the periodic scheduler (restart force already did).
        buildCubit(
          periodicOverride: const Duration(seconds: 10),
          policy: _ManualUploadPolicy(),
        );
        async.flushMicrotasks();

        cubit.resumeAuthenticatedSync();
        async.flushMicrotasks();
        repository.syncCalls = 0;
        repository.uploaded.clear();
        repository.enqueue(_arrived('ot-cp-arrived-policy'));

        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        expect(
          repository.uploaded,
          contains('arrivedAtWorkSite:ot-cp-arrived-policy'),
        );
        expect(repository.queue, isEmpty);
      });
    });

    test('pause cancels timer; resume creates exactly one active timer', () {
      fakeAsync((async) {
        buildCubit(periodicOverride: const Duration(minutes: 5));
        async.flushMicrotasks();

        cubit.resumeAuthenticatedSync();
        async.flushMicrotasks();
        expect(cubit.isPeriodicTimerActive, isTrue);

        cubit.pauseAuthenticatedSync();
        expect(cubit.isPeriodicTimerActive, isFalse);

        cubit.resumeAuthenticatedSync();
        async.flushMicrotasks();
        expect(cubit.isPeriodicTimerActive, isTrue);

        cubit.resumeAuthenticatedSync();
        async.flushMicrotasks();
        expect(cubit.isPeriodicTimerActive, isTrue);
      });
    });

    test('sync lock releases after failure so next tick retries', () {
      fakeAsync((async) {
        buildCubit(periodicOverride: const Duration(seconds: 5));
        async.flushMicrotasks();

        cubit.resumeAuthenticatedSync();
        async.flushMicrotasks();
        repository.syncCalls = 0;
        repository.uploaded.clear();
        repository.enqueue(_arrived('ot-cp-arrived-retry'));
        repository.nextFailure = const Failure('timeout', code: 'TIMEOUT');

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(repository.queue, isNotEmpty);
        expect(repository.uploaded, isEmpty);

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(
          repository.uploaded,
          contains('arrivedAtWorkSite:ot-cp-arrived-retry'),
        );
        expect(repository.queue, isEmpty);
      });
    });

    test('production interval remains Duration(minutes: 5) when configured',
        () async {
      await buildCubit();
      expect(syncConfiguration.current.intervalMinutes, 5);
      expect(syncConfiguration.current.interval, const Duration(minutes: 5));
      cubit.resumeAuthenticatedSync();
      expect(cubit.isPeriodicTimerActive, isTrue);
    });
  });
}
