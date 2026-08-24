import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/attendance_constants.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/device_time_guard_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/services/gps_service.dart';
import 'package:mobile/core/services/selfie_capture_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status_snapshot.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_today.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mobile/features/attendance/domain/usecases/clock_in_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/clock_out_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/end_break_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/get_attendance_status_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/get_attendance_today_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/start_break_usecase.dart';
import 'package:mobile/features/attendance/domain/usecases/sync_pending_attendance_usecase.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_state.dart';

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

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit({
    required this._getStatusUseCase,
    required this._getTodayUseCase,
    required this._clockInUseCase,
    required this._clockOutUseCase,
    required this._startBreakUseCase,
    required this._endBreakUseCase,
    required this._syncPendingUseCase,
    required this._gpsService,
    required this._selfieCaptureService,
    required this._addressResolverService,
    required this._deviceTimeGuard,
    required this._gpsAddressSync,
    required this._preferencesService,
    required this._sessionQueryCache,
    required this._localDataSource,
  }) : super(const AttendanceState());

  static const String _statusCacheKey = 'attendance:status';
  static const String _todayCacheKey = 'attendance:today';

  final GetAttendanceStatusUseCase _getStatusUseCase;
  final GetAttendanceTodayUseCase _getTodayUseCase;
  final ClockInUseCase _clockInUseCase;
  final ClockOutUseCase _clockOutUseCase;
  final StartBreakUseCase _startBreakUseCase;
  final EndBreakUseCase _endBreakUseCase;
  final SyncPendingAttendanceUseCase _syncPendingUseCase;
  final GpsService _gpsService;
  final SelfieCaptureService _selfieCaptureService;
  final AddressResolverService _addressResolverService;
  final DeviceTimeGuardService _deviceTimeGuard;
  final GpsAddressSyncService _gpsAddressSync;
  final PreferencesService _preferencesService;
  final SessionQueryCache _sessionQueryCache;
  final AttendanceLocalDataSource _localDataSource;

  Timer? _tickTimer;
  Timer? _pollTimer;
  Future<void>? _initializeInFlight;
  bool _sessionActive = false;

  /// Clears timers/state when the user logs out. Singleton survives navigation.
  void resetForLogout() {
    _tickTimer?.cancel();
    _pollTimer?.cancel();
    _tickTimer = null;
    _pollTimer = null;
    _initializeInFlight = null;
    _sessionActive = false;
    if (!isClosed) {
      emit(const AttendanceState());
    }
  }

  Future<void> initialize() async {
    if (_initializeInFlight != null) {
      await _initializeInFlight;
      return;
    }
    if (_sessionActive && state.status != null) {
      // Shared across Dashboard summary + Attendance tab — avoid duplicate
      // status/today fetches and dual 30s polls.
      return;
    }

    _initializeInFlight = _initializeBody();
    try {
      await _initializeInFlight;
    } finally {
      _initializeInFlight = null;
    }
  }

  Future<void> _initializeBody() async {
    final cachedStatus =
        _sessionQueryCache.get<AttendanceStatusSnapshot>(_statusCacheKey) ??
            _localDataSource.readStatus();
    final cachedToday =
        _sessionQueryCache.get<AttendanceToday>(_todayCacheKey) ??
            _localDataSource.readToday();
    final hasData = cachedStatus != null || state.status != null;

    if (hasData) {
      emit(
        state.copyWith(
          loadStatus: AttendanceLoadStatus.ready,
          status: cachedStatus ?? state.status,
          today: cachedToday ?? state.today,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loadStatus: AttendanceLoadStatus.loading,
          isRefreshing: false,
        ),
      );
    }

    unawaited(_deviceTimeGuard.syncSecurityEvents());
    await Future.wait([
      _loadStatus(),
      _loadToday(),
    ]);
    if (!isClosed) {
      emit(state.copyWith(isRefreshing: false));
    }
    _sessionActive = true;
    _startTimers();
  }

  Future<void> refresh() async {
    final hasData = state.status != null;
    emit(
      state.copyWith(
        isRefreshing: hasData,
        loadStatus: hasData
            ? AttendanceLoadStatus.ready
            : AttendanceLoadStatus.loading,
      ),
    );
    await Future.wait([
      _loadStatus(forceRefresh: true),
      _loadToday(forceRefresh: true),
    ]);
    if (!isClosed) {
      emit(state.copyWith(isRefreshing: false));
    }
  }

  Future<void> clockIn() {
    return _performAction(
      requiresSelfie: true,
      submit: (gps, selfieBytes, deviceId) => _clockInUseCase(
        gps: gps,
        selfieBytes: selfieBytes,
        deviceId: deviceId,
      ),
    );
  }

  Future<void> clockOut() {
    return _performAction(
      requiresSelfie: true,
      submit: (gps, selfieBytes, deviceId) => _clockOutUseCase(
        gps: gps,
        selfieBytes: selfieBytes,
        deviceId: deviceId,
      ),
    );
  }

  Future<void> startBreak() {
    return _performAction(
      requiresSelfie: false,
      submit: (gps, selfieBytes, deviceId) => _startBreakUseCase(
        gps: gps,
        deviceId: deviceId,
      ),
    );
  }

  Future<void> endBreak() {
    return _performAction(
      requiresSelfie: false,
      submit: (gps, selfieBytes, deviceId) => _endBreakUseCase(
        gps: gps,
        deviceId: deviceId,
      ),
    );
  }

  Future<void> _performAction({
    required bool requiresSelfie,
    required Future<Result<AttendanceActionOutcome>> Function(
      GpsSnapshot gps,
      List<int> selfieBytes,
      String deviceId,
    ) submit,
  }) async {
    emit(
      state.copyWith(
        loadStatus: AttendanceLoadStatus.actionInProgress,
        clearMessage: true,
      ),
    );

    try {
      final timeCheck = await _deviceTimeGuard.validate(
        lastAttendanceAt: state.status?.clockInAt ?? state.status?.clockOutAt,
        module: 'attendance',
      );
      if (!timeCheck.isValid) {
        emit(
          state.copyWith(
            loadStatus: AttendanceLoadStatus.ready,
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
            loadStatus: AttendanceLoadStatus.ready,
            message: 'gpsAccuracyTooLow',
            isError: true,
          ),
        );
        return;
      }

      var gps = _toGpsSnapshot(reading, trustedUtc: timeCheck.trustedUtc);
      // Start reverse-geocoding in parallel with the camera so the critical
      // path is not blocked by placemark lookup.
      final geocodeFuture = _addressResolverService.resolveStructured(gps);

      var selfieBytes = const <int>[];
      if (requiresSelfie) {
        try {
          selfieBytes = await _selfieCaptureService.captureLivePhoto();
        } on LivePhotoRequiredException {
          emit(
            state.copyWith(
              loadStatus: AttendanceLoadStatus.ready,
              message: 'livePhotoRequired',
              isError: true,
            ),
          );
          return;
        } on CameraUnavailableException {
          emit(
            state.copyWith(
              loadStatus: AttendanceLoadStatus.ready,
              message: 'cameraUnavailable',
              isError: true,
            ),
          );
          return;
        }
      }

      try {
        final resolved = await geocodeFuture;
        gps = _addressResolverService.apply(gps, resolved);
      } on Object {
        // Coordinates-only is acceptable; address sync retries later.
      }

      final deviceId =
          _preferencesService.getString(StorageKeys.deviceId) ?? 'unknown-device';

      final result = await submit(gps, selfieBytes, deviceId);
      _handleActionResult(result);
    } on LocationException catch (error) {
      emit(
        state.copyWith(
          loadStatus: AttendanceLoadStatus.ready,
          message: error.message,
          isError: true,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          loadStatus: AttendanceLoadStatus.ready,
          message: 'errorGeneric',
          isError: true,
        ),
      );
    }
  }

  void _handleActionResult(Result<AttendanceActionOutcome> result) {
    switch (result) {
      case Success(data: final outcome):
        unawaited(
          _deviceTimeGuard.rememberSuccessfulAttendance(DateTime.now().toUtc()),
        );
        emit(
          state.copyWith(
            loadStatus: AttendanceLoadStatus.ready,
            status: outcome.status,
            message: outcome.queuedOffline ? null : 'attendanceUpdated',
            clearMessage: outcome.queuedOffline,
            isError: false,
            isOffline: outcome.queuedOffline,
          ),
        );
        unawaited(_loadToday(forceRefresh: true));
        if (outcome.queuedOffline) {
          unawaited(_syncPendingUseCase());
        }
        unawaited(_deviceTimeGuard.syncSecurityEvents());
        unawaited(_gpsAddressSync.processQueue());
      case Failure(message: final message, code: final code):
        final offline = code == 'OFFLINE' ||
            code == 'TIMEOUT' ||
            code == 'NETWORK_ERROR';
        emit(
          state.copyWith(
            loadStatus: AttendanceLoadStatus.ready,
            message: offline ? null : message,
            clearMessage: offline,
            isError: !offline,
            isOffline: offline,
          ),
        );
    }
  }

  Future<void> _loadStatus({bool forceRefresh = false}) async {
    final result = await _getStatusUseCase(forceRefresh: forceRefresh);
    switch (result) {
      case Success(data: final status):
        _sessionQueryCache.set(_statusCacheKey, status);
        emit(
          state.copyWith(
            loadStatus: AttendanceLoadStatus.ready,
            status: status,
            isOffline: false,
          ),
        );
      case Failure(message: final message, code: final code):
        final offline = code == 'OFFLINE' ||
            code == 'TIMEOUT' ||
            code == 'NETWORK_ERROR';
        emit(
          state.copyWith(
            loadStatus: state.status == null && !offline
                ? AttendanceLoadStatus.failure
                : AttendanceLoadStatus.ready,
            isOffline: offline,
            message: offline ? null : message,
            clearMessage: offline,
            isError: !offline,
          ),
        );
    }
  }

  Future<void> _loadToday({bool forceRefresh = false}) async {
    final result = await _getTodayUseCase(forceRefresh: forceRefresh);
    switch (result) {
      case Success(data: final today):
        _sessionQueryCache.set(_todayCacheKey, today);
        emit(state.copyWith(today: today));
      case Failure():
        break;
    }
  }

  void _startTimers() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(AttendanceConstants.timerTickInterval, (_) {
      final status = state.status;
      if (status == null || status.status != AttendanceStatus.clockedIn) {
        return;
      }
      emit(
        state.copyWith(
          status: status.copyWith(
            liveWorkingSeconds: status.liveWorkingSeconds + 1,
          ),
        ),
      );
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      AttendanceConstants.statusPollInterval,
      (_) => _loadStatus(),
    );
  }

  @override
  Future<void> close() {
    _tickTimer?.cancel();
    _pollTimer?.cancel();
    return super.close();
  }
}
