import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/connectivity_status.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:mobile/features/overtime/data/models/overtime_session_model.dart';
import 'package:mobile/features/overtime/data/models/pending_overtime_action_model.dart';
import 'package:mobile/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/domain/services/overtime_upload_policy_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

/// Regression: server already confirmed a stage while mobile still has a
/// failed/pending local action (timeout after success / CONFLICT retry).
class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity({this.online = true});
  bool online;

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
  Stream<bool> get onConnectivityChanged => Stream<bool>.value(online);

  @override
  Stream<ConnectivitySnapshot> get onStatusChanged => const Stream.empty();

  @override
  Future<ConnectivitySnapshot> refreshStatus({
    String reason = 'manual',
    bool forceApiProbe = false,
  }) async =>
      _snapshot;

  @override
  Future<void> dispose() async {}

  @override
  void invalidateCachedProbe({String reason = 'invalidate'}) {}
}

class _FakeAddressResolver extends Fake implements AddressResolverService {
  @override
  Future<String> resolve(GpsSnapshot gps) async => 'Reconcile Address';
}

class _FakeGpsAddressSync extends Fake implements GpsAddressSyncService {
  @override
  Future<void> enqueueOvertime({
    required String sessionId,
    required String point,
    required GpsSnapshot gps,
  }) async {}
}

class _AlwaysUploadPolicy extends Fake implements OvertimeUploadPolicyService {
  @override
  Future<bool> shouldAttemptImmediateUpload({bool force = false}) async => true;

  @override
  Future<bool> shouldAutoSync() async => true;
}

class _ReconcileRemote extends Fake implements OvertimeRemoteDataSource {
  final Map<String, OvertimeSessionModel> mongo = {};
  var arrivedCalls = 0;
  var finishedCalls = 0;
  /// When true, arrived POST throws CONFLICT (stage already on server).
  bool conflictOnArrived = false;
  /// When true, first arrived call "times out" (client never sees success).
  bool timeoutOnceOnArrived = false;
  var _timedOutOnce = false;

  @override
  Future<OvertimeSessionModel?> getRunning() async {
    for (final doc in mongo.values) {
      if (doc.status == OvertimeStatus.running) return doc;
    }
    return null;
  }

  @override
  Future<OvertimeSessionModel> getById(String id) async {
    final doc = mongo[id];
    if (doc == null) {
      throw ApiException(message: 'NOT_FOUND', statusCode: 404, code: 'NOT_FOUND');
    }
    return doc;
  }

  @override
  Future<OvertimeSessionModel> recordArrivedAtWorkSite({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    String? voiceFilename,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    DateTime? checkpointAt,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    arrivedCalls += 1;
    if (timeoutOnceOnArrived && !_timedOutOnce) {
      _timedOutOnce = true;
      // Simulate: server already applied the stage, but client times out.
      _seedArrived(
        sessionId: sessionId,
        gps: gps,
        deviceId: deviceId,
        address: address,
        clientRequestId: clientRequestId,
        checkpointAt: checkpointAt,
        notes: notes,
        batteryLevel: batteryLevel,
        networkStatus: networkStatus,
      );
      throw ApiException(
        message: 'errorRequestTimeout',
        statusCode: null,
        code: 'TIMEOUT',
      );
    }

    final existing = mongo[sessionId];
    if (existing == null) {
      throw StateError('missing session');
    }
    final existingCp = existing.checkpoints?.arrivedAtWorkSite;
    if (existingCp != null) {
      if (existingCp.clientRequestId == clientRequestId) {
        return existing; // idempotent replay
      }
      if (conflictOnArrived || existingCp.clientRequestId != clientRequestId) {
        throw ApiException(
          message:
              'Checkpoint arrivedAtWorkSite is already completed and cannot be repeated',
          statusCode: 409,
          code: 'CONFLICT',
        );
      }
    }

    return _seedArrived(
      sessionId: sessionId,
      gps: gps,
      deviceId: deviceId,
      address: address,
      clientRequestId: clientRequestId,
      checkpointAt: checkpointAt,
      notes: notes,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
    );
  }

  @override
  Future<OvertimeSessionModel> recordFinishedWork({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    String? voiceFilename,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    DateTime? checkpointAt,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    finishedCalls += 1;
    final existing = mongo[sessionId];
    if (existing == null) {
      throw StateError('missing session');
    }
    if (existing.checkpoints?.arrivedAtWorkSite == null) {
      throw ApiException(
        message: 'Next required checkpoint is arrivedAtWorkSite',
        statusCode: 409,
        code: 'CONFLICT',
      );
    }
    final at = checkpointAt ?? gps.recordedAt;
    final cp = OvertimeCheckpoint(
      at: at,
      gps: gps,
      photoUrl: 'https://example.com/finished.jpg',
      address: address,
      deviceId: deviceId,
      clientRequestId: clientRequestId,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
      notes: notes,
    );
    final checkpoints =
        (existing.checkpoints ?? const OvertimeCheckpoints()).copyWith(
      finishedWork: cp,
    );
    final updated = _copy(
      existing,
      checkpoints: checkpoints,
      nextCheckpoint: checkpoints.nextStage,
    );
    mongo[sessionId] = updated;
    return updated;
  }

  OvertimeSessionModel _seedArrived({
    required String sessionId,
    required GpsSnapshot gps,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    DateTime? checkpointAt,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) {
    final existing = mongo[sessionId]!;
    final at = checkpointAt ?? gps.recordedAt;
    final cp = OvertimeCheckpoint(
      at: at,
      gps: gps,
      photoUrl: 'https://example.com/arrived.jpg',
      address: address,
      deviceId: deviceId,
      clientRequestId: clientRequestId,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
      notes: notes,
    );
    final checkpoints =
        (existing.checkpoints ?? const OvertimeCheckpoints()).copyWith(
      arrivedAtWorkSite: cp,
    );
    final updated = _copy(
      existing,
      checkpoints: checkpoints,
      nextCheckpoint: OvertimeCheckpointStage.finishedWork,
    );
    mongo[sessionId] = updated;
    return updated;
  }

  OvertimeSessionModel _copy(
    OvertimeSessionModel existing, {
    OvertimeCheckpoints? checkpoints,
    OvertimeCheckpointStage? nextCheckpoint,
  }) {
    return OvertimeSessionModel(
      id: existing.id,
      companyId: existing.companyId,
      userId: existing.userId,
      type: existing.type,
      status: existing.status,
      startAt: existing.startAt,
      startGps: existing.startGps,
      startDeviceId: existing.startDeviceId,
      startAddress: existing.startAddress,
      startPhotoUrl: existing.startPhotoUrl,
      createdAt: existing.createdAt,
      workflowVersion: OvertimeWorkflowVersion.v2,
      checkpoints: checkpoints ?? existing.checkpoints,
      nextCheckpoint: nextCheckpoint ?? existing.nextCheckpoint,
    );
  }

  void seedRunningWithStart({required String clientRequestId}) {
    final at = DateTime.utc(2026, 8, 8, 10);
    final gps = _gps(at);
    final session = OvertimeSessionModel(
      id: 'server-ot-1',
      companyId: 'company-1',
      userId: 'user-1',
      type: OvertimeType.normal,
      status: OvertimeStatus.running,
      startAt: at,
      startGps: gps,
      startDeviceId: 'device-1',
      startAddress: 'Start',
      startPhotoUrl: 'https://example.com/start.jpg',
      createdAt: at,
      workflowVersion: OvertimeWorkflowVersion.v2,
      checkpoints: OvertimeCheckpoints(
        startJourney: OvertimeCheckpoint(
          at: at,
          gps: gps,
          photoUrl: 'https://example.com/start.jpg',
          address: 'Start',
          deviceId: 'device-1',
          clientRequestId: clientRequestId,
        ),
      ),
      nextCheckpoint: OvertimeCheckpointStage.arrivedAtWorkSite,
    );
    mongo[session.id] = session;
  }
}

GpsSnapshot _gps(DateTime at) => GpsSnapshot(
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 8,
      recordedAt: at,
      provider: 'gps',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late PreferencesService preferences;
  late OvertimeLocalDataSource local;
  late _ReconcileRemote remote;
  late _FakeConnectivity connectivity;
  late OvertimeRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    preferences = PreferencesService(prefs);
    local = OvertimeLocalDataSource(preferences);
    remote = _ReconcileRemote();
    connectivity = _FakeConnectivity(online: true);
    repository = OvertimeRepositoryImpl(
      remote: remote,
      local: local,
      connectivity: connectivity,
      addressResolver: _FakeAddressResolver(),
      gpsAddressSync: _FakeGpsAddressSync(),
      uploadPolicy: _AlwaysUploadPolicy(),
    );
  });

  Future<void> seedLocalRunningFromServer() async {
    remote.seedRunningWithStart(clientRequestId: 'ot-start-1');
    final running = await repository.getRunningSession();
    expect(running, isA<Success<OvertimeSession?>>());
    expect(local.readRunningSession()?.id, 'server-ot-1');
  }

  PendingOvertimeActionModel pendingArrived({
    required String clientRequestId,
    String? lastError,
  }) {
    final at = DateTime.utc(2026, 8, 8, 11);
    return PendingOvertimeActionModel(
      id: clientRequestId,
      type: PendingOvertimeActionType.arrivedAtWorkSite,
      sessionId: 'server-ot-1',
      gps: _gps(at),
      photoBytes: List<int>.filled(64, 1),
      voiceBytes: const [],
      deviceId: 'device-1',
      clientRequestId: clientRequestId,
      address: 'Site',
      checkpointAt: at,
      createdAt: at,
      lastError: lastError,
      retryCount: lastError == null ? 0 : 2,
    );
  }

  group('overtime sync reconciliation', () {
    test(
      '1) server accepted arrived + mobile timeout → queue then reconcile clears Sync Failed',
      () async {
        await seedLocalRunningFromServer();
        remote.timeoutOnceOnArrived = true;

        final at = DateTime.utc(2026, 8, 8, 11);
        final result = await repository.recordCheckpoint(
          sessionId: 'server-ot-1',
          stage: OvertimeCheckpointStage.arrivedAtWorkSite,
          gps: _gps(at),
          photoBytes: List<int>.filled(32, 2),
          deviceId: 'device-1',
          address: 'Site',
          clientRequestId: 'ot-cp-arrived-A',
        );

        // TIMEOUT → queued offline path
        expect(result, isA<Success<OvertimeSession>>());
        expect(local.readQueue(), isNotEmpty);
        expect(
          remote.mongo['server-ot-1']!.checkpoints?.arrivedAtWorkSite,
          isNotNull,
          reason: 'server already has arrived after timed-out POST',
        );

        // Sync retries with same clientRequestId → idempotent success → dequeue
        final sync = await repository.syncPendingActions();
        expect(sync, isA<Success<int>>());
        expect(local.readQueue(), isEmpty);
        expect(
          local.readRunningSession()?.checkpoints?.arrivedAtWorkSite,
          isNotNull,
        );
        expect(
          local.readRunningSession()?.effectiveNextCheckpoint,
          OvertimeCheckpointStage.finishedWork,
        );
      },
    );

    test(
      '2) server has completed arrived + local action marked failed → getRunning clears pending',
      () async {
        await seedLocalRunningFromServer();
        // Server already has arrived (admin view).
        remote._seedArrived(
          sessionId: 'server-ot-1',
          gps: _gps(DateTime.utc(2026, 8, 8, 11)),
          deviceId: 'device-1',
          address: 'Site',
          clientRequestId: 'ot-cp-arrived-SERVER',
        );

        // Mobile still has a failed pending with a different clientRequestId.
        await local.enqueue(
          pendingArrived(
            clientRequestId: 'ot-cp-arrived-STALE',
            lastError: 'CONFLICT',
          ),
        );
        expect(local.readQueue(), hasLength(1));
        expect(local.readQueue().first.lastError, 'CONFLICT');

        final result = await repository.getRunningSession();
        expect(result, isA<Success<OvertimeSession?>>());
        expect(local.readQueue(), isEmpty, reason: 'reconcile must drain');
        expect(
          local.readRunningSession()?.checkpoints?.arrivedAtWorkSite,
          isNotNull,
        );
        expect(
          local.readRunningSession()?.effectiveNextCheckpoint,
          OvertimeCheckpointStage.finishedWork,
        );
      },
    );

    test(
      '3) retry after reconciliation continues to finished work (no stuck arrived)',
      () async {
        await seedLocalRunningFromServer();
        remote._seedArrived(
          sessionId: 'server-ot-1',
          gps: _gps(DateTime.utc(2026, 8, 8, 11)),
          deviceId: 'device-1',
          address: 'Site',
          clientRequestId: 'ot-cp-arrived-SERVER',
        );
        await local.enqueue(
          pendingArrived(
            clientRequestId: 'ot-cp-arrived-STALE',
            lastError: 'CONFLICT',
          ),
        );

        await repository.getRunningSession();
        expect(local.readQueue(), isEmpty);

        final finished = await repository.recordCheckpoint(
          sessionId: 'server-ot-1',
          stage: OvertimeCheckpointStage.finishedWork,
          gps: _gps(DateTime.utc(2026, 8, 8, 12)),
          photoBytes: List<int>.filled(32, 3),
          deviceId: 'device-1',
          address: 'Site',
          clientRequestId: 'ot-cp-finished-1',
        );
        expect(finished, isA<Success<OvertimeSession>>());
        expect(remote.finishedCalls, 1);
        expect(
          local.readRunningSession()?.checkpoints?.finishedWork,
          isNotNull,
        );
      },
    );

    test(
      '4) CONFLICT with different clientRequestId does not create duplicate arrived',
      () async {
        await seedLocalRunningFromServer();
        remote._seedArrived(
          sessionId: 'server-ot-1',
          gps: _gps(DateTime.utc(2026, 8, 8, 11)),
          deviceId: 'device-1',
          address: 'Site',
          clientRequestId: 'ot-cp-arrived-A',
        );
        remote.conflictOnArrived = true;

        await local.enqueue(
          pendingArrived(clientRequestId: 'ot-cp-arrived-B'),
        );

        final sync = await repository.syncPendingActions();
        expect(sync, isA<Success<int>>());
        expect(local.readQueue(), isEmpty, reason: 'CONFLICT reconciled');
        expect(remote.arrivedCalls, 1);
        expect(
          remote.mongo['server-ot-1']!.checkpoints?.arrivedAtWorkSite
              ?.clientRequestId,
          'ot-cp-arrived-A',
          reason: 'original server checkpoint retained — no duplicate',
        );
      },
    );

    test(
      '5) media/upload CONFLICT on arrived is independent of finished-work progression after reconcile',
      () async {
        await seedLocalRunningFromServer();
        // Arrived already on server with photo URL; local still has pending
        // with a large photo that would "fail" sync via CONFLICT.
        remote._seedArrived(
          sessionId: 'server-ot-1',
          gps: _gps(DateTime.utc(2026, 8, 8, 11)),
          deviceId: 'device-1',
          address: 'Site',
          clientRequestId: 'ot-cp-arrived-A',
        );
        await local.enqueue(
          pendingArrived(
            clientRequestId: 'ot-cp-arrived-VOICE-RETRY',
            lastError: 'CONFLICT',
          ),
        );

        await repository.syncPendingActions();
        expect(local.readQueue(), isEmpty);

        // Stage progression uses server state, not the abandoned media queue item.
        expect(
          local.readRunningSession()?.effectiveNextCheckpoint,
          OvertimeCheckpointStage.finishedWork,
        );
        final finished = await repository.recordCheckpoint(
          sessionId: 'server-ot-1',
          stage: OvertimeCheckpointStage.finishedWork,
          gps: _gps(DateTime.utc(2026, 8, 8, 13)),
          photoBytes: List<int>.filled(16, 9),
          deviceId: 'device-1',
          address: 'Site',
          clientRequestId: 'ot-cp-finished-media',
        );
        expect(finished, isA<Success<OvertimeSession>>());
        expect(
          remote.mongo['server-ot-1']!.checkpoints?.arrivedAtWorkSite?.photoUrl,
          isNotEmpty,
          reason: 'server arrived media preserved',
        );
      },
    );

    test(
      'getRunning must NOT clear pending when server has not confirmed the stage',
      () async {
        await seedLocalRunningFromServer();
        await local.enqueue(pendingArrived(clientRequestId: 'ot-cp-pending'));

        final before = local.readQueue().length;
        await repository.getRunningSession();
        expect(
          local.readQueue().length,
          before,
          reason:
              'legitimate offline pending must survive getRunning when stage absent on server',
        );
      },
    );
  });
}
