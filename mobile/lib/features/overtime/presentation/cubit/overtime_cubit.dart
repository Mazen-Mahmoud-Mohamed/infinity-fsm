import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/checkpoint_telemetry_service.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/device_time_guard_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/services/gps_service.dart';
import 'package:mobile/core/services/overtime_session_reminder_service.dart';
import 'package:mobile/core/services/selfie_capture_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/usecases/end_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_running_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/record_overtime_checkpoint_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/start_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_state.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_voice_draft.dart';
import 'package:mobile/features/overtime/data/models/pending_overtime_action_model.dart';

GpsSnapshot _toGpsSnapshot(GpsReading reading, {DateTime? trustedUtc}) {
  return GpsSnapshot(
    latitude: reading.latitude,
    longitude: reading.longitude,
    accuracy: reading.accuracy,
    heading: reading.heading,
    speed: reading.speed,
    altitude: reading.altitude,
    provider: reading.provider,
    recordedAt: trustedUtc ?? reading.recordedAt.toUtc(),
  );
}

bool _isConnectivityCode(String? code) {
  return code == 'OFFLINE' || code == 'TIMEOUT' || code == 'NETWORK_ERROR';
}

String _watermarkLabelFor(OvertimeCheckpointStage? stage, OvertimeType? type) {
  switch (stage) {
    case OvertimeCheckpointStage.arrivedAtWorkSite:
      return 'Arrived at Work Site';
    case OvertimeCheckpointStage.finishedWork:
      return 'Finished Work';
    case OvertimeCheckpointStage.endJourney:
      return 'End Journey';
    case OvertimeCheckpointStage.startJourney:
    case null:
      return type == OvertimeType.travel
          ? 'Start Journey — Travel'
          : 'Start Journey — Normal';
  }
}

double? _latestGpsAccuracy(OvertimeSession? session) {
  if (session == null) {
    return null;
  }
  final checkpoints = session.checkpoints;
  if (checkpoints != null) {
    for (final stage in OvertimeCheckpointStage.ordered.reversed) {
      final checkpoint = checkpoints.forStage(stage);
      if (checkpoint != null) {
        return checkpoint.gps.accuracy;
      }
    }
  }
  return session.startGps.accuracy;
}

/// Holds a resolved running-session lookup, including an intentional null.
class _CachedRunningOvertime {
  const _CachedRunningOvertime(this.session);

  final OvertimeSession? session;
}

typedef _CheckpointCapture = ({
  GpsSnapshot gps,
  List<int> photo,
  String deviceId,
  String? address,
  int? batteryLevel,
  String networkStatus,
  String? notes,
});

class OvertimeCubit extends Cubit<OvertimeState> {
  OvertimeCubit({
    required GetRunningOvertimeUseCase getRunningOvertimeUseCase,
    required StartOvertimeUseCase startOvertimeUseCase,
    required EndOvertimeUseCase endOvertimeUseCase,
    required RecordOvertimeCheckpointUseCase recordCheckpointUseCase,
    required GpsService gpsService,
    required SelfieCaptureService selfieCaptureService,
    required AddressResolverService addressResolverService,
    required DeviceTimeGuardService deviceTimeGuard,
    required GpsAddressSyncService gpsAddressSync,
    required PreferencesService preferencesService,
    required ConnectivityService connectivityService,
    required CheckpointTelemetryService checkpointTelemetryService,
    required SessionQueryCache sessionQueryCache,
    required OvertimeLocalDataSource localDataSource,
    required OvertimeSyncCubit overtimeSyncCubit,
    OvertimeSessionReminderService? reminderService,
  })  : _getRunningOvertimeUseCase = getRunningOvertimeUseCase,
        _startOvertimeUseCase = startOvertimeUseCase,
        _endOvertimeUseCase = endOvertimeUseCase,
        _recordCheckpointUseCase = recordCheckpointUseCase,
        _gpsService = gpsService,
        _selfieCaptureService = selfieCaptureService,
        _addressResolverService = addressResolverService,
        _deviceTimeGuard = deviceTimeGuard,
        _gpsAddressSync = gpsAddressSync,
        _preferencesService = preferencesService,
        _connectivityService = connectivityService,
        _checkpointTelemetryService = checkpointTelemetryService,
        _sessionQueryCache = sessionQueryCache,
        _localDataSource = localDataSource,
        _overtimeSyncCubit = overtimeSyncCubit,
        _reminderService = reminderService,
        super(const OvertimeState());

  static const String _runningCacheKey = 'overtime:running';
  static const Duration _telemetryRefreshInterval = Duration(seconds: 30);

  final GetRunningOvertimeUseCase _getRunningOvertimeUseCase;
  final StartOvertimeUseCase _startOvertimeUseCase;
  final EndOvertimeUseCase _endOvertimeUseCase;
  final RecordOvertimeCheckpointUseCase _recordCheckpointUseCase;
  final GpsService _gpsService;
  final SelfieCaptureService _selfieCaptureService;
  final AddressResolverService _addressResolverService;
  final DeviceTimeGuardService _deviceTimeGuard;
  final GpsAddressSyncService _gpsAddressSync;
  final PreferencesService _preferencesService;
  final ConnectivityService _connectivityService;
  final CheckpointTelemetryService _checkpointTelemetryService;
  final SessionQueryCache _sessionQueryCache;
  final OvertimeLocalDataSource _localDataSource;
  final OvertimeSyncCubit _overtimeSyncCubit;
  final OvertimeSessionReminderService? _reminderService;

  Timer? _tickTimer;
  Timer? _telemetryTimer;

  void updateNotesDraft(String? notes) {
    final trimmed = notes?.trim();
    emit(
      state.copyWith(
        notesDraft: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        clearNotesDraft: trimmed == null || trimmed.isEmpty,
      ),
    );
  }

  void updateVoiceDraft(OvertimeVoiceDraft? draft) {
    emit(
      state.copyWith(
        voiceDraft: draft,
        clearVoiceDraft: draft == null,
      ),
    );
  }

  /// Updates voice on an already-queued offline stage (before sync succeeds).
  Future<void> updatePendingStageVoice({
    required OvertimeCheckpointStage stage,
    OvertimeVoiceDraft? draft,
  }) async {
    final queue = _localDataSource.readQueue();
    final index = queue.indexWhere((action) => action.checkpointStage == stage);
    if (index < 0) {
      return;
    }
    final existing = queue[index];
    final updated = PendingOvertimeActionModel.fromEntity(
      draft == null
          ? existing.copyWith(clearVoice: true)
          : existing.copyWith(
              voiceBytes: draft.bytes,
              voiceDurationSeconds: draft.durationSeconds,
            ),
    );
    final next = [...queue];
    next[index] = updated;
    await _localDataSource.saveQueue(next);
    _kickPendingSync();
    emit(
      state.copyWith(
        pendingSyncCount: next.length,
      ),
    );
  }

  Future<void> initialize() async {
    final cached = _sessionQueryCache.get<_CachedRunningOvertime>(_runningCacheKey);
    final localSession = _localDataSource.readRunningSession();
    final hasCachedLookup = cached != null ||
        localSession != null ||
        state.status == OvertimeLoadStatus.ready;

    if (hasCachedLookup) {
      final session = cached?.session ?? localSession ?? state.session;
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          session: session,
          clearSession: session == null,
          currentAddress: session?.startAddress ?? state.currentAddress,
          elapsedSeconds: session?.elapsedSeconds ?? state.elapsedSeconds,
          isRefreshing: true,
          clearMessage: true,
          clearBusyAction: true,
          gpsAccuracyMeters: _latestGpsAccuracy(session),
          clearGpsAccuracyMeters: session == null,
        ),
      );
      if (session != null && session.isRunning) {
        _startTicker(session.startAt);
      } else {
        _stopTicker();
      }
    } else {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.loading,
          isRefreshing: false,
          clearMessage: true,
          clearCompleted: true,
          clearBusyAction: true,
        ),
      );
    }

    unawaited(_deviceTimeGuard.syncSecurityEvents());
    await _fetchRunning();
    if (!isClosed) {
      emit(state.copyWith(isRefreshing: false));
    }
  }

  Future<void> refresh() => initialize();

  Future<void> _fetchRunning() async {
    final result = await _getRunningOvertimeUseCase();
    switch (result) {
      case Success(data: final session):
        _sessionQueryCache.set(
          _runningCacheKey,
          _CachedRunningOvertime(session),
        );
        emit(
          state.copyWith(
            status: OvertimeLoadStatus.ready,
            session: session,
            clearSession: session == null,
            currentAddress: session?.startAddress,
            elapsedSeconds: session?.elapsedSeconds ?? 0,
            isError: false,
            isOffline: false,
            clearBusyAction: true,
            gpsAccuracyMeters: _latestGpsAccuracy(session),
            clearGpsAccuracyMeters: session == null,
            pendingSyncCount: _localDataSource.readQueue().length,
          ),
        );
        if (session != null && session.isRunning) {
          _startTicker(session.startAt);
        } else {
          _stopTicker();
        }
      case Failure(message: final message, code: final code):
        if (_isConnectivityCode(code)) {
          final cached = state.session ?? _localDataSource.readRunningSession();
          emit(
            state.copyWith(
              status: OvertimeLoadStatus.ready,
              session: cached,
              isOffline: true,
              clearMessage: true,
              isError: false,
              clearBusyAction: true,
              gpsAccuracyMeters: _latestGpsAccuracy(cached),
              clearGpsAccuracyMeters: cached == null,
            ),
          );
          if (cached != null && cached.isRunning) {
            _startTicker(cached.startAt);
          } else {
            _stopTicker();
          }
          return;
        }
        if (state.session != null ||
            state.status == OvertimeLoadStatus.ready) {
          emit(
            state.copyWith(
              status: OvertimeLoadStatus.ready,
              message: message,
              isError: true,
              isOffline: false,
              clearBusyAction: true,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: OvertimeLoadStatus.failure,
            message: message,
            isError: true,
            isOffline: false,
            clearBusyAction: true,
          ),
        );
        _stopTicker();
    }
  }

  Future<void> startNormal() => _start(
        OvertimeType.normal,
        OvertimeBusyAction.startNormal,
      );

  Future<void> startTravel() => _start(
        OvertimeType.travel,
        OvertimeBusyAction.startTravel,
      );

  /// Completes the next sequential checkpoint (arrived / finished / end).
  Future<void> completeNextCheckpoint() async {
    final session = state.session;
    if (session == null || !session.isRunning || state.isBusy) {
      return;
    }

    final next = session.effectiveNextCheckpoint;
    if (next == null) {
      return;
    }

    if (next == OvertimeCheckpointStage.endJourney) {
      await endSession();
      return;
    }

    final busy = next == OvertimeCheckpointStage.arrivedAtWorkSite
        ? OvertimeBusyAction.arrivedAtWorkSite
        : OvertimeBusyAction.finishedWork;

    emit(
      state.copyWith(
        status: OvertimeLoadStatus.actionInProgress,
        busyAction: busy,
        clearMessage: true,
      ),
    );

    try {
      final capture = await _captureGpsAndSelfie(stage: next);
      if (capture == null) {
        return;
      }

      final clientRequestId =
          'ot-cp-${capture.deviceId}-${next.apiValue}-${DateTime.now().millisecondsSinceEpoch}';

      final voice = state.voiceDraft;
      final result = await _recordCheckpointUseCase(
        sessionId: session.id,
        stage: next,
        gps: capture.gps,
        photoBytes: capture.photo,
        deviceId: capture.deviceId,
        address: capture.address,
        clientRequestId: clientRequestId,
        notes: capture.notes,
        batteryLevel: capture.batteryLevel,
        networkStatus: capture.networkStatus,
        voiceBytes: voice?.bytes,
        voiceDurationSeconds: voice?.durationSeconds,
      );

      switch (result) {
        case Success(data: final updated):
          final offlineQueued = !(await _connectivityService.isConnected) ||
              updated.companyId == 'local' ||
              updated.id.startsWith('local-');
          _sessionQueryCache.set(
            _runningCacheKey,
            _CachedRunningOvertime(updated),
          );
          final successKey =
              next == OvertimeCheckpointStage.arrivedAtWorkSite
                  ? 'overtimeArrivedAtWorkSiteRecorded'
                  : 'overtimeFinishedWorkRecorded';
          emit(
            state.copyWith(
              status: OvertimeLoadStatus.ready,
              clearBusyAction: true,
              session: updated,
              currentAddress: capture.address ?? state.currentAddress,
              elapsedSeconds: updated.elapsedSeconds,
              message: offlineQueued ? null : successKey,
              clearMessage: offlineQueued,
              isError: false,
              isOffline: offlineQueued,
              clearNotesDraft: true,
              clearVoiceDraft: true,
            ),
          );
          unawaited(_deviceTimeGuard.syncSecurityEvents());
          unawaited(_gpsAddressSync.processQueue());
          if (offlineQueued) {
            _kickPendingSync();
          }
        case Failure(message: final message, code: final code):
          emit(
            state.copyWith(
              status: OvertimeLoadStatus.ready,
              clearBusyAction: true,
              message: _isConnectivityCode(code) ? null : message,
              clearMessage: _isConnectivityCode(code),
              isError: !_isConnectivityCode(code),
              isOffline: _isConnectivityCode(code),
            ),
          );
      }
    } on LocationException catch (error) {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          clearBusyAction: true,
          message: error.message,
          isError: true,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          clearBusyAction: true,
          message: 'errorGeneric',
          isError: true,
        ),
      );
    }
  }

  Future<void> endSession() async {
    final session = state.session;
    if (session == null || !session.isRunning || state.isBusy) {
      return;
    }

    if (session.isV2Workflow) {
      final next = session.effectiveNextCheckpoint;
      if (next != null && next != OvertimeCheckpointStage.endJourney) {
        emit(
          state.copyWith(
            status: OvertimeLoadStatus.ready,
            message: 'overtimeCompletePriorCheckpoints',
            isError: true,
          ),
        );
        return;
      }
    }

    emit(
      state.copyWith(
        status: OvertimeLoadStatus.actionInProgress,
        busyAction: OvertimeBusyAction.end,
        clearMessage: true,
      ),
    );

    try {
      final capture = await _captureGpsAndSelfie(
        stage: OvertimeCheckpointStage.endJourney,
      );
      if (capture == null) {
        return;
      }

      final clientRequestId =
          'ot-end-${capture.deviceId}-${DateTime.now().millisecondsSinceEpoch}';

      final voice = state.voiceDraft;
      final result = await _endOvertimeUseCase(
        sessionId: session.id,
        gps: capture.gps,
        photoBytes: capture.photo,
        deviceId: capture.deviceId,
        address: capture.address,
        clientRequestId: clientRequestId,
        notes: capture.notes,
        batteryLevel: capture.batteryLevel,
        networkStatus: capture.networkStatus,
        voiceBytes: voice?.bytes,
        voiceDurationSeconds: voice?.durationSeconds,
      );

      switch (result) {
        case Success(data: final ended):
          final offlineQueued = !(await _connectivityService.isConnected) ||
              ended.companyId == 'local' ||
              ended.id.startsWith('local-');
          _stopTicker();
          _sessionQueryCache.set(
            _runningCacheKey,
            const _CachedRunningOvertime(null),
          );
          emit(
            state.copyWith(
              status: OvertimeLoadStatus.ready,
              clearBusyAction: true,
              clearSession: true,
              completedSession: ended,
              currentAddress: ended.endAddress ?? capture.address,
              elapsedSeconds: 0,
              message: offlineQueued ? null : 'overtimeEnded',
              clearMessage: offlineQueued,
              isError: false,
              isOffline: offlineQueued,
              clearNotesDraft: true,
              clearVoiceDraft: true,
              offerContinueSession: false,
            ),
          );
          unawaited(_deviceTimeGuard.syncSecurityEvents());
          unawaited(_gpsAddressSync.processQueue());
          if (offlineQueued) {
            _kickPendingSync();
          }
        case Failure(message: final message, code: final code):
          emit(
            state.copyWith(
              status: OvertimeLoadStatus.ready,
              clearBusyAction: true,
              message: _isConnectivityCode(code) ? null : message,
              clearMessage: _isConnectivityCode(code),
              isError: !_isConnectivityCode(code),
              isOffline: _isConnectivityCode(code),
            ),
          );
      }
    } on LocationException catch (error) {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          clearBusyAction: true,
          message: error.message,
          isError: true,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          clearBusyAction: true,
          message: 'errorGeneric',
          isError: true,
        ),
      );
    }
  }

  /// Shared GPS + live selfie + telemetry capture used by all checkpoints.
  Future<_CheckpointCapture?> _captureGpsAndSelfie({
    OvertimeCheckpointStage? stage,
    OvertimeType? type,
  }) async {
    final timeCheck = await _deviceTimeGuard.validate(module: 'overtime');
    if (!timeCheck.isValid) {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          clearBusyAction: true,
          message: timeCheck.reasonCode ?? 'deviceTimeIncorrect',
          isError: true,
        ),
      );
      unawaited(_deviceTimeGuard.syncSecurityEvents());
      return null;
    }

    final reading = await _gpsService.getCurrentReading();
    if (!reading.isAccurateEnough) {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          clearBusyAction: true,
          message: 'gpsAccuracyTooLow',
          isError: true,
        ),
      );
      return null;
    }

    var gps = _toGpsSnapshot(reading, trustedUtc: timeCheck.trustedUtc);
    final geocodeFuture = _addressResolverService.resolveStructured(gps);
    final telemetryFuture = _checkpointTelemetryService.capture();

    late final List<int> photo;
    try {
      photo = await _selfieCaptureService.captureLivePhoto(
        watermarkLabel: _watermarkLabelFor(stage, type),
        timestamp: timeCheck.trustedUtc ?? reading.recordedAt,
        latitude: gps.latitude,
        longitude: gps.longitude,
      );
    } on LivePhotoRequiredException {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          clearBusyAction: true,
          message: 'livePhotoRequired',
          isError: true,
        ),
      );
      return null;
    } on CameraUnavailableException {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          clearBusyAction: true,
          message: 'cameraUnavailable',
          isError: true,
        ),
      );
      return null;
    }

    String? address;
    try {
      final resolved = await geocodeFuture;
      gps = _addressResolverService.apply(gps, resolved);
      address = resolved.isResolved ? resolved.fullAddress : null;
    } on Object {
      // Keep coordinates; address may resolve later during sync.
    }

    final telemetry = await telemetryFuture;
    final deviceId =
        _preferencesService.getString(StorageKeys.deviceId) ?? 'unknown-device';
    final notes = state.notesDraft?.trim();

    return (
      gps: gps,
      photo: photo,
      deviceId: deviceId,
      address: address,
      batteryLevel: telemetry.batteryLevel,
      networkStatus: telemetry.networkStatus,
      notes: (notes == null || notes.isEmpty) ? null : notes,
    );
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        clearMessage: true,
        isError: false,
      ),
    );
  }

  Future<void> _start(
    OvertimeType type,
    OvertimeBusyAction busyAction,
  ) async {
    if (state.isBusy) {
      return;
    }

    final localRunning = _localDataSource.readRunningSession();
    if (state.session?.isRunning == true ||
        (localRunning != null && localRunning.isRunning)) {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          session: state.session ?? localRunning,
          message: 'overtimeContinueExistingSession',
          isError: false,
          offerContinueSession: true,
        ),
      );
      await _fetchRunning();
      return;
    }

    emit(
      state.copyWith(
        status: OvertimeLoadStatus.actionInProgress,
        busyAction: busyAction,
        clearMessage: true,
        clearCompleted: true,
        offerContinueSession: false,
      ),
    );

    try {
      final capture = await _captureGpsAndSelfie(type: type);
      if (capture == null) {
        return;
      }

      final clientRequestId =
          'ot-${capture.deviceId}-${DateTime.now().millisecondsSinceEpoch}';

      final voice = state.voiceDraft;
      final result = await _startOvertimeUseCase(
        type: type,
        gps: capture.gps,
        photoBytes: capture.photo,
        deviceId: capture.deviceId,
        clientRequestId: clientRequestId,
        address: capture.address,
        notes: capture.notes,
        batteryLevel: capture.batteryLevel,
        networkStatus: capture.networkStatus,
        voiceBytes: voice?.bytes,
        voiceDurationSeconds: voice?.durationSeconds,
      );

      switch (result) {
        case Success(data: final session):
          final offlineQueued = !(await _connectivityService.isConnected) ||
              session.companyId == 'local' ||
              session.id.startsWith('local-');
          _sessionQueryCache.set(
            _runningCacheKey,
            _CachedRunningOvertime(session),
          );
          emit(
            state.copyWith(
              status: OvertimeLoadStatus.ready,
              clearBusyAction: true,
              session: session,
              currentAddress: session.startAddress ?? capture.address,
              elapsedSeconds: session.elapsedSeconds,
              message: offlineQueued
                  ? null
                  : (type == OvertimeType.travel
                      ? 'travelOvertimeStarted'
                      : 'normalOvertimeStarted'),
              clearMessage: offlineQueued,
              isError: false,
              isOffline: offlineQueued,
              clearNotesDraft: true,
              clearVoiceDraft: true,
            ),
          );
          _startTicker(session.startAt);
          unawaited(_deviceTimeGuard.syncSecurityEvents());
          unawaited(_gpsAddressSync.processQueue());
          if (offlineQueued) {
            _kickPendingSync();
          }
        case Failure(message: final message, code: final code):
          final isConflict = code == 'CONFLICT' ||
              message.toLowerCase().contains('already have a running');
          if (isConflict) {
            await _fetchRunning();
            if (!isClosed) {
              emit(
                state.copyWith(
                  status: OvertimeLoadStatus.ready,
                  clearBusyAction: true,
                  message: 'overtimeContinueExistingSession',
                  isError: false,
                  offerContinueSession: true,
                ),
              );
            }
            return;
          }
          emit(
            state.copyWith(
              status: OvertimeLoadStatus.ready,
              clearBusyAction: true,
              message: _isConnectivityCode(code) ? null : message,
              clearMessage: _isConnectivityCode(code),
              isError: !_isConnectivityCode(code),
              isOffline: _isConnectivityCode(code),
            ),
          );
      }
    } on LocationException catch (error) {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          clearBusyAction: true,
          message: error.message,
          isError: true,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: OvertimeLoadStatus.ready,
          clearBusyAction: true,
          message: 'errorGeneric',
          isError: true,
        ),
      );
    }
  }

  void _startTicker(DateTime startAt) {
    _stopTicker();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          elapsedSeconds: DateTime.now().difference(startAt).inSeconds,
        ),
      );
    });
    _reminderService?.startMonitoring(startAt, onRemind: _handleReminder);
    _startTelemetryRefresh();
  }

  void _stopTicker() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _reminderService?.stopMonitoring();
    _stopTelemetryRefresh();
  }

  void _handleReminder() {
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        message: 'overtimeActiveSessionReminder',
        isError: false,
        clearMessage: false,
      ),
    );
  }

  void _startTelemetryRefresh() {
    _telemetryTimer?.cancel();
    unawaited(_refreshLiveTelemetry());
    _telemetryTimer = Timer.periodic(
      _telemetryRefreshInterval,
      (_) => unawaited(_refreshLiveTelemetry()),
    );
  }

  void _stopTelemetryRefresh() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    if (!isClosed) {
      emit(
        state.copyWith(
          clearLiveBatteryLevel: true,
          clearLiveNetworkStatus: true,
        ),
      );
    }
  }

  Future<void> _refreshLiveTelemetry() async {
    if (isClosed || !state.isRunning) {
      return;
    }
    try {
      final telemetry = await _checkpointTelemetryService.capture();
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          liveBatteryLevel: telemetry.batteryLevel,
          clearLiveBatteryLevel: telemetry.batteryLevel == null,
          liveNetworkStatus: telemetry.networkStatus,
        ),
      );
    } on Object {
      // Best-effort telemetry only; never block the session UI.
    }
  }

  /// Explicit continue action for an existing running session — used by the
  /// "Continue Existing Session" banner/button.
  Future<void> continueExistingSession() async {
    emit(state.copyWith(offerContinueSession: false, clearMessage: true));
    await initialize();
  }

  void _kickPendingSync() {
    unawaited(_overtimeSyncCubit.refreshPendingCount());
    unawaited(_overtimeSyncCubit.syncNow());
  }

  @override
  Future<void> close() {
    _stopTicker();
    _stopTelemetryRefresh();
    return super.close();
  }
}
