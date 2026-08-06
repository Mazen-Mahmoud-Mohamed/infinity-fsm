import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/data/cache/overtime_cache_keys.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:mobile/features/overtime/data/models/overtime_session_model.dart';
import 'package:mobile/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:mobile/features/overtime/data/trace/overtime_offline_trace.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/services/overtime_upload_policy_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

/// ~180KB — closer to a compressed 1080p selfie than the tiny test fixtures.
List<int> _realisticPhoto(int seed) =>
    List<int>.generate(180 * 1024, (i) => (seed + i) % 256);

class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity({this.online = false});
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
  Future<String> resolve(GpsSnapshot gps) async => 'Trace Address';
}

class _FakeGpsAddressSync extends Fake implements GpsAddressSyncService {
  @override
  Future<void> enqueueOvertime({
    required String sessionId,
    required String point,
    required GpsSnapshot gps,
  }) async {}
}

class _FakeRemote extends Fake implements OvertimeRemoteDataSource {
  final Map<String, OvertimeSessionModel> mongo = {};
  var _seq = 0;
  final List<String> httpLog = [];

  @override
  Future<OvertimeSessionModel?> getRunning() async {
    httpLog.add('GET /running');
    for (final doc in mongo.values) {
      if (doc.status == OvertimeStatus.running) return doc;
    }
    return null;
  }

  @override
  Future<OvertimeSessionPage> listMine({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
  }) async {
    httpLog.add('GET /mine');
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
    httpLog.add('POST /start photo=${photoBytes.length}');
    OvertimeOfflineTrace.step(
      'HTTP_REQUEST',
      status: 'entered',
      objectId: clientRequestId,
      detail: 'fake POST /start photo=${photoBytes.length}',
    );
    if (photoBytes.isEmpty) {
      OvertimeOfflineTrace.step(
        'HTTP_RESPONSE',
        status: 'failure',
        objectId: clientRequestId,
        detail: 'empty photo rejected',
      );
      throw StateError('photo required');
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
        ),
      ),
      nextCheckpoint: OvertimeCheckpointStage.arrivedAtWorkSite,
    );
    mongo[id] = session;
    mongo['client:$clientRequestId'] = session;
    OvertimeOfflineTrace.step(
      'HTTP_RESPONSE',
      status: 'success',
      objectId: clientRequestId,
      serverId: id,
    );
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
    httpLog.add('POST /$sessionId/end photo=${photoBytes.length}');
    final existing = mongo[sessionId];
    if (existing == null) throw StateError('missing $sessionId');
    final effectiveStart = startedAt ?? existing.startAt;
    final effectiveEnd = endedAt ?? gps.recordedAt;
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
      totalDurationMinutes: 5,
      workingDurationMinutes: 0,
      eligibleOvertimeMinutes: 5,
      liveElapsedSeconds: durationSeconds,
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
        ),
      ),
    );
    mongo[sessionId] = ended;
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
  }) =>
      _cp(
        sessionId: sessionId,
        stage: OvertimeCheckpointStage.arrivedAtWorkSite,
        gps: gps,
        deviceId: deviceId,
        address: address,
        clientRequestId: clientRequestId,
        checkpointAt: checkpointAt,
      );

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
  }) =>
      _cp(
        sessionId: sessionId,
        stage: OvertimeCheckpointStage.finishedWork,
        gps: gps,
        deviceId: deviceId,
        address: address,
        clientRequestId: clientRequestId,
        checkpointAt: checkpointAt,
      );

  Future<OvertimeSessionModel> _cp({
    required String sessionId,
    required OvertimeCheckpointStage stage,
    required GpsSnapshot gps,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    DateTime? checkpointAt,
  }) async {
    httpLog.add('POST /$sessionId/${stage.apiValue}');
    final existing = mongo[sessionId];
    if (existing == null) throw StateError('missing $sessionId');
    final at = checkpointAt ?? gps.recordedAt;
    final cp = OvertimeCheckpoint(
      at: at,
      gps: gps,
      photoUrl: 'https://example.com/${stage.apiValue}.jpg',
      address: address,
      deviceId: deviceId,
      clientRequestId: clientRequestId,
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

  test(
    'FORENSIC: offline 4-stage → dump → reconnect path → restart dump',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final preferences = PreferencesService(prefs);
      final local = OvertimeLocalDataSource(preferences);
      final remote = _FakeRemote();
      final connectivity = _FakeConnectivity(online: false);
      final repository = OvertimeRepositoryImpl(
        remote: remote,
        local: local,
        connectivity: connectivity,
        addressResolver: _FakeAddressResolver(),
        gpsAddressSync: _FakeGpsAddressSync(),
        uploadPolicy: OvertimeUploadPolicyService(
          connectivity: connectivity,
          sessionQueryCache: SessionQueryCache(),
        ),
      );

      final startAt = DateTime.utc(2026, 8, 3, 18, 0, 0);
      const startId = 'ot-forensic-start';

      // --- OFFLINE LIFECYCLE ---
      connectivity.online = false;
      final started = (await repository.startSession(
        type: OvertimeType.normal,
        gps: _gps(startAt),
        photoBytes: _realisticPhoto(1),
        deviceId: 'device-f',
        clientRequestId: startId,
        address: 'Riyadh',
      ) as Success<OvertimeSession>)
          .data;

      await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.arrivedAtWorkSite,
        gps: _gps(startAt.add(const Duration(minutes: 1))),
        photoBytes: _realisticPhoto(2),
        deviceId: 'device-f',
        address: 'Site',
        clientRequestId: 'ot-forensic-arrived',
      );
      await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.finishedWork,
        gps: _gps(startAt.add(const Duration(minutes: 4))),
        photoBytes: _realisticPhoto(3),
        deviceId: 'device-f',
        address: 'Site',
        clientRequestId: 'ot-forensic-finished',
      );
      final ended = (await repository.endSession(
        sessionId: started.id,
        gps: _gps(startAt.add(const Duration(minutes: 5))),
        photoBytes: _realisticPhoto(4),
        deviceId: 'device-f',
        address: 'Riyadh End',
        clientRequestId: 'ot-forensic-end',
      ) as Success<OvertimeSession>)
          .data;

      OvertimeOfflineTrace.step(
        'FORENSIC',
        status: 'success',
        detail: 'AFTER_END_OFFLINE',
        localId: ended.id,
      );
      final afterEnd = local.dumpStorage();

      expect(afterEnd['queueCount'], 4, reason: 'queue must have 4 actions after END');
      expect(afterEnd['historyCount'], 1, reason: 'history must keep ended session');
      expect(afterEnd['runningId'], isNull);
      expect(
        (afterEnd['photoKeys'] as Map).length,
        4,
        reason: '4 photo keys must exist',
      );

      // --- RECONNECT PATH (what the app does when internet returns) ---
      connectivity.online = true;
      OvertimeOfflineTrace.step(
        'CONNECTIVITY',
        status: 'success',
        detail: 'restored — simulating app reconnect handlers',
      );

      await repository.getRunningSession();
      OvertimeOfflineTrace.step('FORENSIC', status: 'success', detail: 'AFTER_GET_RUNNING');
      final afterRunning = local.dumpStorage();

      final listResult = await repository.listMySessions();
      OvertimeOfflineTrace.step(
        'FORENSIC',
        status: 'success',
        detail:
            'AFTER_LIST_MINE uiWouldShow=${listResult is Success ? (listResult as Success<OvertimeSessionPage>).data.items.length : -1}',
      );
      final afterList = local.dumpStorage();

      // Simulate OvertimeHistoryCubit: it previously emitted remote page.items
      // only (0). After the fix, listMySessions returns the merged prefs list.
      final uiHistoryCount = listResult is Success<OvertimeSessionPage>
          ? listResult.data.items.length
          : -1;

      final syncResult = await repository.syncPendingActions();
      OvertimeOfflineTrace.step(
        'FORENSIC',
        status: 'success',
        detail:
            'AFTER_SYNC synced=${syncResult is Success ? (syncResult as Success<int>).data : syncResult}',
      );
      final afterSync = local.dumpStorage();

      // --- APP RESTART (new datasource over same prefs) ---
      final localAfterRestart = OvertimeLocalDataSource(preferences);
      OvertimeOfflineTrace.step('FORENSIC', status: 'success', detail: 'AFTER_RESTART');
      final afterRestart = localAfterRestart.dumpStorage();

      // Assertions that pinpoint the failure mode:
      expect(
        afterRunning['queueCount'],
        4,
        reason: 'getRunning must NOT clear the pending queue',
      );
      expect(
        afterList['queueCount'],
        greaterThan(0),
        reason: 'listMySessions must NOT clear the pending queue before sync',
      );
      expect(
        afterList['historyCount'],
        greaterThan(0),
        reason: 'merged history must keep unsynced local session',
      );

      // Expose the History UI lie if present.
      // ignore: avoid_print
      print('FORENSIC_UI_HISTORY_COUNT=$uiHistoryCount '
          'FORENSIC_PREFS_HISTORY=${afterList['historyCount']} '
          'FORENSIC_QUEUE_AFTER_LIST=${afterList['queueCount']} '
          'FORENSIC_QUEUE_AFTER_SYNC=${afterSync['queueCount']} '
          'FORENSIC_HTTP=${remote.httpLog} '
          'FORENSIC_MONGO=${remote.mongo.keys.toList()} '
          'FORENSIC_RESTART_QUEUE=${afterRestart['queueCount']} '
          'FORENSIC_RESTART_HISTORY=${afterRestart['historyCount']}');

      expect(uiHistoryCount, 1,
          reason: 'listMySessions must return merged local pending session');

      expect(
        (syncResult as Success<int>).data,
        4,
        reason: 'all 4 pending actions must upload',
      );
      expect(afterSync['queueCount'], 0);
      expect(
        remote.mongo.values.any((s) => s.status == OvertimeStatus.pendingReview),
        isTrue,
        reason: 'backend must have pendingReview session',
      );
      expect(prefs.getString(OvertimeCacheKeys.pendingQueue), anyOf(isNull, equals('[]')));
    },
  );

  test(
    'FORENSIC: HistoryCubit displays remote-only while prefs still have local',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final preferences = PreferencesService(prefs);
      final local = OvertimeLocalDataSource(preferences);
      final remote = _FakeRemote();
      final connectivity = _FakeConnectivity(online: false);
      final repository = OvertimeRepositoryImpl(
        remote: remote,
        local: local,
        connectivity: connectivity,
        addressResolver: _FakeAddressResolver(),
        gpsAddressSync: _FakeGpsAddressSync(),
        uploadPolicy: OvertimeUploadPolicyService(
          connectivity: connectivity,
          sessionQueryCache: SessionQueryCache(),
        ),
      );

      final startAt = DateTime.utc(2026, 8, 3, 19, 0, 0);
      connectivity.online = false;
      final started = (await repository.startSession(
        type: OvertimeType.travel,
        gps: _gps(startAt),
        photoBytes: _realisticPhoto(5),
        deviceId: 'device-h',
        clientRequestId: 'ot-hist-ui',
        address: null,
      ) as Success<OvertimeSession>)
          .data;
      await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.arrivedAtWorkSite,
        gps: _gps(startAt.add(const Duration(minutes: 1))),
        photoBytes: _realisticPhoto(6),
        deviceId: 'device-h',
        address: null,
        clientRequestId: 'ot-hist-arrived',
      );
      await repository.recordCheckpoint(
        sessionId: started.id,
        stage: OvertimeCheckpointStage.finishedWork,
        gps: _gps(startAt.add(const Duration(minutes: 2))),
        photoBytes: _realisticPhoto(7),
        deviceId: 'device-h',
        address: null,
        clientRequestId: 'ot-hist-finished',
      );
      await repository.endSession(
        sessionId: started.id,
        gps: _gps(startAt.add(const Duration(minutes: 3))),
        photoBytes: _realisticPhoto(8),
        deviceId: 'device-h',
        address: null,
        clientRequestId: 'ot-hist-end',
      );

      connectivity.online = true;
      final listResult = await repository.listMySessions();
      final remoteItems = (listResult as Success<OvertimeSessionPage>).data.items;
      final prefsHistory = local.readHistory();
      final queue = local.readQueue();

      // ignore: avoid_print
      print('FORENSIC_HISTORY_UI_BUG remoteItems=${remoteItems.length} '
          'prefsHistory=${prefsHistory.length} queue=${queue.length} '
          'prefsIds=${prefsHistory.map((e) => e.id).toList()}');

      expect(queue.length, 4);
      expect(prefsHistory.length, 1);
      expect(
        remoteItems.length,
        1,
        reason: 'listMySessions must surface local pending in returned page',
      );
      expect(
        prefsHistory.single.id.startsWith('local-'),
        isTrue,
        reason: 'prefs still have the offline session',
      );
      expect(remoteItems.single.id, prefsHistory.single.id);
    },
  );
}
