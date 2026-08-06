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
import 'package:mobile/features/overtime/data/trace/overtime_offline_trace.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_export_filters.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/services/overtime_calculator.dart';
import 'package:mobile/features/overtime/domain/services/overtime_upload_policy_service.dart';

class OvertimeRepositoryImpl implements OvertimeRepository {
  OvertimeRepositoryImpl({
    required OvertimeRemoteDataSource remote,
    required OvertimeLocalDataSource local,
    required ConnectivityService connectivity,
    required AddressResolverService addressResolver,
    required GpsAddressSyncService gpsAddressSync,
    required OvertimeUploadPolicyService uploadPolicy,
  }) : _remote = remote,
       _local = local,
       _connectivity = connectivity,
       _addressResolver = addressResolver,
       _gpsAddressSync = gpsAddressSync,
       _uploadPolicy = uploadPolicy;

  final OvertimeRemoteDataSource _remote;
  final OvertimeLocalDataSource _local;
  final ConnectivityService _connectivity;
  final AddressResolverService _addressResolver;
  final GpsAddressSyncService _gpsAddressSync;
  final OvertimeUploadPolicyService _uploadPolicy;

  Future<bool> _shouldAttemptRemoteUpload({bool force = false}) =>
      _uploadPolicy.shouldAttemptImmediateUpload(force: force);

  bool _isConnectivityFailure(String? code) {
    return code == 'OFFLINE' || code == 'TIMEOUT' || code == 'NETWORK_ERROR';
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

  List<int>? _nonEmptyVoiceBytes(List<int>? voiceBytes) {
    if (voiceBytes == null || voiceBytes.isEmpty) {
      return null;
    }
    return voiceBytes;
  }

  OvertimeVoiceNote? _pendingVoiceNote({
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
  }) {
    if (voiceBytes == null || voiceBytes.isEmpty) {
      return null;
    }
    return OvertimeVoiceNote(
      url: 'local-pending',
      duration: voiceDurationSeconds,
    );
  }

  OvertimeSessionModel _asModel(OvertimeSession session) {
    return session is OvertimeSessionModel
        ? session
        : OvertimeSessionModel.fromJson(
            OvertimeSessionModel(
              id: session.id,
              companyId: session.companyId,
              userId: session.userId,
              type: session.type,
              status: session.status,
              startAt: session.startAt,
              startGps: session.startGps,
              startDeviceId: session.startDeviceId,
              startAddress: session.startAddress,
              startPhotoUrl: session.startPhotoUrl,
              endAt: session.endAt,
              endGps: session.endGps,
              endAddress: session.endAddress,
              endPhotoUrl: session.endPhotoUrl,
              endDeviceId: session.endDeviceId,
              totalDurationMinutes: session.totalDurationMinutes,
              workingDurationMinutes: session.workingDurationMinutes,
              eligibleOvertimeMinutes: session.eligibleOvertimeMinutes,
              approvedHours: session.approvedHours,
              liveElapsedSeconds: session.liveElapsedSeconds,
              rejectionReason: session.rejectionReason,
              createdAt: session.createdAt,
              workflowVersion: session.workflowVersion,
              checkpoints: session.checkpoints,
              nextCheckpoint: session.nextCheckpoint,
              requiresManualReview: session.requiresManualReview,
              reviewReason: session.reviewReason,
              reviewNotes: session.reviewNotes,
            ).toJson(),
          );
  }

  OvertimeCheckpoint _buildCheckpoint({
    required DateTime at,
    required GpsSnapshot gps,
    required String deviceId,
    String? address,
    String? photoUrl,
    OvertimeVoiceNote? voiceNote,
    String? notes,
    String? clientRequestId,
    int? batteryLevel,
    String? networkStatus,
  }) {
    return OvertimeCheckpoint(
      at: at,
      gps: _gpsWithRecordedAt(gps, at),
      photoUrl: photoUrl,
      voiceNote: voiceNote,
      address: address,
      deviceId: deviceId,
      clientRequestId: clientRequestId,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
      notes: notes,
    );
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
    double? approvedHours,
    int? liveElapsedSeconds,
    DateTime? createdAt,
    OvertimeWorkflowVersion? workflowVersion,
    OvertimeCheckpoints? checkpoints,
    OvertimeCheckpointStage? nextCheckpoint,
    bool? requiresManualReview,
    String? reviewReason,
    String? reviewNotes,
    bool clearNextCheckpoint = false,
    bool clearEnd = false,
    bool clearReviewReason = false,
  }) {
    return OvertimeSessionModel(
      id: id ?? source.id,
      companyId: companyId ?? source.companyId,
      userId: userId ?? source.userId,
      type: source.type,
      isOvernight: source.isOvernight,
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
      totalDurationMinutes: totalDurationMinutes ?? source.totalDurationMinutes,
      workingDurationMinutes:
          workingDurationMinutes ?? source.workingDurationMinutes,
      eligibleOvertimeMinutes:
          eligibleOvertimeMinutes ?? source.eligibleOvertimeMinutes,
      approvedHours: approvedHours ?? source.approvedHours,
      liveElapsedSeconds: liveElapsedSeconds ?? source.liveElapsedSeconds,
      createdAt: createdAt ?? source.createdAt,
      workflowVersion: workflowVersion ?? source.workflowVersion,
      checkpoints: checkpoints ?? source.checkpoints,
      nextCheckpoint: clearNextCheckpoint
          ? null
          : (nextCheckpoint ?? source.nextCheckpoint),
      requiresManualReview: requiresManualReview ?? source.requiresManualReview,
      reviewReason: clearReviewReason
          ? null
          : (reviewReason ?? source.reviewReason),
      reviewNotes: reviewNotes ?? source.reviewNotes,
    );
  }

  OvertimeSessionModel _buildOptimisticRunning({
    required OvertimeType type,
    required GpsSnapshot gps,
    required String deviceId,
    required String clientRequestId,
    required String? address,
    required DateTime startAt,
    bool isOvernight = false,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) {
    final startCheckpoint = _buildCheckpoint(
      at: startAt,
      gps: gps,
      deviceId: deviceId,
      address: address,
      clientRequestId: clientRequestId,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
      notes: notes,
      voiceNote: _pendingVoiceNote(
        voiceBytes: voiceBytes,
        voiceDurationSeconds: voiceDurationSeconds,
      ),
    );
    return OvertimeSessionModel(
      id: 'local-$clientRequestId',
      companyId: 'local',
      userId: 'local',
      type: type,
      isOvernight: type == OvertimeType.travel && isOvernight,
      status: OvertimeStatus.running,
      startAt: startAt,
      startGps: _gpsWithRecordedAt(gps, startAt),
      startDeviceId: deviceId,
      startAddress: address,
      liveElapsedSeconds: 0,
      createdAt: startAt,
      workflowVersion: OvertimeWorkflowVersion.v2,
      checkpoints: OvertimeCheckpoints(startJourney: startCheckpoint),
      nextCheckpoint: OvertimeCheckpointStage.arrivedAtWorkSite,
    );
  }

  @override
  Future<Result<OvertimeSession?>> getRunningSession() async {
    OvertimeOfflineTrace.step('GET_RUNNING', status: 'entered');
    try {
      final session = await _remote.getRunning();
      if (session != null) {
        await _local.saveRunningSession(_asModel(session));
        OvertimeOfflineTrace.step(
          'GET_RUNNING',
          status: 'success',
          serverId: session.id,
          detail: 'remote running adopted',
        );
        return Success(session);
      }

      // Do not wipe an optimistic offline running session while its pending
      // START / checkpoints still need to sync — that made sessions "vanish".
      final cached = _local.readRunningSession();
      if (cached != null &&
          (cached.id.startsWith('local-') ||
              _local.hasPendingActionsForSession(cached.id))) {
        OvertimeOfflineTrace.step(
          'GET_RUNNING',
          status: 'success',
          localId: cached.id,
          queueLength: _local.readQueue().length,
          detail: 'kept local running; remote null',
        );
        return Success(cached);
      }

      await _local.saveRunningSession(null);
      OvertimeOfflineTrace.step(
        'GET_RUNNING',
        status: 'success',
        detail: 'remote null; cleared local running',
        queueLength: _local.readQueue().length,
      );
      return const Success(null);
    } on Object catch (error) {
      final failure = NetworkErrorMapper.map<OvertimeSession?>(error);
      final cached = _local.readRunningSession();
      if (_isConnectivityFailure(failure.code)) {
        OvertimeOfflineTrace.step(
          'GET_RUNNING',
          status: 'success',
          localId: cached?.id,
          detail: 'connectivity failure; returned cache',
        );
        return Success(cached);
      }
      if (cached != null) {
        return Success(cached);
      }
      OvertimeOfflineTrace.step(
        'GET_RUNNING',
        status: 'failure',
        detail: failure.message,
      );
      return failure;
    }
  }

  @override
  Future<Result<OvertimeSession>> startSession({
    required OvertimeType type,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    required String deviceId,
    required String clientRequestId,
    required String? address,
    bool isOvernight = false,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    final resolvedOvernight = type == OvertimeType.travel ? isOvernight : false;
    final shouldUpload = await _shouldAttemptRemoteUpload();
    if (!shouldUpload) {
      return _queueStart(
        type: type,
        gps: gps,
        photoBytes: photoBytes,
        voiceBytes: voiceBytes,
        voiceDurationSeconds: voiceDurationSeconds,
        deviceId: deviceId,
        clientRequestId: clientRequestId,
        address: address,
        isOvernight: resolvedOvernight,
        notes: notes,
        batteryLevel: batteryLevel,
        networkStatus: networkStatus,
      );
    }

    try {
      final session = await _remote.start(
        type: type,
        gps: gps,
        photoBytes: photoBytes,
        voiceBytes: _nonEmptyVoiceBytes(voiceBytes),
        deviceId: deviceId,
        clientRequestId: clientRequestId,
        address: address,
        isOvernight: resolvedOvernight,
        notes: notes,
        batteryLevel: batteryLevel,
        networkStatus: networkStatus,
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
          voiceBytes: voiceBytes,
          voiceDurationSeconds: voiceDurationSeconds,
          deviceId: deviceId,
          clientRequestId: clientRequestId,
          address: address,
          isOvernight: resolvedOvernight,
          notes: notes,
          batteryLevel: batteryLevel,
          networkStatus: networkStatus,
        );
      }
      return failure;
    }
  }

  Future<Result<OvertimeSession>> _queueStart({
    required OvertimeType type,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    required String deviceId,
    required String clientRequestId,
    required String? address,
    bool isOvernight = false,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    OvertimeOfflineTrace.step(
      'QUEUE_START',
      status: 'entered',
      objectId: clientRequestId,
      detail: 'photoBytes=${photoBytes.length}',
    );
    final startAt = gps.recordedAt;
    final optimistic = _buildOptimisticRunning(
      type: type,
      gps: gps,
      deviceId: deviceId,
      clientRequestId: clientRequestId,
      address: address,
      startAt: startAt,
      isOvernight: isOvernight,
      voiceBytes: voiceBytes,
      voiceDurationSeconds: voiceDurationSeconds,
      notes: notes,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
    );
    await _local.saveRunningSession(optimistic);
    await _local.enqueue(
      PendingOvertimeActionModel(
        id: clientRequestId,
        type: PendingOvertimeActionType.start,
        overtimeType: type,
        isOvernight: isOvernight,
        gps: _gpsWithRecordedAt(gps, startAt),
        photoBytes: photoBytes,
        voiceBytes: voiceBytes ?? const [],
        voiceDurationSeconds: voiceDurationSeconds,
        deviceId: deviceId,
        clientRequestId: clientRequestId,
        address: address,
        startedAt: startAt,
        notes: notes,
        batteryLevel: batteryLevel,
        networkStatus: networkStatus,
        createdAt: DateTime.now(),
      ),
    );
    OvertimeOfflineTrace.step(
      'QUEUE_START',
      status: 'success',
      localId: optimistic.id,
      objectId: clientRequestId,
      queueLength: _local.readQueue().length,
    );
    _local.dumpStorage();
    return Success(optimistic);
  }

  @override
  Future<Result<OvertimeSession>> recordCheckpoint({
    required String sessionId,
    required OvertimeCheckpointStage stage,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    if (stage != OvertimeCheckpointStage.arrivedAtWorkSite &&
        stage != OvertimeCheckpointStage.finishedWork) {
      return const Failure(
        'Invalid checkpoint stage',
        code: 'INVALID_CHECKPOINT',
      );
    }

    final shouldUpload = await _shouldAttemptRemoteUpload();
    if (!shouldUpload) {
      return _queueCheckpoint(
        sessionId: sessionId,
        stage: stage,
        gps: gps,
        photoBytes: photoBytes,
        voiceBytes: voiceBytes,
        voiceDurationSeconds: voiceDurationSeconds,
        deviceId: deviceId,
        address: address,
        clientRequestId: clientRequestId,
        notes: notes,
        batteryLevel: batteryLevel,
        networkStatus: networkStatus,
      );
    }

    try {
      final session = stage == OvertimeCheckpointStage.arrivedAtWorkSite
          ? await _remote.recordArrivedAtWorkSite(
              sessionId: sessionId,
              gps: gps,
              photoBytes: photoBytes,
              voiceBytes: _nonEmptyVoiceBytes(voiceBytes),
              deviceId: deviceId,
              address: address,
              clientRequestId: clientRequestId,
              checkpointAt: gps.recordedAt,
              notes: notes,
              batteryLevel: batteryLevel,
              networkStatus: networkStatus,
            )
          : await _remote.recordFinishedWork(
              sessionId: sessionId,
              gps: gps,
              photoBytes: photoBytes,
              voiceBytes: _nonEmptyVoiceBytes(voiceBytes),
              deviceId: deviceId,
              address: address,
              clientRequestId: clientRequestId,
              checkpointAt: gps.recordedAt,
              notes: notes,
              batteryLevel: batteryLevel,
              networkStatus: networkStatus,
            );
      final model = _asModel(session);
      await _local.saveRunningSession(model);
      if (gps.needsAddressResolution) {
        await _gpsAddressSync.enqueueOvertime(
          sessionId: model.id,
          point: stage.apiValue,
          gps: gps,
        );
      }
      return Success(model);
    } on Object catch (error) {
      final failure = NetworkErrorMapper.map<OvertimeSession>(error);
      if (_isConnectivityFailure(failure.code)) {
        return _queueCheckpoint(
          sessionId: sessionId,
          stage: stage,
          gps: gps,
          photoBytes: photoBytes,
          voiceBytes: voiceBytes,
          voiceDurationSeconds: voiceDurationSeconds,
          deviceId: deviceId,
          address: address,
          clientRequestId: clientRequestId,
          notes: notes,
          batteryLevel: batteryLevel,
          networkStatus: networkStatus,
        );
      }
      return failure;
    }
  }

  Future<Result<OvertimeSession>> _queueCheckpoint({
    required String sessionId,
    required OvertimeCheckpointStage stage,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    final running = _resolveRunningSession(sessionId);
    if (running == null) {
      return const Failure(
        'overtimeNoRunningSession',
        code: 'NO_RUNNING_SESSION',
      );
    }

    if (!running.isV2Workflow) {
      return const Failure(
        'Legacy sessions do not support mid-journey checkpoints',
        code: 'LEGACY_WORKFLOW',
      );
    }

    final expected = running.effectiveNextCheckpoint;
    if (expected != stage) {
      return Failure(
        expected == null
            ? 'All checkpoints are already completed'
            : 'Next required checkpoint is ${expected.apiValue}',
        code: 'CHECKPOINT_ORDER',
      );
    }

    final at = gps.recordedAt;
    final checkpoint = _buildCheckpoint(
      at: at,
      gps: gps,
      deviceId: deviceId,
      address: address,
      clientRequestId: clientRequestId,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
      notes: notes,
      voiceNote: _pendingVoiceNote(
        voiceBytes: voiceBytes,
        voiceDurationSeconds: voiceDurationSeconds,
      ),
    );
    final existing = running.checkpoints ?? const OvertimeCheckpoints();
    final updatedCheckpoints =
        stage == OvertimeCheckpointStage.arrivedAtWorkSite
        ? existing.copyWith(arrivedAtWorkSite: checkpoint)
        : existing.copyWith(finishedWork: checkpoint);
    final next = updatedCheckpoints.nextStage;

    final updated = _copySession(
      running,
      checkpoints: updatedCheckpoints,
      nextCheckpoint: next,
      clearNextCheckpoint: next == null,
    );
    await _local.saveRunningSession(updated);

    final actionType = stage == OvertimeCheckpointStage.arrivedAtWorkSite
        ? PendingOvertimeActionType.arrivedAtWorkSite
        : PendingOvertimeActionType.finishedWork;

    await _local.enqueue(
      PendingOvertimeActionModel(
        id: clientRequestId,
        type: actionType,
        sessionId: updated.id,
        gps: _gpsWithRecordedAt(gps, at),
        photoBytes: photoBytes,
        voiceBytes: voiceBytes ?? const [],
        voiceDurationSeconds: voiceDurationSeconds,
        deviceId: deviceId,
        clientRequestId: clientRequestId,
        address: address,
        checkpointAt: at,
        notes: notes,
        batteryLevel: batteryLevel,
        networkStatus: networkStatus,
        createdAt: DateTime.now(),
      ),
    );
    return Success(updated);
  }

  @override
  Future<Result<OvertimeSession>> endSession({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    required String deviceId,
    required String? address,
    String? clientRequestId,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    final shouldUpload = await _shouldAttemptRemoteUpload();
    if (!shouldUpload) {
      return _queueEnd(
        sessionId: sessionId,
        gps: gps,
        photoBytes: photoBytes,
        voiceBytes: voiceBytes,
        voiceDurationSeconds: voiceDurationSeconds,
        deviceId: deviceId,
        address: address,
        clientRequestId: clientRequestId,
        notes: notes,
        batteryLevel: batteryLevel,
        networkStatus: networkStatus,
      );
    }

    try {
      final session = await _remote.end(
        sessionId: sessionId,
        gps: gps,
        photoBytes: photoBytes,
        voiceBytes: _nonEmptyVoiceBytes(voiceBytes),
        deviceId: deviceId,
        address: address,
        clientRequestId: clientRequestId,
        notes: notes,
        batteryLevel: batteryLevel,
        networkStatus: networkStatus,
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
          voiceBytes: voiceBytes,
          voiceDurationSeconds: voiceDurationSeconds,
          deviceId: deviceId,
          address: address,
          clientRequestId: clientRequestId,
          notes: notes,
          batteryLevel: batteryLevel,
          networkStatus: networkStatus,
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
        isOvernight: action.isOvernight,
        notes: action.notes,
        batteryLevel: action.batteryLevel,
        networkStatus: action.networkStatus,
      );
    }
    return null;
  }

  Future<Result<OvertimeSession>> _queueEnd({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    required String deviceId,
    required String? address,
    String? clientRequestId,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    OvertimeOfflineTrace.step(
      'QUEUE_END',
      status: 'entered',
      localId: sessionId,
      detail: 'photoBytes=${photoBytes.length}',
    );
    final running = _resolveRunningSession(sessionId);
    if (running == null) {
      OvertimeOfflineTrace.step(
        'QUEUE_END',
        status: 'failure',
        localId: sessionId,
        detail: 'NO_RUNNING_SESSION',
      );
      return const Failure(
        'overtimeNoRunningSession',
        code: 'NO_RUNNING_SESSION',
      );
    }

    if (running.isV2Workflow) {
      final expected = running.effectiveNextCheckpoint;
      if (expected != null && expected != OvertimeCheckpointStage.endJourney) {
        OvertimeOfflineTrace.step(
          'QUEUE_END',
          status: 'failure',
          localId: sessionId,
          detail: 'CHECKPOINT_ORDER expected=${expected.apiValue}',
        );
        return Failure(
          'Complete ${expected.apiValue} before ending the journey',
          code: 'CHECKPOINT_ORDER',
        );
      }
    }

    // Never overwrite the original offline startTime.
    final startAt = running.startAt;
    final endAt = gps.recordedAt.isAfter(startAt)
        ? gps.recordedAt
        : DateTime.now();
    final safeEndAt = endAt.isAfter(startAt)
        ? endAt
        : startAt.add(const Duration(seconds: 1));
    final durationSeconds = durationSecondsBetween(startAt, safeEndAt);
    final durations = calculateDurations(startAt, safeEndAt);

    final resolvedClientRequestId =
        (clientRequestId != null && clientRequestId.trim().isNotEmpty)
        ? clientRequestId.trim()
        : 'end-${running.id}-${safeEndAt.millisecondsSinceEpoch}';

    final endCheckpoint = _buildCheckpoint(
      at: safeEndAt,
      gps: gps,
      deviceId: deviceId,
      address: address,
      clientRequestId: resolvedClientRequestId,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
      notes: notes,
      voiceNote: _pendingVoiceNote(
        voiceBytes: voiceBytes,
        voiceDurationSeconds: voiceDurationSeconds,
      ),
    );
    final existing = running.checkpoints ?? const OvertimeCheckpoints();
    final updatedCheckpoints = running.isV2Workflow
        ? existing.copyWith(endJourney: endCheckpoint)
        : running.checkpoints;

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
      checkpoints: updatedCheckpoints,
      clearNextCheckpoint: true,
    );

    await _local.saveRunningSession(null);
    final history = _local
        .readHistory()
        .where((item) => item.id != ended.id)
        .toList();
    await _local.saveHistory([ended, ...history].take(50).toList());
    await _local.enqueue(
      PendingOvertimeActionModel(
        id: resolvedClientRequestId,
        type: PendingOvertimeActionType.end,
        sessionId: ended.id,
        gps: _gpsWithRecordedAt(gps, safeEndAt),
        photoBytes: photoBytes,
        voiceBytes: voiceBytes ?? const [],
        voiceDurationSeconds: voiceDurationSeconds,
        deviceId: deviceId,
        clientRequestId: resolvedClientRequestId,
        address: address,
        startedAt: startAt,
        endedAt: safeEndAt,
        durationSeconds: durationSeconds,
        notes: notes,
        batteryLevel: batteryLevel,
        networkStatus: networkStatus,
        createdAt: DateTime.now(),
      ),
    );
    OvertimeOfflineTrace.step(
      'QUEUE_END',
      status: 'success',
      localId: ended.id,
      objectId: resolvedClientRequestId,
      queueLength: _local.readQueue().length,
      pendingSessions: _local
          .readHistory()
          .where((e) => e.id.startsWith('local-'))
          .length,
      detail: 'converted to pending sync',
    );
    _local.dumpStorage();
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
  Future<Result<OvertimeExcelExportResult>> exportExcel(
    OvertimeExportFilters filters,
  ) async {
    try {
      if (!await _connectivity.isConnected) {
        return const Failure('errorNoInternet', code: 'OFFLINE');
      }
      final result = await _remote.exportExcel(filters);
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
    OvertimeOfflineTrace.step(
      'LIST_MY_SESSIONS',
      status: 'entered',
      detail: 'page=$page beforeDump',
    );
    _local.dumpStorage();
    try {
      final result = await _remote.listMine(
        page: page,
        limit: limit,
        status: status,
      );
      if (page == 1) {
        final remoteItems = result.items.map(_asModel).toList();
        final before = _local.readHistory();
        final merged = _mergeHistoryPreservingPending(remoteItems);
        OvertimeOfflineTrace.step(
          'HISTORY_REFRESH',
          status: 'entered',
          detail:
              'remote=${remoteItems.length} localBefore=${before.length} merged=${merged.length}',
        );
        await _local.saveHistory(merged);
        OvertimeOfflineTrace.step(
          'HISTORY_REFRESH',
          status: 'success',
          pendingSessions: merged
              .where((e) => e.id.startsWith('local-'))
              .length,
          queueLength: _local.readQueue().length,
        );
        _local.dumpStorage();
        // CRITICAL: return the merged list, not remote-only.
        // Returning `result` made HistoryCubit / UI show an empty list while
        // prefs still held the offline pending session (session "vanished").
        final mergedPage = OvertimeSessionPage(
          items: status == null
              ? merged
              : merged.where((item) => item.status == status).toList(),
          page: 1,
          limit: limit,
          total: status == null
              ? merged.length
              : merged.where((item) => item.status == status).length,
          totalPages: 1,
        );
        OvertimeOfflineTrace.step(
          'LIST_MY_SESSIONS',
          status: 'success',
          detail:
              'returning mergedCount=${mergedPage.items.length} (remote was ${result.items.length})',
        );
        return Success(mergedPage);
      }
      OvertimeOfflineTrace.step(
        'LIST_MY_SESSIONS',
        status: 'success',
        detail: 'returning remoteCount=${result.items.length}',
      );
      return Success(result);
    } on Object catch (error) {
      final failure = NetworkErrorMapper.map<OvertimeSessionPage>(error);
      final cached = _local.readHistory();
      if (_isConnectivityFailure(failure.code) || cached.isNotEmpty) {
        final filtered = status == null
            ? cached
            : cached.where((item) => item.status == status).toList();
        OvertimeOfflineTrace.step(
          'LIST_MY_SESSIONS',
          status: 'success',
          detail: 'offline/cache fallback count=${filtered.length}',
        );
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
      OvertimeOfflineTrace.step(
        'LIST_MY_SESSIONS',
        status: 'failure',
        detail: failure.message,
      );
      return failure;
    }
  }

  /// Keep offline / pending-sync sessions visible until the queue drains.
  List<OvertimeSessionModel> _mergeHistoryPreservingPending(
    List<OvertimeSessionModel> remoteItems,
  ) {
    final localHistory = _local.readHistory();
    final queue = _local.readQueue();
    if (queue.isEmpty &&
        localHistory.every((item) => !item.id.startsWith('local-'))) {
      return remoteItems;
    }

    final remoteIds = remoteItems.map((item) => item.id).toSet();
    final localIdMap = _local.readLocalIdMap();
    final pendingLocal = <OvertimeSessionModel>[];

    for (final item in localHistory) {
      if (remoteIds.contains(item.id)) {
        continue;
      }
      final keep =
          item.id.startsWith('local-') ||
          queue.any((action) {
            final actionSessionId = action.sessionId;
            if (actionSessionId == item.id) {
              return true;
            }
            if (action.type == PendingOvertimeActionType.start &&
                'local-${action.clientRequestId}' == item.id) {
              return true;
            }
            if (actionSessionId != null &&
                localIdMap[actionSessionId] == item.id) {
              return true;
            }
            return false;
          });
      if (keep) {
        pendingLocal.add(item);
      }
    }

    return [...pendingLocal, ...remoteItems].take(50).toList();
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
  Future<Result<OvertimeSession>> approveSession(
    String id, {
    String? reviewNotes,
    double? approvedHours,
  }) async {
    try {
      final session = await _remote.approve(
        id,
        reviewNotes: reviewNotes,
        approvedHours: approvedHours,
      );
      return Success(session);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<OvertimeSession>> rejectSession(
    String id, {
    String? rejectionReason,
    String? reviewNotes,
  }) async {
    try {
      final session = await _remote.reject(
        id,
        rejectionReason: rejectionReason,
        reviewNotes: reviewNotes,
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
    OvertimeOfflineTrace.step('SYNC_START', status: 'entered');
    _local.dumpStorage();
    if (!await _connectivity.isConnected) {
      OvertimeOfflineTrace.step(
        'SYNC_START',
        status: 'failure',
        detail: 'offline — abort',
        queueLength: _local.readQueue().length,
      );
      return const Success(0);
    }

    var synced = 0;
    final queue = [..._local.readQueue()]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    OvertimeOfflineTrace.step(
      'SYNC_START',
      status: 'success',
      queueLength: queue.length,
      detail: 'online; processing ${queue.map((e) => e.type.name).join(",")}',
    );

    // Durable across sync passes (and app restarts): in-memory map alone was
    // lost after START was removed, leaving mid/end stuck on local-* forever.
    final localIdMap = <String, String>{..._local.readLocalIdMap()};
    _seedLocalIdMapFromCaches(localIdMap);

    for (final action in queue) {
      try {
        final enriched = await _enrichPendingAction(action);

        if (enriched.type == PendingOvertimeActionType.start) {
          OvertimeOfflineTrace.step(
            'REPO_UPLOAD',
            status: 'entered',
            objectId: enriched.id,
            detail: 'START photoBytes=${enriched.photoBytes.length}',
          );
          final startedAt = enriched.startedAt ?? enriched.gps.recordedAt;
          final session = await _remote.start(
            type: enriched.overtimeType ?? OvertimeType.normal,
            gps: _gpsWithRecordedAt(enriched.gps, startedAt),
            photoBytes: enriched.photoBytes,
            voiceBytes: _nonEmptyVoiceBytes(enriched.voiceBytes),
            deviceId: enriched.deviceId,
            clientRequestId: enriched.clientRequestId,
            address: enriched.address,
            startedAt: startedAt,
            isOvernight: enriched.isOvernight,
            notes: enriched.notes,
            batteryLevel: enriched.batteryLevel,
            networkStatus: enriched.networkStatus,
          );
          OvertimeOfflineTrace.step(
            'REPO_UPLOAD',
            status: 'success',
            objectId: enriched.id,
            localId: 'local-${enriched.clientRequestId}',
            serverId: session.id,
            detail: 'START uploaded',
          );
          final localId = 'local-${enriched.clientRequestId}';
          localIdMap[localId] = session.id;
          await _local.rememberLocalIdMapping(localId, session.id);
          await _local.remapQueueSessionIds(localId, session.id);

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
                startPhotoUrl: running.startPhotoUrl ?? session.startPhotoUrl,
                workflowVersion: session.workflowVersion,
                checkpoints: running.checkpoints ?? session.checkpoints,
                nextCheckpoint:
                    running.nextCheckpoint ?? session.nextCheckpoint,
                requiresManualReview: session.requiresManualReview,
                reviewReason: session.reviewReason,
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
        } else if (enriched.isMidCheckpoint) {
          var sessionId = enriched.sessionId ?? '';
          sessionId = _resolveSyncedSessionId(sessionId, localIdMap);
          if (sessionId.startsWith('local-')) {
            continue;
          }

          final checkpointAt = enriched.checkpointAt ?? enriched.gps.recordedAt;
          final remote =
              enriched.type == PendingOvertimeActionType.arrivedAtWorkSite
              ? await _remote.recordArrivedAtWorkSite(
                  sessionId: sessionId,
                  gps: _gpsWithRecordedAt(enriched.gps, checkpointAt),
                  photoBytes: enriched.photoBytes,
                  voiceBytes: _nonEmptyVoiceBytes(enriched.voiceBytes),
                  deviceId: enriched.deviceId,
                  address: enriched.address,
                  clientRequestId: enriched.clientRequestId,
                  checkpointAt: checkpointAt,
                  notes: enriched.notes,
                  batteryLevel: enriched.batteryLevel,
                  networkStatus: enriched.networkStatus,
                )
              : await _remote.recordFinishedWork(
                  sessionId: sessionId,
                  gps: _gpsWithRecordedAt(enriched.gps, checkpointAt),
                  photoBytes: enriched.photoBytes,
                  voiceBytes: _nonEmptyVoiceBytes(enriched.voiceBytes),
                  deviceId: enriched.deviceId,
                  address: enriched.address,
                  clientRequestId: enriched.clientRequestId,
                  checkpointAt: checkpointAt,
                  notes: enriched.notes,
                  batteryLevel: enriched.batteryLevel,
                  networkStatus: enriched.networkStatus,
                );

          final running = _local.readRunningSession();
          if (running != null &&
              (running.id == sessionId || running.id == enriched.sessionId)) {
            await _local.saveRunningSession(
              _copySession(
                _asModel(remote),
                id: sessionId,
                startAt: running.startAt,
                checkpoints: remote.checkpoints ?? running.checkpoints,
                nextCheckpoint: remote.nextCheckpoint,
                requiresManualReview: remote.requiresManualReview,
                reviewReason: remote.reviewReason,
              ),
            );
          }

          await _local.removeFromQueue(enriched.id);
          if (enriched.gps.needsAddressResolution) {
            await _gpsAddressSync.enqueueOvertime(
              sessionId: sessionId,
              point: enriched.checkpointStage?.apiValue ?? 'start',
              gps: enriched.gps,
            );
          }
          synced += 1;
        } else {
          var sessionId = enriched.sessionId ?? '';
          sessionId = _resolveSyncedSessionId(sessionId, localIdMap);
          if (sessionId.startsWith('local-')) {
            // Start action not synced yet; keep for next pass.
            continue;
          }

          final endedAt = enriched.endedAt ?? enriched.gps.recordedAt;
          final startedAt = enriched.startedAt;
          final durationSeconds =
              enriched.durationSeconds ??
              (startedAt == null
                  ? null
                  : durationSecondsBetween(startedAt, endedAt));
          final endedRemote = await _remote.end(
            sessionId: sessionId,
            gps: _gpsWithRecordedAt(enriched.gps, endedAt),
            photoBytes: enriched.photoBytes,
            voiceBytes: _nonEmptyVoiceBytes(enriched.voiceBytes),
            deviceId: enriched.deviceId,
            address: enriched.address,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
            clientRequestId: enriched.clientRequestId,
            notes: enriched.notes,
            batteryLevel: enriched.batteryLevel,
            networkStatus: enriched.networkStatus,
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
                  liveElapsedSeconds:
                      enriched.durationSeconds ??
                      durationSecondsBetween(startedAt, endedAt),
                  endGps: _gpsWithRecordedAt(enriched.gps, endedAt),
                  endAddress: enriched.address ?? endedRemote.endAddress,
                  endDeviceId: enriched.deviceId,
                  checkpoints: endedRemote.checkpoints,
                  workflowVersion: endedRemote.workflowVersion,
                  requiresManualReview: endedRemote.requiresManualReview,
                  reviewReason: endedRemote.reviewReason,
                  clearNextCheckpoint: true,
                )
              : _asModel(endedRemote);

          final history = _local.readHistory();
          final withoutDupes = history
              .where(
                (item) =>
                    item.id != localEnded.id && item.id != enriched.sessionId,
              )
              .toList();
          await _local.saveHistory(
            [localEnded, ...withoutDupes].take(50).toList(),
          );
          await _local.removeFromQueue(enriched.id);

          final localKey = enriched.sessionId;
          if (localKey != null && localKey.startsWith('local-')) {
            await _local.clearLocalIdMapping(localKey);
            localIdMap.remove(localKey);
          } else {
            for (final entry in localIdMap.entries.toList()) {
              if (entry.value == sessionId) {
                await _local.clearLocalIdMapping(entry.key);
                localIdMap.remove(entry.key);
              }
            }
          }

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
        // Fail-closed: mid/end order must not skip ahead on hard failures.
        if (action.isMidCheckpoint ||
            action.type == PendingOvertimeActionType.end ||
            _isOrderBlockingFailure(failure.code, failure.message)) {
          break;
        }
      }
    }

    return Success(synced);
  }

  void _seedLocalIdMapFromCaches(Map<String, String> localIdMap) {
    void consider(OvertimeSessionModel session) {
      if (session.id.startsWith('local-')) {
        return;
      }
      final clientRequestId = session.checkpoints?.startJourney?.clientRequestId
          ?.trim();
      if (clientRequestId == null || clientRequestId.isEmpty) {
        return;
      }
      localIdMap.putIfAbsent('local-$clientRequestId', () => session.id);
    }

    final running = _local.readRunningSession();
    if (running != null) {
      consider(running);
    }
    for (final item in _local.readHistory()) {
      consider(item);
    }
  }

  String _resolveSyncedSessionId(
    String sessionId,
    Map<String, String> localIdMap,
  ) {
    if (!sessionId.startsWith('local-')) {
      return sessionId;
    }
    final mapped = localIdMap[sessionId];
    if (mapped != null && mapped.isNotEmpty) {
      return mapped;
    }
    _seedLocalIdMapFromCaches(localIdMap);
    return localIdMap[sessionId] ?? sessionId;
  }

  bool _isOrderBlockingFailure(String? code, String message) {
    if (code == 'CHECKPOINT_ORDER' ||
        code == 'CONFLICT' ||
        code == 'LEGACY_WORKFLOW') {
      return true;
    }
    return message.contains('Next required');
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
