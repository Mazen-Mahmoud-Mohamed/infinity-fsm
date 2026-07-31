import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/device_time_guard_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/services/gps_service.dart';
import 'package:mobile/core/services/selfie_capture_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/usecases/end_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_running_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/start_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_state.dart';

GpsSnapshot _toGpsSnapshot(GpsReading reading, {DateTime? trustedUtc}) {
  return GpsSnapshot(
    latitude: reading.latitude,
    longitude: reading.longitude,
    accuracy: reading.accuracy,
    heading: reading.heading,
    speed: reading.speed,
    provider: reading.provider,
    recordedAt: trustedUtc ?? reading.recordedAt.toUtc(),
  );
}

bool _isConnectivityCode(String? code) {
  return code == 'OFFLINE' || code == 'TIMEOUT' || code == 'NETWORK_ERROR';
}

/// Holds a resolved running-session lookup, including an intentional null.
class _CachedRunningOvertime {
  const _CachedRunningOvertime(this.session);

  final OvertimeSession? session;
}

class OvertimeCubit extends Cubit<OvertimeState> {
  OvertimeCubit({
    required GetRunningOvertimeUseCase getRunningOvertimeUseCase,
    required StartOvertimeUseCase startOvertimeUseCase,
    required EndOvertimeUseCase endOvertimeUseCase,
    required GpsService gpsService,
    required SelfieCaptureService selfieCaptureService,
    required AddressResolverService addressResolverService,
    required DeviceTimeGuardService deviceTimeGuard,
    required GpsAddressSyncService gpsAddressSync,
    required PreferencesService preferencesService,
    required ConnectivityService connectivityService,
    required SessionQueryCache sessionQueryCache,
    required OvertimeLocalDataSource localDataSource,
  })  : _getRunningOvertimeUseCase = getRunningOvertimeUseCase,
        _startOvertimeUseCase = startOvertimeUseCase,
        _endOvertimeUseCase = endOvertimeUseCase,
        _gpsService = gpsService,
        _selfieCaptureService = selfieCaptureService,
        _addressResolverService = addressResolverService,
        _deviceTimeGuard = deviceTimeGuard,
        _gpsAddressSync = gpsAddressSync,
        _preferencesService = preferencesService,
        _connectivityService = connectivityService,
        _sessionQueryCache = sessionQueryCache,
        _localDataSource = localDataSource,
        super(const OvertimeState());

  static const String _runningCacheKey = 'overtime:running';

  final GetRunningOvertimeUseCase _getRunningOvertimeUseCase;
  final StartOvertimeUseCase _startOvertimeUseCase;
  final EndOvertimeUseCase _endOvertimeUseCase;
  final GpsService _gpsService;
  final SelfieCaptureService _selfieCaptureService;
  final AddressResolverService _addressResolverService;
  final DeviceTimeGuardService _deviceTimeGuard;
  final GpsAddressSyncService _gpsAddressSync;
  final PreferencesService _preferencesService;
  final ConnectivityService _connectivityService;
  final SessionQueryCache _sessionQueryCache;
  final OvertimeLocalDataSource _localDataSource;

  Timer? _tickTimer;

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

  Future<void> endSession() async {
    final session = state.session;
    if (session == null || !session.isRunning || state.isBusy) {
      return;
    }

    emit(
      state.copyWith(
        status: OvertimeLoadStatus.actionInProgress,
        busyAction: OvertimeBusyAction.end,
        clearMessage: true,
      ),
    );

    try {
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
        return;
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
        return;
      }

      var gps = _toGpsSnapshot(reading, trustedUtc: timeCheck.trustedUtc);
      final geocodeFuture = _addressResolverService.resolveStructured(gps);

      late final List<int> photo;
      try {
        photo = await _selfieCaptureService.captureLivePhoto();
      } on LivePhotoRequiredException {
        emit(
          state.copyWith(
            status: OvertimeLoadStatus.ready,
            clearBusyAction: true,
            message: 'livePhotoRequired',
            isError: true,
          ),
        );
        return;
      } on CameraUnavailableException {
        emit(
          state.copyWith(
            status: OvertimeLoadStatus.ready,
            clearBusyAction: true,
            message: 'cameraUnavailable',
            isError: true,
          ),
        );
        return;
      }

      String? address;
      try {
        final resolved = await geocodeFuture;
        gps = _addressResolverService.apply(gps, resolved);
        address = resolved.isResolved ? resolved.fullAddress : null;
      } on Object {
        // Keep coordinates; address may resolve later during sync.
      }

      final deviceId =
          _preferencesService.getString(StorageKeys.deviceId) ?? 'unknown-device';

      final result = await _endOvertimeUseCase(
        sessionId: session.id,
        gps: gps,
        photoBytes: photo,
        deviceId: deviceId,
        address: address,
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
              currentAddress: ended.endAddress ?? address,
              elapsedSeconds: 0,
              message: offlineQueued ? null : 'overtimeEnded',
              clearMessage: offlineQueued,
              isError: false,
              isOffline: offlineQueued,
            ),
          );
          unawaited(_deviceTimeGuard.syncSecurityEvents());
          unawaited(_gpsAddressSync.processQueue());
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

    emit(
      state.copyWith(
        status: OvertimeLoadStatus.actionInProgress,
        busyAction: busyAction,
        clearMessage: true,
        clearCompleted: true,
      ),
    );

    try {
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
        return;
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
        return;
      }

      var gps = _toGpsSnapshot(reading, trustedUtc: timeCheck.trustedUtc);
      final geocodeFuture = _addressResolverService.resolveStructured(gps);

      late final List<int> photo;
      try {
        photo = await _selfieCaptureService.captureLivePhoto();
      } on LivePhotoRequiredException {
        emit(
          state.copyWith(
            status: OvertimeLoadStatus.ready,
            clearBusyAction: true,
            message: 'livePhotoRequired',
            isError: true,
          ),
        );
        return;
      } on CameraUnavailableException {
        emit(
          state.copyWith(
            status: OvertimeLoadStatus.ready,
            clearBusyAction: true,
            message: 'cameraUnavailable',
            isError: true,
          ),
        );
        return;
      }

      String? address;
      try {
        final resolved = await geocodeFuture;
        gps = _addressResolverService.apply(gps, resolved);
        address = resolved.isResolved ? resolved.fullAddress : null;
      } on Object {
        // Coordinates-only is fine; sync can enrich later.
      }

      final deviceId =
          _preferencesService.getString(StorageKeys.deviceId) ?? 'unknown-device';
      final clientRequestId =
          'ot-$deviceId-${DateTime.now().millisecondsSinceEpoch}';

      final result = await _startOvertimeUseCase(
        type: type,
        gps: gps,
        photoBytes: photo,
        deviceId: deviceId,
        clientRequestId: clientRequestId,
        address: address,
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
              currentAddress: session.startAddress ?? address,
              elapsedSeconds: session.elapsedSeconds,
              message: offlineQueued
                  ? null
                  : (type == OvertimeType.travel
                      ? 'travelOvertimeStarted'
                      : 'normalOvertimeStarted'),
              clearMessage: offlineQueued,
              isError: false,
              isOffline: offlineQueued,
            ),
          );
          _startTicker(session.startAt);
          unawaited(_deviceTimeGuard.syncSecurityEvents());
          unawaited(_gpsAddressSync.processQueue());
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
  }

  void _stopTicker() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  @override
  Future<void> close() {
    _stopTicker();
    return super.close();
  }
}
