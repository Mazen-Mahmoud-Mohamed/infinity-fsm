import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/connectivity_service.dart';
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

GpsSnapshot _gps(DateTime at) => GpsSnapshot(
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 8,
      recordedAt: at,
      provider: 'gps',
    );

OvertimeCheckpoint _cp({
  required DateTime at,
  required String clientRequestId,
  String photo = 'https://example.com/p.jpg',
}) {
  return OvertimeCheckpoint(
    at: at,
    gps: _gps(at),
    photoUrl: photo,
    address: 'Site',
    deviceId: 'device-1',
    clientRequestId: clientRequestId,
  );
}

class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity({this.online = true});
  bool online;

  @override
  Future<bool> get isConnected async => online;

  @override
  Future<List<ConnectivityResult>> get connectionTypes async => online
      ? const [ConnectivityResult.wifi]
      : const [ConnectivityResult.none];

  @override
  Stream<bool> get onConnectivityChanged => Stream<bool>.value(online);
}

class _FakeAddressResolver extends Fake implements AddressResolverService {
  @override
  Future<String> resolve(GpsSnapshot gps) async => 'Addr';
}

class _FakeGpsAddressSync extends Fake implements GpsAddressSyncService {
  @override
  Future<void> enqueueOvertime({
    required String sessionId,
    required String point,
    required GpsSnapshot gps,
  }) async {}
}

/// Mirrors production: do not attempt remote upload while connectivity is down.
class _ConnectivityAwareUpload extends Fake
    implements OvertimeUploadPolicyService {
  _ConnectivityAwareUpload(this.connectivity);
  final _FakeConnectivity connectivity;

  @override
  Future<bool> shouldAttemptImmediateUpload({bool force = false}) async =>
      connectivity.online;

  @override
  Future<bool> shouldAutoSync() async => connectivity.online;
}

class _ForensicRemote extends Fake implements OvertimeRemoteDataSource {
  OvertimeSessionModel? running;
  var finishedPosts = 0;
  var arrivedPosts = 0;
  bool timeoutOnceOnFinished = false;
  var _timedOutFinished = false;
  bool conflictOnFinished = false;

  @override
  Future<OvertimeSessionModel?> getRunning() async => running;

  @override
  Future<OvertimeSessionModel> getById(String id) async {
    if (running?.id == id) return running!;
    throw ApiException(message: 'NOT_FOUND', statusCode: 404, code: 'NOT_FOUND');
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
    arrivedPosts += 1;
    final existing = running!;
    final at = checkpointAt ?? gps.recordedAt;
    final checkpoints = (existing.checkpoints ?? const OvertimeCheckpoints())
        .copyWith(
      arrivedAtWorkSite: _cp(at: at, clientRequestId: clientRequestId),
    );
    running = _copy(
      existing,
      checkpoints: checkpoints,
      next: checkpoints.nextStage,
    );
    return running!;
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
    finishedPosts += 1;
    if (timeoutOnceOnFinished && !_timedOutFinished) {
      _timedOutFinished = true;
      final existing = running!;
      final at = checkpointAt ?? gps.recordedAt;
      final checkpoints = (existing.checkpoints ?? const OvertimeCheckpoints())
          .copyWith(
        finishedWork: _cp(at: at, clientRequestId: clientRequestId),
      );
      running = _copy(
        existing,
        checkpoints: checkpoints,
        next: checkpoints.nextStage,
      );
      throw ApiException(
        message: 'errorRequestTimeout',
        code: 'TIMEOUT',
      );
    }

    final existing = running!;
    final existingCp = existing.checkpoints?.finishedWork;
    if (existingCp != null) {
      if (existingCp.clientRequestId == clientRequestId) {
        return existing;
      }
      if (conflictOnFinished) {
        throw ApiException(
          message: 'Checkpoint finishedWork is already completed',
          statusCode: 409,
          code: 'CONFLICT',
        );
      }
    }

    final at = checkpointAt ?? gps.recordedAt;
    final checkpoints = (existing.checkpoints ?? const OvertimeCheckpoints())
        .copyWith(
      finishedWork: _cp(at: at, clientRequestId: clientRequestId),
    );
    running = _copy(
      existing,
      checkpoints: checkpoints,
      next: checkpoints.nextStage,
    );
    return running!;
  }

  OvertimeSessionModel _copy(
    OvertimeSessionModel existing, {
    OvertimeCheckpoints? checkpoints,
    OvertimeCheckpointStage? next,
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
      nextCheckpoint: next ?? existing.nextCheckpoint,
    );
  }

  void seedRunning({
    bool withArrived = false,
    bool withFinished = false,
    OvertimeCheckpointStage? staleNext,
  }) {
    final startAt = DateTime.utc(2026, 8, 8, 10);
    var checkpoints = OvertimeCheckpoints(
      startJourney: _cp(at: startAt, clientRequestId: 'ot-start-1'),
    );
    if (withArrived) {
      checkpoints = checkpoints.copyWith(
        arrivedAtWorkSite: _cp(
          at: DateTime.utc(2026, 8, 8, 11),
          clientRequestId: 'ot-arrived-1',
        ),
      );
    }
    if (withFinished) {
      checkpoints = checkpoints.copyWith(
        finishedWork: _cp(
          at: DateTime.utc(2026, 8, 8, 12),
          clientRequestId: 'ot-finished-SERVER',
        ),
      );
    }
    running = OvertimeSessionModel(
      id: 'server-ot-1',
      companyId: 'company-1',
      userId: 'user-1',
      type: OvertimeType.normal,
      status: OvertimeStatus.running,
      startAt: startAt,
      startGps: _gps(startAt),
      startDeviceId: 'device-1',
      startAddress: 'Start',
      startPhotoUrl: 'https://example.com/start.jpg',
      createdAt: startAt,
      workflowVersion: OvertimeWorkflowVersion.v2,
      checkpoints: checkpoints,
      nextCheckpoint: staleNext ?? checkpoints.nextStage,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late PreferencesService preferences;
  late OvertimeLocalDataSource local;
  late _ForensicRemote remote;
  late _FakeConnectivity connectivity;
  late OvertimeRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    preferences = PreferencesService(prefs);
    local = OvertimeLocalDataSource(preferences);
    remote = _ForensicRemote();
    connectivity = _FakeConnectivity(online: true);
    repository = OvertimeRepositoryImpl(
      remote: remote,
      local: local,
      connectivity: connectivity,
      addressResolver: _FakeAddressResolver(),
      gpsAddressSync: _FakeGpsAddressSync(),
      uploadPolicy: _ConnectivityAwareUpload(connectivity),
    );
  });

  Future<void> seedLocalFromRemote() async {
    final result = await repository.getRunningSession();
    expect(result, isA<Success<OvertimeSession?>>());
  }

  PendingOvertimeActionModel pendingFinished({
    required String clientRequestId,
    String? lastError,
    DateTime? createdAt,
  }) {
    final at = createdAt ?? DateTime.utc(2026, 8, 8, 12);
    return PendingOvertimeActionModel(
      id: clientRequestId,
      type: PendingOvertimeActionType.finishedWork,
      sessionId: 'server-ot-1',
      gps: _gps(at),
      photoBytes: List<int>.filled(32, 7),
      deviceId: 'device-1',
      clientRequestId: clientRequestId,
      address: 'Site',
      checkpointAt: at,
      createdAt: at,
      lastError: lastError,
      retryCount: lastError == null ? 0 : 3,
    );
  }

  group('overtime local state forensics', () {
    test('A) clean online flow advances to endJourney after finish', () async {
      remote.seedRunning(withArrived: true);
      await seedLocalFromRemote();

      final finished = await repository.recordCheckpoint(
        sessionId: 'server-ot-1',
        stage: OvertimeCheckpointStage.finishedWork,
        gps: _gps(DateTime.utc(2026, 8, 8, 12)),
        photoBytes: const [1, 2, 3],
        deviceId: 'device-1',
        address: 'Site',
        clientRequestId: 'ot-finished-clean',
      );
      expect(finished, isA<Success<OvertimeSession>>());
      final session = (finished as Success<OvertimeSession>).data;
      expect(
        session.effectiveNextCheckpoint,
        OvertimeCheckpointStage.endJourney,
      );
    });

    test(
      'I) stale nextCheckpoint field cannot regress behind checkpoints',
      () async {
        remote.seedRunning(
          withArrived: true,
          withFinished: true,
          // Poisoned field from older app versions / bad merges.
          staleNext: OvertimeCheckpointStage.startJourney,
        );
        await seedLocalFromRemote();

        final localSession = local.readRunningSession()!;
        expect(
          localSession.nextCheckpoint,
          isNot(OvertimeCheckpointStage.startJourney),
          reason: 'adopt/normalize must rewrite stale nextCheckpoint',
        );
        expect(
          localSession.effectiveNextCheckpoint,
          OvertimeCheckpointStage.endJourney,
        );
      },
    );

    test(
      'F/G) GET_RUNNING while Finish Work pending keeps optimistic stage; '
      'after server confirms, pending is drained and stage does not regress',
      () async {
        remote.seedRunning(withArrived: true);
        await seedLocalFromRemote();

        // Optimistic Finish Work queued (sync not yet confirmed on server).
        connectivity.online = false;
        final queued = await repository.recordCheckpoint(
          sessionId: 'server-ot-1',
          stage: OvertimeCheckpointStage.finishedWork,
          gps: _gps(DateTime.utc(2026, 8, 8, 12)),
          photoBytes: const [9, 9, 9],
          deviceId: 'device-1',
          address: 'Site',
          clientRequestId: 'ot-finished-pending',
        );
        expect(queued, isA<Success<OvertimeSession>>());
        expect(local.readQueue(), isNotEmpty);
        expect(
          local.readRunningSession()!.checkpoints?.finishedWork,
          isNotNull,
        );
        expect(
          local.readRunningSession()!.effectiveNextCheckpoint,
          OvertimeCheckpointStage.endJourney,
        );

        // GET_RUNNING returns server without finishedWork — must NOT wipe
        // optimistic local Finish Work while pending remains.
        connectivity.online = true;
        remote.seedRunning(withArrived: true);
        final mid = await repository.getRunningSession();
        expect(mid, isA<Success<OvertimeSession?>>());
        expect(
          local.readRunningSession()!.checkpoints?.finishedWork,
          isNotNull,
          reason: 'optimistic Finish Work must survive getRunning',
        );
        expect(
          local.readRunningSession()!.effectiveNextCheckpoint,
          OvertimeCheckpointStage.endJourney,
        );
        expect(local.readQueue(), isNotEmpty);

        // Server later confirms Finish Work.
        remote.seedRunning(withArrived: true, withFinished: true);
        final after = await repository.getRunningSession();
        expect(after, isA<Success<OvertimeSession?>>());
        expect(local.readQueue(), isEmpty);
        expect(
          local.readRunningSession()!.effectiveNextCheckpoint,
          OvertimeCheckpointStage.endJourney,
        );
      },
    );

    test(
      'C) Finish Work server success + client timeout → reconcile recovers',
      () async {
        remote.seedRunning(withArrived: true);
        await seedLocalFromRemote();
        remote.timeoutOnceOnFinished = true;

        final result = await repository.recordCheckpoint(
          sessionId: 'server-ot-1',
          stage: OvertimeCheckpointStage.finishedWork,
          gps: _gps(DateTime.utc(2026, 8, 8, 12)),
          photoBytes: const [1],
          deviceId: 'device-1',
          address: 'Site',
          clientRequestId: 'ot-finished-timeout',
        );
        expect(result, isA<Success<OvertimeSession>>());
        expect(remote.running!.checkpoints?.finishedWork, isNotNull);

        final sync = await repository.syncPendingActions();
        expect(sync, isA<Success<int>>());
        expect(local.readQueue(), isEmpty);
        expect(
          local.readRunningSession()!.effectiveNextCheckpoint,
          OvertimeCheckpointStage.endJourney,
        );
      },
    );

    test(
      'D/H) duplicate Finish Work clientRequestIds — server confirmation '
      'invalidates stale duplicates without clearing unrelated queue',
      () async {
        remote.seedRunning(withArrived: true, withFinished: true);
        await local.enqueue(
          pendingFinished(clientRequestId: 'ot-finished-SERVER'),
        );
        await local.enqueue(
          pendingFinished(
            clientRequestId: 'ot-finished-STALE-B',
            lastError: 'CONFLICT',
            createdAt: DateTime.utc(2026, 8, 8, 12, 5),
          ),
        );
        await local.enqueue(
          PendingOvertimeActionModel(
            id: 'ot-end-keep',
            type: PendingOvertimeActionType.end,
            sessionId: 'server-ot-1',
            gps: _gps(DateTime.utc(2026, 8, 8, 13)),
            photoBytes: const [1],
            deviceId: 'device-1',
            clientRequestId: 'ot-end-keep',
            createdAt: DateTime.utc(2026, 8, 8, 13),
          ),
        );

        await repository.getRunningSession();

        final queue = local.readQueue();
        expect(
          queue.any((e) => e.type == PendingOvertimeActionType.finishedWork),
          isFalse,
        );
        expect(
          queue.any((e) => e.id == 'ot-end-keep'),
          isTrue,
          reason: 'unrelated END pending must survive',
        );
        expect(
          local.readRunningSession(),
          isNull,
          reason: 'pending END must block remote RUNNING adoption',
        );
      },
    );

    test(
      'E/M) app restart with pending Finish Work recovers without clearing data',
      () async {
        remote.seedRunning(withArrived: true);
        await seedLocalFromRemote();

        connectivity.online = false;
        await repository.recordCheckpoint(
          sessionId: 'server-ot-1',
          stage: OvertimeCheckpointStage.finishedWork,
          gps: _gps(DateTime.utc(2026, 8, 8, 12)),
          photoBytes: const [4, 5, 6],
          deviceId: 'device-1',
          address: 'Site',
          clientRequestId: 'ot-finished-restart',
        );
        expect(local.readQueue(), isNotEmpty);

        // Simulate app restart: new datasource/repository over same prefs.
        final local2 = OvertimeLocalDataSource(preferences);
        final connectivity2 = _FakeConnectivity(online: true);
        final repo2 = OvertimeRepositoryImpl(
          remote: remote,
          local: local2,
          connectivity: connectivity2,
          addressResolver: _FakeAddressResolver(),
          gpsAddressSync: _FakeGpsAddressSync(),
          uploadPolicy: _ConnectivityAwareUpload(connectivity2),
        );

        expect(local2.readRunningSession(), isNotNull);
        expect(local2.readQueue(), isNotEmpty);
        expect(
          local2.readRunningSession()!.effectiveNextCheckpoint,
          OvertimeCheckpointStage.endJourney,
        );

        connectivity.online = true;
        remote.seedRunning(withArrived: true); // server still without finish
        await repo2.getRunningSession();
        expect(
          local2.readRunningSession()!.checkpoints?.finishedWork,
          isNotNull,
          reason: 'restart + getRunning must keep optimistic Finish Work',
        );

        final sync = await repo2.syncPendingActions();
        expect(sync, isA<Success<int>>());
        expect(local2.readQueue(), isEmpty);
        expect(
          local2.readRunningSession()!.effectiveNextCheckpoint,
          OvertimeCheckpointStage.endJourney,
        );
      },
    );

    test(
      'L) old persisted nextCheckpoint=startJourney with arrived+finished '
      'completed is normalized on getRunning',
      () async {
        remote.seedRunning(withArrived: true, withFinished: true);
        // Manually poison local prefs like an old buggy build.
        final poisoned = OvertimeSessionModel(
          id: 'server-ot-1',
          companyId: 'company-1',
          userId: 'user-1',
          type: OvertimeType.normal,
          status: OvertimeStatus.running,
          startAt: DateTime.utc(2026, 8, 8, 10),
          startGps: _gps(DateTime.utc(2026, 8, 8, 10)),
          startDeviceId: 'device-1',
          createdAt: DateTime.utc(2026, 8, 8, 10),
          workflowVersion: OvertimeWorkflowVersion.v2,
          checkpoints: OvertimeCheckpoints(
            startJourney: _cp(
              at: DateTime.utc(2026, 8, 8, 10),
              clientRequestId: 'ot-start-1',
            ),
            arrivedAtWorkSite: _cp(
              at: DateTime.utc(2026, 8, 8, 11),
              clientRequestId: 'ot-arrived-1',
            ),
            finishedWork: _cp(
              at: DateTime.utc(2026, 8, 8, 12),
              clientRequestId: 'ot-finished-SERVER',
            ),
          ),
          nextCheckpoint: OvertimeCheckpointStage.startJourney,
        );
        await local.saveRunningSession(poisoned);
        expect(
          poisoned.effectiveNextCheckpoint,
          OvertimeCheckpointStage.endJourney,
          reason: 'entity getter must ignore regressive nextCheckpoint field',
        );

        await repository.getRunningSession();
        final fixed = local.readRunningSession()!;
        expect(fixed.nextCheckpoint, OvertimeCheckpointStage.endJourney);
        expect(
          fixed.effectiveNextCheckpoint,
          OvertimeCheckpointStage.endJourney,
        );
      },
    );

    test(
      'invariant: stage progression is monotonic after getRunning',
      () async {
        remote.seedRunning(withArrived: true, withFinished: true);
        await seedLocalFromRemote();
        final before = local.readRunningSession()!.effectiveNextCheckpoint;
        await repository.getRunningSession();
        final after = local.readRunningSession()!.effectiveNextCheckpoint;
        expect(after, before);
        expect(after, OvertimeCheckpointStage.endJourney);
      },
    );
  });
}
