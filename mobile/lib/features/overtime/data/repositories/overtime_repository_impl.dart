import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_remote_datasource.dart';
import 'package:mobile/features/overtime/data/models/overtime_session_model.dart';
import 'package:mobile/features/overtime/data/models/pending_overtime_action_model.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/services/overtime_calculator.dart';

class OvertimeRepositoryImpl implements OvertimeRepository {
  OvertimeRepositoryImpl({
    required OvertimeRemoteDataSource remote,
    required OvertimeLocalDataSource local,
    required ConnectivityService connectivity,
    required AddressResolverService addressResolver,
    required GpsAddressSyncService gpsAddressSync,
  })  : _remote = remote,
        _local = local,
        _connectivity = connectivity,
        _addressResolver = addressResolver,
        _gpsAddressSync = gpsAddressSync;

  final OvertimeRemoteDataSource _remote;
  final OvertimeLocalDataSource _local;
  final ConnectivityService _connectivity;
  final AddressResolverService _addressResolver;
  final GpsAddressSyncService _gpsAddressSync;

  bool _isConnectivityFailure(String? code) {
    return code == 'OFFLINE' ||
        code == 'TIMEOUT' ||
        code == 'NETWORK_ERROR';
  }

  static int durationSecondsBetween(DateTime startAt, DateTime endAt) {
    final seconds = endAt.difference(startAt).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  /// Shared OT split (must match backend `calculateOvertimeDurations`).
  static OvertimeDurationResult calculateDurations(
    DateTime startAt,
    DateTime endAt,
  ) {
    return OvertimeCalculator.calculate(startAt, endAt);
  }

  GpsSnapshot _gpsWithRecordedAt(GpsSnapshot gps, DateTime recordedAt) {
    return gps.copyWith(recordedAt: recordedAt);
  }

  OvertimeSessionModel _asModel(OvertimeSession session) {
    return session is OvertimeSessionModel
        ? session
        : OvertimeSessionModel.fromJson({
            'id': session.id,
            'companyId': session.companyId,
            'userId': session.userId,
            'type': session.type.apiValue,
            'status': session.status.apiValue,
            'startAt': session.startAt.toIso8601String(),
            'startGps': {
              'latitude': session.startGps.latitude,
              'longitude': session.startGps.longitude,
              'accuracy': session.startGps.accuracy,
              'heading': session.startGps.heading,
              'speed': session.startGps.speed,
              'provider': session.startGps.provider,
              'recordedAt': session.startGps.recordedAt.toIso8601String(),
            },
            'startDeviceId': session.startDeviceId,
            'startAddress': session.startAddress,
            'startPhotoUrl': session.startPhotoUrl,
            'endAt': session.endAt?.toIso8601String(),
            'endGps': session.endGps == null
                ? null
                : {
                    'latitude': session.endGps!.latitude,
                    'longitude': session.endGps!.longitude,
                    'accuracy': session.endGps!.accuracy,
                    'heading': session.endGps!.heading,
                    'speed': session.endGps!.speed,
                    'provider': session.endGps!.provider,
                    'recordedAt':
                        session.endGps!.recordedAt.toIso8601String(),
                  },
            'endAddress': session.endAddress,
            'endPhotoUrl': session.endPhotoUrl,
            'endDeviceId': session.endDeviceId,
            'totalDurationMinutes': session.totalDurationMinutes,
            'workingDurationMinutes': session.workingDurationMinutes,
            'eligibleOvertimeMinutes': session.eligibleOvertimeMinutes,
            'liveElapsedSeconds': session.liveElapsedSeconds,
            'rejectionReason': session.rejectionReason,
            'createdAt': session.createdAt?.toIso8601String(),
          });
  }

  OvertimeSessionModel _copySession(
    OvertimeSession source, {
    String? id,
    String? companyId,
    String? userId,
    OvertimeStatus? status,
    DateTime? startAt,
    GpsSnapshot? startGps,
    String? startDeviceId,
    String? startAddress,
    String? startPhotoUrl,
    DateTime? endAt,
    GpsSnapshot? endGps,
    String? endAddress,
    String? endPhotoUrl,
    String? endDeviceId,
    int? totalDurationMinutes,
    int? workingDurationMinutes,
    int? eligibleOvertimeMinutes,
    int? liveElapsedSeconds,
    DateTime? createdAt,
    bool clearEnd = false,
  }) {
    return OvertimeSessionModel(
      id: id ?? source.id,
      companyId: companyId ?? source.companyId,
      userId: userId ?? source.userId,
      type: source.type,
      status: status ?? source.status,
      startAt: startAt ?? source.startAt,
      startGps: startGps ?? source.startGps,
      startDeviceId: startDeviceId ?? source.startDeviceId,
      startAddress: startAddress ?? source.startAddress,
      startPhotoUrl: startPhotoUrl ?? source.startPhotoUrl,
      endAt: clearEnd ? null : (endAt ?? source.endAt),
      endGps: clearEnd ? null : (endGps ?? source.endGps),
      endAddress: clearEnd ? null : (endAddress ?? source.endAddress),
      endPhotoUrl: clearEnd ? null : (endPhotoUrl ?? source.endPhotoUrl),
      endDeviceId: clearEnd ? null : (endDeviceId ?? source.endDeviceId),
      totalDurationMinutes:
          totalDurationMinutes ?? source.totalDurationMinutes,
      workingDurationMinutes:
          workingDurationMinutes ?? source.workingDurationMinutes,
      eligibleOvertimeMinutes:
          eligibleOvertimeMinutes ?? source.eligibleOvertimeMinutes,
      liveElapsedSeconds: liveElapsedSeconds ?? source.liveElapsedSeconds,
      createdAt: createdAt ?? source.createdAt,
    );
  }

  OvertimeSessionModel _buildOptimisticRunning({
    required OvertimeType type,
    required GpsSnapshot gps,
    required String deviceId,
    required String clientRequestId,
    required String? address,
    required DateTime startAt,
  }) {
    return OvertimeSessionModel(
      id: 'local-$clientRequestId',
      companyId: 'local',
      userId: 'local',
      type: type,
      status: OvertimeStatus.running,
      startAt: startAt,
      startGps: _gpsWithRecordedAt(gps, startAt),
      startDeviceId: deviceId,
      startAddress: address,
      liveElapsedSeconds: 0,
      createdAt: startAt,
    );
  }

  @override
  Future<Result<OvertimeSession?>> getRunningSession() async {
    try {
      final session = await _remote.getRunning();
      await _local.saveRunningSession(
        session == null ? null : _asModel(session),
      );
      return Success(session);
    } on Object catch (error) {
      final failure = NetworkErrorMapper.map<OvertimeSession?>(error);
      final cached = _local.readRunningSession();
      if (_isConnectivityFailure(failure.code)) {
        return Success(cached);
      }
      if (cached != null) {
        return Success(cached);
      }
      return failure;
    }
  }

  @override
  Future<Result<OvertimeSession>> startSession({
    required OvertimeType type,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    required String deviceId,
    required String clientRequestId,
    required String? address,
  }) async {
    final isOnline = await _connectivity.isConnected;
    if (!isOnline) {
      return _queueStart(
        type: type,
        gps: gps,
        photoBytes: photoBytes,
        deviceId: deviceId,
        clientRequestId: clientRequestId,
        address: address,
      );
    }

    try {
      final session = await _remote.start(
        type: type,
        gps: gps,
        photoBytes: photoBytes,
        deviceId: deviceId,
        clientRequestId: clientRequestId,
        address: address,
      );
      final model = _asModel(session);
      await _local.saveRunningSession(model);
      if (gps.needsAddressResolution) {
        await _gpsAddressSync.enqueueOvertime(
          sessionId: model.id,
          point: 'start',
          gps: gps,
        );
      }
      return Success(model);
    } on Object catch (error) {
      final failure = NetworkErrorMapper.map<OvertimeSession>(error);
      if (_isConnectivityFailure(failure.code)) {
        return _queueStart(
          type: type,
          gps: gps,
          photoBytes: photoBytes,
          deviceId: deviceId,
          clientRequestId: clientRequestId,
          address: address,
        );
      }
      return failure;
    }
  }

  Future<Result<OvertimeSession>> _queueStart({
    required OvertimeType type,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    required String deviceId,
    required String clientRequestId,
    required String? address,
  }) async {
    final startAt = gps.recordedAt;
    final optimistic = _buildOptimisticRunning(
      type: type,
      gps: gps,
      deviceId: deviceId,
      clientRequestId: clientRequestId,
      address: address,
      startAt: startAt,
    );
    await _local.saveRunningSession(optimistic);
    await _local.enqueue(
      PendingOvertimeActionModel(
        id: clientRequestId,
        type: PendingOvertimeActionType.start,
        overtimeType: type,
        gps: _gpsWithRecordedAt(gps, startAt),
        photoBytes: photoBytes,
        deviceId: deviceId,
        clientRequestId: clientRequestId,
        address: address,
        startedAt: startAt,
        createdAt: DateTime.now(),
      ),
    );
    return Success(optimistic);
  }

  @override
  Future<Result<OvertimeSession>> endSession({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    required String deviceId,
    required String? address,
  }) async {
    final isOnline = await _connectivity.isConnected;
    if (!isOnline) {
      return _queueEnd(
        sessionId: sessionId,
        gps: gps,
        photoBytes: photoBytes,
        deviceId: deviceId,
        address: address,
      );
    }

    try {
      final session = await _remote.end(
        sessionId: sessionId,
        gps: gps,
        photoBytes: photoBytes,
        deviceId: deviceId,
        address: address,
      );
      final model = _asModel(session);
      await _local.saveRunningSession(null);
      final history = _local.readHistory();
      await _local.saveHistory([model, ...history].take(50).toList());
      if (gps.needsAddressResolution) {
        await _gpsAddressSync.enqueueOvertime(
          sessionId: model.id,
          point: 'end',
          gps: gps,
        );
      }
      return Success(model);
    } on Object catch (error) {
      final failure = NetworkErrorMapper.map<OvertimeSession>(error);
      if (_isConnectivityFailure(failure.code)) {
        return _queueEnd(
          sessionId: sessionId,
          gps: gps,
          photoBytes: photoBytes,
          deviceId: deviceId,
          address: address,
        );
      }
      return failure;
    }
  }

  /// Resolve the local running session without inventing a new start time.
  OvertimeSessionModel? _resolveRunningSession(String sessionId) {
    final running = _local.readRunningSession();
    if (running != null) {
      return running;
    }

    // Recover start metadata from a queued START if the running cache was lost.
    for (final action in _local.readQueue()) {
      if (action.type != PendingOvertimeActionType.start) {
        continue;
      }
      final localId = 'local-${action.clientRequestId}';
      if (sessionId != localId && sessionId != action.clientRequestId) {
        continue;
      }
      final startAt = action.startedAt ?? action.gps.recordedAt;
      return _buildOptimisticRunning(
        type: action.overtimeType ?? OvertimeType.normal,
        gps: action.gps,
        deviceId: action.deviceId,
        clientRequestId: action.clientRequestId,
        address: action.address,
        startAt: startAt,
      );
    }
    return null;
  }

  Future<Result<OvertimeSession>> _queueEnd({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    required String deviceId,
    required String? address,
  }) async {
    final running = _resolveRunningSession(sessionId);
    if (running == null) {
      return const Failure(
      'overtimeNoRunningSession',
      code: 'NO_RUNNING_SESSION',
    );
    }

    // Never overwrite the original offline startTime.
    final startAt = running.startAt;
    final endAt = gps.recordedAt.isAfter(startAt)
        ? gps.recordedAt
        : DateTime.now();
    final safeEndAt = endAt.isAfter(startAt) ? endAt : startAt.add(
      const Duration(seconds: 1),
    );
    final durationSeconds = durationSecondsBetween(startAt, safeEndAt);
    final durations = calculateDurations(startAt, safeEndAt);

    final ended = _copySession(
      running,
      status: OvertimeStatus.pendingReview,
      startAt: startAt,
      endAt: safeEndAt,
      endGps: _gpsWithRecordedAt(gps, safeEndAt),
      endAddress: address,
      endDeviceId: deviceId,
      totalDurationMinutes: durations.totalDurationMinutes,
      workingDurationMinutes: durations.workingDurationMinutes,
      eligibleOvertimeMinutes: durations.eligibleOvertimeMinutes,
      liveElapsedSeconds: durationSeconds,
    );

    await _local.saveRunningSession(null);
    final history = _local.readHistory()
        .where((item) => item.id != ended.id)
        .toList();
    await _local.saveHistory([ended, ...history].take(50).toList());
    await _local.enqueue(
      PendingOvertimeActionModel(
        id: 'end-${ended.id}-${safeEndAt.millisecondsSinceEpoch}',
        type: PendingOvertimeActionType.end,
        sessionId: ended.id,
        gps: _gpsWithRecordedAt(gps, safeEndAt),
        photoBytes: photoBytes,
        deviceId: deviceId,
        clientRequestId: 'end-${ended.id}',
        address: address,
        startedAt: startAt,
        endedAt: safeEndAt,
        durationSeconds: durationSeconds,
        createdAt: DateTime.now(),
      ),
    );
    return Success(ended);
  }

  @override
  Future<Result<OvertimeSessionPage>> listAdminSessions({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
    String? search,
  }) async {
    try {
      final result = await _remote.listAdmin(
        page: page,
        limit: limit,
        status: status,
        search: search,
      );
      return Success(result);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<OvertimeSessionPage>> listMySessions({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
  }) async {
    try {
      final result = await _remote.listMine(
        page: page,
        limit: limit,
        status: status,
      );
      if (page == 1) {
        await _local.saveHistory(
          result.items.map(_asModel).toList(),
        );
      }
      return Success(result);
    } on Object catch (error) {
      final failure = NetworkErrorMapper.map<OvertimeSessionPage>(error);
      final cached = _local.readHistory();
      if (_isConnectivityFailure(failure.code) || cached.isNotEmpty) {
        final filtered = status == null
            ? cached
            : cached.where((item) => item.status == status).toList();
        return Success(
          OvertimeSessionPage(
            items: filtered,
            page: 1,
            limit: limit,
            total: filtered.length,
            totalPages: 1,
          ),
        );
      }
      return failure;
    }
  }

  @override
  Future<Result<OvertimeSession>> getSessionById(String id) async {
    try {
      final session = await _remote.getById(id);
      return Success(session);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<OvertimeSession>> approveSession(String id) async {
    try {
      final session = await _remote.approve(id);
      return Success(session);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<OvertimeSession>> rejectSession(
    String id, {
    String? rejectionReason,
  }) async {
    try {
      final session = await _remote.reject(
        id,
        rejectionReason: rejectionReason,
      );
      return Success(session);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<List<PendingOvertimeAction>> getPendingActions() async {
    return _local.readQueue();
  }

  Future<void> _replaceHistoryId(
    String localId,
    OvertimeSessionModel replacement,
  ) async {
    final history = _local.readHistory();
    final next = history.map((item) {
      if (item.id != localId) {
        return item;
      }
      // Keep offline start/end/duration; only adopt the server id/company/user.
      return _copySession(
        item,
        id: replacement.id,
        companyId: replacement.companyId,
        userId: replacement.userId,
        startAt: item.startAt,
        endAt: item.endAt,
        totalDurationMinutes: item.totalDurationMinutes,
        workingDurationMinutes: item.workingDurationMinutes,
        eligibleOvertimeMinutes: item.eligibleOvertimeMinutes,
        liveElapsedSeconds: item.liveElapsedSeconds,
        endGps: item.endGps,
        endAddress: item.endAddress,
        endPhotoUrl: item.endPhotoUrl ?? replacement.endPhotoUrl,
        endDeviceId: item.endDeviceId,
        startPhotoUrl: item.startPhotoUrl ?? replacement.startPhotoUrl,
      );
    }).toList();
    await _local.saveHistory(next);
  }

  @override
  Future<Result<int>> syncPendingActions() async {
    if (!await _connectivity.isConnected) {
      return const Success(0);
    }

    var synced = 0;
    final queue = [..._local.readQueue()]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Resolve local session ids after start sync.
    final localIdMap = <String, String>{};

    for (final action in queue) {
      try {
        final enriched = await _enrichPendingAction(action);

        if (enriched.type == PendingOvertimeActionType.start) {
          final startedAt = enriched.startedAt ?? enriched.gps.recordedAt;
          final session = await _remote.start(
            type: enriched.overtimeType ?? OvertimeType.normal,
            gps: _gpsWithRecordedAt(enriched.gps, startedAt),
            photoBytes: enriched.photoBytes,
            deviceId: enriched.deviceId,
            clientRequestId: enriched.clientRequestId,
            address: enriched.address,
            startedAt: startedAt,
          );
          final localId = 'local-${enriched.clientRequestId}';
          localIdMap[localId] = session.id;

          final running = _local.readRunningSession();
          if (running != null && running.id == localId) {
            // Keep the original offline startTime while adopting the server id.
            await _local.saveRunningSession(
              _copySession(
                running,
                id: session.id,
                companyId: session.companyId,
                userId: session.userId,
                startAt: running.startAt,
                startPhotoUrl:
                    running.startPhotoUrl ?? session.startPhotoUrl,
              ),
            );
          }

          await _replaceHistoryId(localId, _asModel(session));
          await _local.removeFromQueue(enriched.id);
          if (enriched.gps.needsAddressResolution) {
            await _gpsAddressSync.enqueueOvertime(
              sessionId: session.id,
              point: 'start',
              gps: enriched.gps,
            );
          }
          synced += 1;
        } else {
          var sessionId = enriched.sessionId ?? '';
          if (sessionId.startsWith('local-') &&
              localIdMap.containsKey(sessionId)) {
            sessionId = localIdMap[sessionId]!;
          }
          if (sessionId.startsWith('local-')) {
            // Start action not synced yet; keep for next pass.
            continue;
          }

          final endedAt = enriched.endedAt ?? enriched.gps.recordedAt;
          final startedAt = enriched.startedAt;
          final durationSeconds = enriched.durationSeconds ??
              (startedAt == null
                  ? null
                  : durationSecondsBetween(startedAt, endedAt));
          final endedRemote = await _remote.end(
            sessionId: sessionId,
            gps: _gpsWithRecordedAt(enriched.gps, endedAt),
            photoBytes: enriched.photoBytes,
            deviceId: enriched.deviceId,
            address: enriched.address,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
          );

          // Keep server OT minutes after sync — never overwrite migrated /
          // authoritative backend duration fields with a local recalculation.
          final localEnded = startedAt != null
              ? _copySession(
                  _asModel(endedRemote),
                  startAt: startedAt,
                  endAt: endedAt,
                  totalDurationMinutes: endedRemote.totalDurationMinutes,
                  workingDurationMinutes: endedRemote.workingDurationMinutes,
                  eligibleOvertimeMinutes: endedRemote.eligibleOvertimeMinutes,
                  liveElapsedSeconds: enriched.durationSeconds ??
                      durationSecondsBetween(startedAt, endedAt),
                  endGps: _gpsWithRecordedAt(enriched.gps, endedAt),
                  endAddress: enriched.address ?? endedRemote.endAddress,
                  endDeviceId: enriched.deviceId,
                )
              : _asModel(endedRemote);

          final history = _local.readHistory();
          final withoutDupes = history
              .where(
                (item) =>
                    item.id != localEnded.id &&
                    item.id != enriched.sessionId,
              )
              .toList();
          await _local.saveHistory(
            [localEnded, ...withoutDupes].take(50).toList(),
          );
          await _local.removeFromQueue(enriched.id);
          if (enriched.gps.needsAddressResolution) {
            await _gpsAddressSync.enqueueOvertime(
              sessionId: sessionId,
              point: 'end',
              gps: enriched.gps,
            );
          }
          synced += 1;
        }
      } on Object catch (error) {
        final failure = NetworkErrorMapper.map<void>(error);
        if (_isConnectivityFailure(failure.code)) {
          break;
        }
        await _local.updateQueueItem(
          PendingOvertimeActionModel.fromEntity(
            action.copyWith(
              retryCount: action.retryCount + 1,
              lastError: failure.message,
            ),
          ),
        );
      }
    }

    return Success(synced);
  }

  Future<PendingOvertimeAction> _enrichPendingAction(
    PendingOvertimeAction action,
  ) async {
    if (!action.gps.needsAddressResolution &&
        (action.address ?? '').trim().isNotEmpty) {
      return action;
    }
    try {
      final resolved = await _addressResolver.resolveStructured(action.gps);
      final gps = _addressResolver.apply(action.gps, resolved);
      final address = resolved.isResolved
          ? (resolved.fullAddress ?? action.address)
          : action.address;
      final enriched = action.copyWith(gps: gps, address: address);
      await _local.updateQueueItem(
        PendingOvertimeActionModel.fromEntity(enriched),
      );
      return enriched;
    } on Object {
      return action;
    }
  }
}
