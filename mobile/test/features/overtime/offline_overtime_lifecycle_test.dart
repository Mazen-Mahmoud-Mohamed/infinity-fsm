import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:mobile/features/overtime/data/models/overtime_session_model.dart';
import 'package:mobile/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService({this.online = false});

  bool online;

  @override
  Future<bool> get isConnected async => online;

  @override
  Future<List<ConnectivityResult>> get connectionTypes async =>
      online ? const [ConnectivityResult.wifi] : const [ConnectivityResult.none];

  @override
  Stream<bool> get onConnectivityChanged => Stream<bool>.value(online);
}

class _FakeAddressResolver extends Fake implements AddressResolverService {
  @override
  Future<String> resolve(GpsSnapshot gps) async => 'Test Address';
}

class _FakeGpsAddressSync extends Fake implements GpsAddressSyncService {
  @override
  Future<void> enqueueOvertime({
    required String sessionId,
    required String point,
    required GpsSnapshot gps,
  }) async {}
}

/// In-memory stand-in for MongoDB that honors client GPS timestamps.
class _FakeOvertimeRemote extends Fake implements OvertimeRemoteDataSource {
  final Map<String, OvertimeSessionModel> mongo = {};
  var _seq = 0;

  /// When true, the next non-START write fails once (simulates reconnect blip).
  bool failNextNonStart = false;

  void _maybeFailNonStart() {
    if (!failNextNonStart) {
      return;
    }
    failNextNonStart = false;
    throw StateError('Simulated mid-sync connectivity blip');
  }

  @override
  Future<OvertimeSessionModel?> getRunning() async {
    for (final doc in mongo.values) {
      if (doc.status == OvertimeStatus.running) {
        return doc;
      }
    }
    return null;
  }

  @override
  Future<OvertimeSessionPage> listMine({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
  }) async {
    final items = mongo.entries
        .where((e) => !e.key.startsWith('client:'))
        .map((e) => e.value)
        .where((s) => status == null || s.status == status)
        .toList();
    return OvertimeSessionPage(
      items: items,
      page: page,
      limit: limit,
      total: items.length,
      totalPages: 1,
    );
  }

  @override
  Future<OvertimeSessionModel> start({
    required OvertimeType type,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    String? voiceFilename,
    required String deviceId,
    required String clientRequestId,
    required String? address,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    final byClientKey = 'client:$clientRequestId';
    final existing = mongo[byClientKey];
    if (existing != null) {
      return existing;
    }

    _seq += 1;
    final id = 'server-$_seq';
    final startAt = startedAt ?? gps.recordedAt;
    final session = OvertimeSessionModel(
      id: id,
      companyId: 'company-1',
      userId: 'user-1',
      type: type,
      status: OvertimeStatus.running,
      startAt: startAt,
      startGps: gps,
      startDeviceId: deviceId,
      startAddress: address,
      startPhotoUrl: 'https://example.com/start.jpg',
      createdAt: startAt,
      workflowVersion: OvertimeWorkflowVersion.v2,
      checkpoints: OvertimeCheckpoints(
        startJourney: OvertimeCheckpoint(
          at: startAt,
          gps: gps,
          photoUrl: 'https://example.com/start.jpg',
          address: address,
          deviceId: deviceId,
          clientRequestId: clientRequestId,
          batteryLevel: batteryLevel,
          networkStatus: networkStatus,
          notes: notes,
        ),
      ),
      nextCheckpoint: OvertimeCheckpointStage.arrivedAtWorkSite,
    );
    mongo[id] = session;
    mongo[byClientKey] = session;
    return session;
  }

  @override
  Future<OvertimeSessionModel> end({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    String? voiceFilename,
    required String deviceId,
    required String? address,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    String? notes,
    String? clientRequestId,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    _maybeFailNonStart();
    final existing = mongo[sessionId];
    if (existing == null) {
      throw StateError('Session $sessionId not found');
    }

    final effectiveStart = startedAt ?? existing.startAt;
    final effectiveEnd = endedAt ??
        (gps.recordedAt.isAfter(effectiveStart)
            ? gps.recordedAt
            : effectiveStart.add(const Duration(seconds: 1)));
    final seconds = durationSeconds ??
        OvertimeRepositoryImpl.durationSecondsBetween(
          effectiveStart,
          effectiveEnd,
        );
    final durations =
        OvertimeRepositoryImpl.calculateDurations(effectiveStart, effectiveEnd);

    final ended = OvertimeSessionModel(
      id: existing.id,
      companyId: existing.companyId,
      userId: existing.userId,
      type: existing.type,
      status: OvertimeStatus.pendingReview,
      startAt: effectiveStart,
      startGps: existing.startGps,
      startDeviceId: existing.startDeviceId,
      startAddress: existing.startAddress,
      startPhotoUrl: existing.startPhotoUrl,
      endAt: effectiveEnd,
      endGps: gps,
      endAddress: address,
      endPhotoUrl: 'https://example.com/end.jpg',
      endDeviceId: deviceId,
      totalDurationMinutes: durations.totalDurationMinutes,
      workingDurationMinutes: durations.workingDurationMinutes,
      eligibleOvertimeMinutes: durations.eligibleOvertimeMinutes,
      liveElapsedSeconds: seconds,
      createdAt: existing.createdAt,
      workflowVersion: existing.workflowVersion,
      checkpoints: (existing.checkpoints ?? const OvertimeCheckpoints()).copyWith(
        endJourney: OvertimeCheckpoint(
          at: effectiveEnd,
          gps: gps,
          photoUrl: 'https://example.com/end.jpg',
          address: address,
          deviceId: deviceId,
          clientRequestId: clientRequestId,
          batteryLevel: batteryLevel,
          networkStatus: networkStatus,
          notes: notes,
        ),
      ),
    );
    mongo[sessionId] = ended;
    for (final key in mongo.keys.toList()) {
      if (key.startsWith('client:') && mongo[key]?.id == sessionId) {
        mongo[key] = ended;
      }
    }
    return ended;
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
  }) {
    return _applyCheckpoint(
      sessionId: sessionId,
      stage: OvertimeCheckpointStage.arrivedAtWorkSite,
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
  }) {
    return _applyCheckpoint(
      sessionId: sessionId,
      stage: OvertimeCheckpointStage.finishedWork,
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

  Future<OvertimeSessionModel> _applyCheckpoint({
    required String sessionId,
    required OvertimeCheckpointStage stage,
    required GpsSnapshot gps,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    DateTime? checkpointAt,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    _maybeFailNonStart();
    final existing = mongo[sessionId];
    if (existing == null) {
      throw StateError('Session $sessionId not found');
    }
    final at = checkpointAt ?? gps.recordedAt;
    final cp = OvertimeCheckpoint(
      at: at,
      gps: gps,
      photoUrl: 'https://example.com/${stage.apiValue}.jpg',
      address: address,
      deviceId: deviceId,
      clientRequestId: clientRequestId,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
      notes: notes,
    );
    final base = existing.checkpoints ?? const OvertimeCheckpoints();
    final checkpoints = stage == OvertimeCheckpointStage.arrivedAtWorkSite
        ? base.copyWith(arrivedAtWorkSite: cp)
        : base.copyWith(finishedWork: cp);
    final updated = OvertimeSessionModel(
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
      checkpoints: checkpoints,
      nextCheckpoint: checkpoints.nextStage,
    );
    mongo[sessionId] = updated;
    return updated;
  }
}

GpsSnapshot _gps(DateTime at) {
  return GpsSnapshot(
    latitude: 24.7136,
    longitude: 46.6753,
    accuracy: 8,
    recordedAt: at,
    provider: 'gps',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late PreferencesService preferences;
  late OvertimeLocalDataSource local;
  late _FakeOvertimeRemote remote;
  late _FakeConnectivityService connectivity;
  late OvertimeRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    preferences = PreferencesService(prefs);
    local = OvertimeLocalDataSource(preferences);
    remote = _FakeOvertimeRemote();
    connectivity = _FakeConnectivityService(online: false);
    repository = OvertimeRepositoryImpl(
      remote: remote,
      local: local,
      connectivity: connectivity,
      addressResolver: _FakeAddressResolver(),
      gpsAddressSync: _FakeGpsAddressSync(),
    );
  });

  test(
    'offline start → wait → end → sync keeps startTime and duration > 0',
    () async {
      final startAt = DateTime.utc(2026, 7, 30, 17, 0, 0);
      final endAt = startAt.add(const Duration(minutes: 12, seconds: 30));
      const clientRequestId = 'ot-device-1';

      // 1) Start offline
      connectivity.online = false;
      final startResult = await repository.startSession(
        type: OvertimeType.normal,
        gps: _gps(startAt),
        photoBytes: const [1, 2, 3],
        deviceId: 'device-1',
        clientRequestId: clientRequestId,
        address: 'Riyadh',
      );

      expect(startResult, isA<Success<OvertimeSession>>());
      final started = (startResult as Success<OvertimeSession>).data;
      expect(started.startAt, startAt);
      expect(started.status, OvertimeStatus.running);
      expect(local.readRunningSession()?.startAt, startAt);

      final startQueue = local.readQueue();
      expect(startQueue, hasLength(1));
      expect(startQueue.single.type, PendingOvertimeActionType.start);
      expect(startQueue.single.startedAt, startAt);

      // 2) Mid-journey checkpoints (v2) — informational only
      final arrivedAt = startAt.add(const Duration(minutes: 2));
      final arrivedResult = await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.arrivedAtWorkSite,
        gps: _gps(arrivedAt),
        photoBytes: const [7, 8],
        deviceId: 'device-1',
        address: 'Site',
        clientRequestId: 'ot-cp-device-1-arrivedAtWorkSite-1',
      );
      expect(arrivedResult, isA<Success<OvertimeSession>>());

      final finishedAt = startAt.add(const Duration(minutes: 10));
      final finishedResult = await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.finishedWork,
        gps: _gps(finishedAt),
        photoBytes: const [9],
        deviceId: 'device-1',
        address: 'Site',
        clientRequestId: 'ot-cp-device-1-finishedWork-1',
      );
      expect(finishedResult, isA<Success<OvertimeSession>>());

      // 3) End offline after elapsed time
      final endResult = await repository.endSession(
        sessionId: started.id,
        gps: _gps(endAt),
        photoBytes: const [4, 5, 6],
        deviceId: 'device-1',
        address: 'Riyadh End',
        clientRequestId: 'ot-end-device-1-1',
      );

      expect(endResult, isA<Success<OvertimeSession>>());
      final ended = (endResult as Success<OvertimeSession>).data;

      expect(ended.startAt, startAt, reason: 'startTime must stay unchanged');
      expect(ended.endAt, endAt);
      expect(ended.endAt!.isAfter(ended.startAt), isTrue);
      expect(ended.liveElapsedSeconds, 12 * 60 + 30);
      expect(ended.totalDurationMinutes, greaterThan(0));
      // 750s → floor minutes = 12 (never ceil / never treat all as eligible blindly).
      expect(ended.totalDurationMinutes, 12);
      expect(ended.eligibleOvertimeMinutes, 12);
      expect(ended.workingDurationMinutes, 0);

      final history = local.readHistory();
      expect(history, hasLength(1));
      expect(history.single.startAt, startAt);
      expect(history.single.endAt, endAt);
      expect(history.single.totalDurationMinutes, greaterThan(0));

      final queue = local.readQueue();
      expect(queue, hasLength(4));
      final endAction =
          queue.singleWhere((a) => a.type == PendingOvertimeActionType.end);
      expect(endAction.startedAt, startAt);
      expect(endAction.endedAt, endAt);
      expect(endAction.durationSeconds, 12 * 60 + 30);
      expect(endAction.durationSeconds, greaterThan(0));

      // 4) Sync online — fake Mongo honors client timestamps
      connectivity.online = true;
      final syncResult = await repository.syncPendingActions();
      expect(syncResult, isA<Success<int>>());
      expect((syncResult as Success<int>).data, 4);
      expect(local.readQueue(), isEmpty);

      final mongoDocs = remote.mongo.entries
          .where((e) => !e.key.startsWith('client:'))
          .map((e) => e.value)
          .toList();
      expect(mongoDocs, hasLength(1));
      final synced = mongoDocs.single;

      expect(synced.startAt, startAt);
      expect(synced.endAt, endAt);
      expect(synced.endAt!.isAfter(synced.startAt), isTrue);
      expect(synced.totalDurationMinutes, greaterThan(0));
      expect(synced.liveElapsedSeconds, 12 * 60 + 30);

      final syncedLocal = local.readHistory().single;
      expect(syncedLocal.startAt, startAt);
      expect(syncedLocal.endAt, endAt);
      expect(syncedLocal.totalDurationMinutes, greaterThan(0));
      expect(syncedLocal.id, synced.id);
    },
  );

  test(
    'interrupted sync after START still finishes mid/end on next pass',
    () async {
      final startAt = DateTime.utc(2026, 7, 30, 19, 0, 0);
      final endAt = startAt.add(const Duration(minutes: 5));
      const clientRequestId = 'ot-interrupted-1';

      connectivity.online = false;
      final startResult = await repository.startSession(
        type: OvertimeType.normal,
        gps: _gps(startAt),
        photoBytes: List<int>.filled(2048, 7),
        deviceId: 'device-3',
        clientRequestId: clientRequestId,
        address: 'Riyadh',
      );
      final started = (startResult as Success<OvertimeSession>).data;

      await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.arrivedAtWorkSite,
        gps: _gps(startAt.add(const Duration(minutes: 1))),
        photoBytes: List<int>.filled(2048, 8),
        deviceId: 'device-3',
        address: 'Site',
        clientRequestId: 'ot-cp-interrupted-arrived',
      );
      await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.finishedWork,
        gps: _gps(startAt.add(const Duration(minutes: 4))),
        photoBytes: List<int>.filled(2048, 9),
        deviceId: 'device-3',
        address: 'Site',
        clientRequestId: 'ot-cp-interrupted-finished',
      );
      await repository.endSession(
        sessionId: started.id,
        gps: _gps(endAt),
        photoBytes: List<int>.filled(2048, 10),
        deviceId: 'device-3',
        address: 'Riyadh End',
        clientRequestId: 'ot-end-interrupted-1',
      );

      expect(local.readQueue(), hasLength(4));
      // Photos must survive outside the queue JSON (four-stage size safety).
      expect(
        preferences.getString('overtime_pending_photo_$clientRequestId'),
        isNotNull,
      );

      connectivity.online = true;
      remote.failNextNonStart = true;
      final firstPass = await repository.syncPendingActions();
      expect(firstPass, isA<Success<int>>());
      expect((firstPass as Success<int>).data, 1);
      expect(local.readLocalIdMap()['local-$clientRequestId'], isNotNull);
      expect(
        local.readQueue().every((a) => a.type != PendingOvertimeActionType.start),
        isTrue,
      );

      // Simulate app restart: in-memory map is gone; durable map + remapped
      // queue session ids must still finish the pipeline.
      remote.failNextNonStart = false;
      final secondPass = await repository.syncPendingActions();
      expect(secondPass, isA<Success<int>>());
      expect((secondPass as Success<int>).data, 3);
      expect(local.readQueue(), isEmpty);

      final mongoDocs = remote.mongo.entries
          .where((e) => !e.key.startsWith('client:'))
          .map((e) => e.value)
          .toList();
      expect(mongoDocs, hasLength(1));
      expect(mongoDocs.single.status, OvertimeStatus.pendingReview);
      expect(mongoDocs.single.endAt, endAt);
    },
  );

  test(
    'online history fetch preserves unsynced local pending sessions',
    () async {
      final startAt = DateTime.utc(2026, 7, 30, 20, 0, 0);
      final endAt = startAt.add(const Duration(minutes: 3));
      connectivity.online = false;

      final startResult = await repository.startSession(
        type: OvertimeType.travel,
        gps: _gps(startAt),
        photoBytes: const [1],
        deviceId: 'device-4',
        clientRequestId: 'ot-preserve-history',
        address: null,
      );
      final started = (startResult as Success<OvertimeSession>).data;
      await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.arrivedAtWorkSite,
        gps: _gps(startAt.add(const Duration(minutes: 1))),
        photoBytes: const [2],
        deviceId: 'device-4',
        address: null,
        clientRequestId: 'ot-preserve-arrived',
      );
      await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.finishedWork,
        gps: _gps(startAt.add(const Duration(minutes: 2))),
        photoBytes: const [3],
        deviceId: 'device-4',
        address: null,
        clientRequestId: 'ot-preserve-finished',
      );
      await repository.endSession(
        sessionId: started.id,
        gps: _gps(endAt),
        photoBytes: const [4],
        deviceId: 'device-4',
        address: null,
        clientRequestId: 'ot-preserve-end',
      );

      expect(local.readHistory(), hasLength(1));
      expect(local.readHistory().single.id.startsWith('local-'), isTrue);

      connectivity.online = true;
      final listed = await repository.listMySessions();
      expect(listed, isA<Success>());
      expect(local.readHistory().any((s) => s.id.startsWith('local-')), isTrue);
      expect(local.readQueue(), hasLength(4));
    },
  );

  test(
    'ending offline recovers startTime from queue if running cache is missing',
    () async {
      final startAt = DateTime.utc(2026, 7, 30, 18, 0, 0);
      final endAt = startAt.add(const Duration(seconds: 90));
      const clientRequestId = 'ot-recover';

      connectivity.online = false;
      final startResult = await repository.startSession(
        type: OvertimeType.travel,
        gps: _gps(startAt),
        photoBytes: const [1],
        deviceId: 'device-2',
        clientRequestId: clientRequestId,
        address: null,
      );
      final started = (startResult as Success<OvertimeSession>).data;

      // Simulate lost running cache (the bug class that zeroed duration).
      await local.saveRunningSession(null);

      final arrivedAt = startAt.add(const Duration(seconds: 20));
      await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.arrivedAtWorkSite,
        gps: _gps(arrivedAt),
        photoBytes: const [3],
        deviceId: 'device-2',
        address: null,
        clientRequestId: 'ot-cp-device-2-arrivedAtWorkSite-1',
      );
      final finishedAt = startAt.add(const Duration(seconds: 60));
      await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.finishedWork,
        gps: _gps(finishedAt),
        photoBytes: const [4],
        deviceId: 'device-2',
        address: null,
        clientRequestId: 'ot-cp-device-2-finishedWork-1',
      );

      final endResult = await repository.endSession(
        sessionId: started.id,
        gps: _gps(endAt),
        photoBytes: const [2],
        deviceId: 'device-2',
        address: null,
        clientRequestId: 'ot-end-device-2-1',
      );

      final ended = (endResult as Success<OvertimeSession>).data;
      expect(ended.startAt, startAt);
      expect(ended.endAt, endAt);
      expect(ended.liveElapsedSeconds, 90);
      expect(ended.totalDurationMinutes, greaterThan(0));

      final endAction = local
          .readQueue()
          .singleWhere((a) => a.type == PendingOvertimeActionType.end);
      expect(endAction.startedAt, startAt);
      expect(endAction.endedAt, endAt);
      expect(endAction.durationSeconds, 90);
    },
  );
}
