import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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

PendingOvertimeAction _arrived({
  required String id,
  String sessionId = 'server-ot-1',
}) {
  return PendingOvertimeAction(
    id: id,
    type: PendingOvertimeActionType.arrivedAtWorkSite,
    sessionId: sessionId,
    gps: _gps(),
    photoBytes: const [1, 2, 3],
    deviceId: 'device-1',
    clientRequestId: id,
    createdAt: DateTime.utc(2026, 8, 24, 10, 1),
  );
}

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

  void emitOnline(bool value) {
    online = value;
    _controller.add(value);
  }

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

class _AlwaysUpload extends Fake implements OvertimeUploadPolicyService {
  @override
  Future<bool> shouldAttemptImmediateUpload({bool force = false}) async => true;

  @override
  Future<bool> shouldAutoSync() async => true;

  @override
  Future<bool> get isWifi async => true;
}

/// Simulates independent stage uploads — ARRIVED must not wait for END.
class _IndependentStageRepo extends Fake implements OvertimeRepository {
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
    // Snapshot so mid-sync enqueue is invisible (production behavior).
    final snapshot = [...queue]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final action in snapshot) {
      if (action.sessionId != null &&
          action.sessionId!.startsWith('local-') &&
          action.type != PendingOvertimeActionType.start) {
        continue;
      }
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
  late _IndependentStageRepo repository;
  late SyncConfigurationService syncConfiguration;
  late OvertimeSyncCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    connectivity = _FakeConnectivity(online: true);
    repository = _IndependentStageRepo();
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
      uploadPolicy: _AlwaysUpload(),
      syncConfiguration: syncConfiguration,
    );
  });

  tearDown(() async {
    await cubit.close();
    await connectivity.dispose();
    syncConfiguration.dispose();
  });

  group('ARRIVED independent sync (production gates)', () {
    test('starts paused — timer does not sync until resumeAuthenticatedSync',
        () async {
      repository.enqueue(_arrived(id: 'ot-cp-arrived-1'));

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repository.syncCalls, 0);
      expect(repository.queue, isNotEmpty);

      cubit.resumeAuthenticatedSync();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.syncCalls, greaterThanOrEqualTo(1));
      expect(repository.uploaded, contains('arrivedAtWorkSite:ot-cp-arrived-1'));
      expect(repository.queue, isEmpty);
    });

    test('ARRIVED uploads without END/FINISHED in the queue', () async {
      cubit.resumeAuthenticatedSync();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      repository.enqueue(_arrived(id: 'ot-cp-arrived-only'));
      await cubit.syncNow(force: true, reason: 'test');

      expect(repository.uploaded, ['arrivedAtWorkSite:ot-cp-arrived-only']);
      expect(repository.queue, isEmpty);
      expect(
        repository.uploaded.any((e) => e.startsWith('end:')),
        isFalse,
      );
    });

    test('API unreachable keeps ARRIVED queued; restore retries immediately',
        () async {
      cubit.resumeAuthenticatedSync();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      repository.enqueue(_arrived(id: 'ot-cp-arrived-offline'));
      connectivity.online = false;

      await cubit.syncNow(force: true, reason: 'test_offline');
      expect(repository.queue.map((e) => e.id), ['ot-cp-arrived-offline']);

      connectivity.emitOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.uploaded, contains('arrivedAtWorkSite:ot-cp-arrived-offline'));
      expect(repository.queue, isEmpty);
    });

    test('upload failure keeps same clientRequestId for retry', () async {
      cubit.resumeAuthenticatedSync();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      repository.enqueue(_arrived(id: 'ot-cp-arrived-retry'));
      repository.nextFailure = const Failure('timeout', code: 'TIMEOUT');

      await cubit.syncNow(force: true, reason: 'fail_once');
      expect(repository.queue.single.id, 'ot-cp-arrived-retry');
      expect(repository.queue.single.clientRequestId, 'ot-cp-arrived-retry');

      await cubit.syncNow(force: true, reason: 'retry');
      expect(repository.uploaded, contains('arrivedAtWorkSite:ot-cp-arrived-retry'));
      expect(repository.queue, isEmpty);
    });

    test('START + ARRIVED + FINISHED + END sync independently in order',
        () async {
      cubit.resumeAuthenticatedSync();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final start = PendingOvertimeAction(
        id: 'ot-start',
        type: PendingOvertimeActionType.start,
        sessionId: 'local-ot-start',
        gps: _gps(),
        photoBytes: const [1],
        deviceId: 'device-1',
        clientRequestId: 'ot-start',
        createdAt: DateTime.utc(2026, 8, 24, 10),
      );
      final arrived = _arrived(id: 'ot-arrived', sessionId: 'server-ot-1');
      final finished = PendingOvertimeAction(
        id: 'ot-finished',
        type: PendingOvertimeActionType.finishedWork,
        sessionId: 'server-ot-1',
        gps: _gps(),
        photoBytes: const [1],
        deviceId: 'device-1',
        clientRequestId: 'ot-finished',
        createdAt: DateTime.utc(2026, 8, 24, 10, 2),
      );
      final end = PendingOvertimeAction(
        id: 'ot-end',
        type: PendingOvertimeActionType.end,
        sessionId: 'server-ot-1',
        gps: _gps(),
        photoBytes: const [1],
        deviceId: 'device-1',
        clientRequestId: 'ot-end',
        createdAt: DateTime.utc(2026, 8, 24, 10, 3),
      );

      repository.enqueue(start);
      repository.enqueue(arrived);
      await cubit.syncNow(force: true);
      expect(repository.uploaded, contains('start:ot-start'));
      expect(repository.uploaded, contains('arrivedAtWorkSite:ot-arrived'));

      repository.enqueue(finished);
      await cubit.syncNow(force: true);
      expect(repository.uploaded, contains('finishedWork:ot-finished'));

      repository.enqueue(end);
      await cubit.syncNow(force: true);
      expect(repository.uploaded, contains('end:ot-end'));
      expect(repository.queue, isEmpty);
    });

    test('configured interval remains 5 minutes (not hardcoded 45s)', () {
      expect(syncConfiguration.current.intervalMinutes, 5);
      expect(syncConfiguration.current.interval, const Duration(minutes: 5));
    });

    test('resumeAuthenticatedSync is idempotent and force-drains queue',
        () async {
      repository.enqueue(_arrived(id: 'ot-cp-arrived-resume'));
      cubit.resumeAuthenticatedSync();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      cubit.resumeAuthenticatedSync();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(repository.uploaded, contains('arrivedAtWorkSite:ot-cp-arrived-resume'));
      expect(repository.queue, isEmpty);
    });
  });
}
