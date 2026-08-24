import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/connectivity_status.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/services/sync_configuration_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/data/trace/overtime_offline_trace.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/services/overtime_upload_policy_service.dart';
import 'package:mobile/features/overtime/domain/usecases/sync_pending_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';

GpsSnapshot _gps([DateTime? at]) => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 8,
      recordedAt: at ?? DateTime.utc(2026, 8, 8, 12),
      provider: 'gps',
    );

PendingOvertimeAction _action({
  required String id,
  required PendingOvertimeActionType type,
  String sessionId = 'server-ot-1',
  String? lastError,
}) {
  return PendingOvertimeAction(
    id: id,
    type: type,
    sessionId: sessionId,
    gps: _gps(),
    photoBytes: const [1, 2, 3],
    deviceId: 'device-1',
    clientRequestId: id,
    createdAt: DateTime.utc(2026, 8, 8, 12),
    lastError: lastError,
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
  Future<List<ConnectivityResult>> get connectionTypes async => online
      ? const [ConnectivityResult.wifi]
      : const [ConnectivityResult.none];

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
}

/// Controllable queue + sync for scheduler regression tests.
class _SchedulerFakeRepo extends Fake implements OvertimeRepository {
  final List<PendingOvertimeAction> queue = [];
  final List<String> syncLog = [];
  final List<String> postLog = [];

  /// When non-null, the next [syncPendingActions] waits on this before draining.
  Completer<void>? blockSync;

  /// Fail the next sync cycle with this result (then clear).
  Result<int>? nextSyncFailure;

  /// If true, finishedWork items are treated as already on server (reconcile).
  bool serverHasFinishedWork = false;

  int syncCallCount = 0;

  void enqueue(PendingOvertimeAction action) {
    queue.removeWhere((e) => e.id == action.id);
    queue.add(action);
    OvertimeOfflineTrace.step(
      'ENQUEUE',
      status: 'success',
      objectId: action.id,
      detail: 'type=${action.type.name}',
      queueLength: queue.length,
    );
  }

  @override
  Future<List<PendingOvertimeAction>> getPendingActions() async =>
      List.unmodifiable(queue);

  @override
  Future<Result<int>> syncPendingActions() async {
    syncCallCount += 1;
    syncLog.add('sync#$syncCallCount');

    // Match production: snapshot BEFORE any await so mid-sync enqueues are
    // invisible to this cycle and require a scheduler follow-up.
    final snapshot = [...queue]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final gate = blockSync;
    if (gate != null) {
      await gate.future;
    }

    if (nextSyncFailure != null) {
      final failure = nextSyncFailure!;
      nextSyncFailure = null;
      return failure;
    }

    var synced = 0;

    for (final action in snapshot) {
      if (action.lastError != null &&
          action.lastError!.isNotEmpty &&
          !(action.type == PendingOvertimeActionType.finishedWork &&
              serverHasFinishedWork)) {
        // Simulate order-blocking hard failure — leave pending, stop.
        // Exception: reconcile path still drains confirmed finishedWork.
        syncLog.add('blocked:${action.id}');
        return Success(synced);
      }

      if (action.type == PendingOvertimeActionType.finishedWork) {
        if (serverHasFinishedWork) {
          queue.removeWhere((e) => e.id == action.id);
          synced += 1;
          syncLog.add('reconcile:${action.id}');
          continue;
        }
        postLog.add('POST finishedWork ${action.id}');
        queue.removeWhere((e) => e.id == action.id);
        synced += 1;
        continue;
      }

      postLog.add('POST ${action.type.name} ${action.id}');
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
  late _SchedulerFakeRepo repository;
  late SyncConfigurationService syncConfiguration;
  late OvertimeSyncCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    connectivity = _FakeConnectivity(online: true);
    repository = _SchedulerFakeRepo();
    syncConfiguration = SyncConfigurationService(
      PreferencesService(await SharedPreferences.getInstance()),
    );
    await syncConfiguration.load();
    cubit = OvertimeSyncCubit(
      syncUseCase: SyncPendingOvertimeUseCase(repository),
      repository: repository,
      connectivity: connectivity,
      gpsAddressSync: _FakeGpsAddressSync(),
      uploadPolicy: _AlwaysUpload(),
      syncConfiguration: syncConfiguration,
    );
    // Production starts paused until authenticated resume.
    cubit.resumeAuthenticatedSync();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    repository.syncCallCount = 0;
    repository.syncLog.clear();
    repository.postLog.clear();
  });

  tearDown(() async {
    await cubit.close();
    await connectivity.dispose();
    syncConfiguration.dispose();
  });

  group('OvertimeSyncCubit coalescing / follow-up', () {
    test('1) enqueue while idle → sync starts normally', () async {
      repository.enqueue(
        _action(id: 'fw-1', type: PendingOvertimeActionType.finishedWork),
      );

      await cubit.syncNow(force: true);

      expect(repository.syncCallCount, greaterThanOrEqualTo(1));
      expect(repository.postLog, contains('POST finishedWork fw-1'));
      expect(repository.queue, isEmpty);
      expect(cubit.state.pendingCount, 0);
    });

    test(
      '2) enqueue Finish Work while sync running → request coalesced, not lost',
      () async {
        final gate = Completer<void>();
        repository.blockSync = gate;
        repository.enqueue(
          _action(id: 'arrived-1', type: PendingOvertimeActionType.arrivedAtWorkSite),
        );

        // Start sync — blocks inside syncPendingActions.
        final first = cubit.syncNow(force: true);
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.status, OvertimeSyncStatus.syncing);

        // Finish Work enqueued + sync requested while first cycle runs.
        repository.enqueue(
          _action(id: 'fw-mid', type: PendingOvertimeActionType.finishedWork),
        );
        await cubit.syncNow(force: true); // must coalesce, not discard

        // First snapshot still only had arrived — release it.
        repository.blockSync = null;
        gate.complete();
        await first;
        // Allow microtask follow-up / loop continuation.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(
          repository.postLog.any((e) => e.contains('fw-mid')),
          isTrue,
          reason: 'Finish Work enqueued mid-sync must be POSTed in follow-up',
        );
        expect(repository.queue.where((e) => e.id == 'fw-mid'), isEmpty);
      },
    );

    test(
      '3) current sync finishes → queued Finish Work automatically processed',
      () async {
        final gate = Completer<void>();
        repository.blockSync = gate;
        repository.enqueue(
          _action(id: 'start-like', type: PendingOvertimeActionType.arrivedAtWorkSite),
        );

        final running = cubit.syncNow(force: true);
        await Future<void>.delayed(Duration.zero);

        repository.enqueue(
          _action(id: 'fw-auto', type: PendingOvertimeActionType.finishedWork),
        );
        unawaited(cubit.syncNow(force: true));

        repository.blockSync = null;
        gate.complete();
        await running;
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(repository.postLog, contains('POST finishedWork fw-auto'));
        expect(repository.queue, isEmpty);
      },
    );

    test(
      '4) multiple actions enqueued during one sync → one follow-up drains in order',
      () async {
        final gate = Completer<void>();
        repository.blockSync = gate;
        repository.enqueue(
          _action(
            id: 'a0',
            type: PendingOvertimeActionType.arrivedAtWorkSite,
          ),
        );

        final running = cubit.syncNow(force: true);
        await Future<void>.delayed(Duration.zero);

        repository.enqueue(
          _action(id: 'fw-a', type: PendingOvertimeActionType.finishedWork),
        );
        repository.enqueue(
          _action(id: 'end-a', type: PendingOvertimeActionType.end),
        );
        // Multiple sync kicks while busy — still one coalesced follow-up.
        unawaited(cubit.syncNow(force: true));
        unawaited(cubit.syncNow(force: true));
        unawaited(cubit.syncNow(force: true));

        repository.blockSync = null;
        gate.complete();
        await running;
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(repository.postLog, contains('POST finishedWork fw-a'));
        expect(repository.postLog, contains('POST end end-a'));
        expect(repository.queue, isEmpty);
        // First cycle + at least one follow-up — not one sync per kick.
        expect(repository.syncCallCount, lessThan(5));
        expect(repository.syncCallCount, greaterThanOrEqualTo(2));
      },
    );

    test(
      '5) legitimate API failure → remains pending, no infinite retries',
      () async {
        repository.enqueue(
          _action(
            id: 'fw-fail',
            type: PendingOvertimeActionType.finishedWork,
            lastError: 'CONFLICT',
          ),
        );

        await cubit.syncNow(force: true);
        await Future<void>.delayed(Duration.zero);
        final callsAfterFirst = repository.syncCallCount;
        expect(callsAfterFirst, 1);
        expect(repository.queue, isNotEmpty);
        expect(repository.postLog, isEmpty);

        // Idle re-entry without new enqueue / progress must not spin.
        await cubit.syncNow(force: true);
        await Future<void>.delayed(Duration.zero);
        expect(repository.syncCallCount, lessThanOrEqualTo(callsAfterFirst + 1));
        expect(repository.queue, isNotEmpty);
      },
    );

    test(
      '6) server already contains Finished Work → reconciliation removes stale pending',
      () async {
        repository.serverHasFinishedWork = true;
        repository.enqueue(
          _action(
            id: 'fw-stale',
            type: PendingOvertimeActionType.finishedWork,
            lastError: 'CONFLICT',
          ),
        );

        await cubit.syncNow(force: true);

        expect(repository.queue, isEmpty);
        expect(repository.syncLog, contains('reconcile:fw-stale'));
        expect(
          repository.postLog.where((e) => e.contains('fw-stale')),
          isEmpty,
          reason: 'reconcile must not POST a duplicate finishedWork',
        );
      },
    );

    test(
      '7) offline enqueue → pending until connectivity returns',
      () async {
        connectivity.online = false;
        repository.enqueue(
          _action(id: 'fw-off', type: PendingOvertimeActionType.finishedWork),
        );

        await cubit.syncNow(force: true);
        expect(repository.syncCallCount, 0);
        expect(repository.queue, isNotEmpty);

        connectivity.emitOnline(true);
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(repository.postLog, contains('POST finishedWork fw-off'));
        expect(repository.queue, isEmpty);
      },
    );

    test(
      'exact production scenario: sync running → Finish Work enqueued → '
      'already syncing → follow-up POSTs finishedWork → queue drained',
      () async {
        final gate = Completer<void>();
        repository.blockSync = gate;

        // Sync already running (e.g. reconciling Arrived).
        repository.enqueue(
          _action(
            id: 'arrived-running',
            type: PendingOvertimeActionType.arrivedAtWorkSite,
          ),
        );
        final active = cubit.syncNow(force: true);
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.status, OvertimeSyncStatus.syncing);

        // Technician presses Finish Work — local enqueue succeeds.
        repository.enqueue(
          _action(
            id: 'fw-prod',
            type: PendingOvertimeActionType.finishedWork,
          ),
        );
        expect(repository.queue.length, 2);

        // Kick sync → must log coalesced follow-up, not drop.
        await cubit.syncNow(force: true);

        // Active cycle finishes without seeing fw-prod (snapshot).
        repository.blockSync = null;
        gate.complete();
        await active;
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          repository.postLog,
          contains('POST finishedWork fw-prod'),
          reason: 'follow-up sync must POST finishedWork after active sync ends',
        );
        expect(repository.queue, isEmpty);
        expect(
          repository.postLog.any((e) => e.contains('arrived-running')),
          isTrue,
        );
      },
    );
  });
}
