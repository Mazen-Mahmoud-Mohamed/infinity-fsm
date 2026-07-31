import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:mobile/features/overtime/data/models/overtime_session_model.dart';
import 'package:mobile/features/overtime/data/repositories/overtime_repository_impl.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService({this.online = false});

  bool online;

  @override
  Future<bool> get isConnected async => online;

  @override
  Stream<bool> get onConnectivityChanged => Stream<bool>.value(online);
}

/// In-memory stand-in for MongoDB that honors client GPS timestamps.
class _FakeOvertimeRemote extends Fake implements OvertimeRemoteDataSource {
  final Map<String, OvertimeSessionModel> mongo = {};
  var _seq = 0;

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
  Future<OvertimeSessionModel> start({
    required OvertimeType type,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    required String deviceId,
    required String clientRequestId,
    required String? address,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
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
    required String deviceId,
    required String? address,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) async {
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
    final minutes =
        OvertimeRepositoryImpl.durationMinutesFromSeconds(seconds);

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
      totalDurationMinutes: minutes,
      workingDurationMinutes: minutes,
      eligibleOvertimeMinutes: minutes,
      liveElapsedSeconds: seconds,
      createdAt: existing.createdAt,
    );
    mongo[sessionId] = ended;
    for (final key in mongo.keys.toList()) {
      if (key.startsWith('client:') && mongo[key]?.id == sessionId) {
        mongo[key] = ended;
      }
    }
    return ended;
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

      // 2) End offline after elapsed time
      final endResult = await repository.endSession(
        sessionId: started.id,
        gps: _gps(endAt),
        photoBytes: const [4, 5, 6],
        deviceId: 'device-1',
        address: 'Riyadh End',
      );

      expect(endResult, isA<Success<OvertimeSession>>());
      final ended = (endResult as Success<OvertimeSession>).data;

      expect(ended.startAt, startAt, reason: 'startTime must stay unchanged');
      expect(ended.endAt, endAt);
      expect(ended.endAt!.isAfter(ended.startAt), isTrue);
      expect(ended.liveElapsedSeconds, 12 * 60 + 30);
      expect(ended.totalDurationMinutes, greaterThan(0));
      expect(ended.totalDurationMinutes, 13); // ceil(750s / 60)

      final history = local.readHistory();
      expect(history, hasLength(1));
      expect(history.single.startAt, startAt);
      expect(history.single.endAt, endAt);
      expect(history.single.totalDurationMinutes, greaterThan(0));

      final queue = local.readQueue();
      expect(queue, hasLength(2));
      final endAction =
          queue.singleWhere((a) => a.type == PendingOvertimeActionType.end);
      expect(endAction.startedAt, startAt);
      expect(endAction.endedAt, endAt);
      expect(endAction.durationSeconds, 12 * 60 + 30);
      expect(endAction.durationSeconds, greaterThan(0));

      // 3) Sync online — fake Mongo honors client timestamps
      connectivity.online = true;
      final syncResult = await repository.syncPendingActions();
      expect(syncResult, isA<Success<int>>());
      expect((syncResult as Success<int>).data, 2);
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

      final endResult = await repository.endSession(
        sessionId: started.id,
        gps: _gps(endAt),
        photoBytes: const [2],
        deviceId: 'device-2',
        address: null,
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
