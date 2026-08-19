import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/services/sync_configuration_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mobile/features/attendance/domain/usecases/sync_pending_attendance_usecase.dart';

enum AttendanceSyncStatus { idle, syncing, success, failure }

class AttendanceSyncState extends Equatable {
  const AttendanceSyncState({
    this.status = AttendanceSyncStatus.idle,
    this.pendingCount = 0,
    this.isOnline = true,
    this.message,
    this.lastSyncedAt,
  });

  final AttendanceSyncStatus status;
  final int pendingCount;
  final bool isOnline;
  final String? message;
  final DateTime? lastSyncedAt;

  AttendanceSyncState copyWith({
    AttendanceSyncStatus? status,
    int? pendingCount,
    bool? isOnline,
    String? message,
    DateTime? lastSyncedAt,
    bool clearMessage = false,
  }) {
    return AttendanceSyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      isOnline: isOnline ?? this.isOnline,
      message: clearMessage ? null : message ?? this.message,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pendingCount,
        isOnline,
        message,
        lastSyncedAt,
      ];
}

/// Watches connectivity and periodically retries attendance events captured
/// while offline, keeping the pending queue synchronized with the server.
class AttendanceSyncCubit extends Cubit<AttendanceSyncState> {
  AttendanceSyncCubit({
    required SyncPendingAttendanceUseCase syncUseCase,
    required AttendanceRepository repository,
    required ConnectivityService connectivity,
    required GpsAddressSyncService gpsAddressSync,
    required SyncConfigurationService syncConfiguration,
  })  : _syncUseCase = syncUseCase,
        _repository = repository,
        _connectivity = connectivity,
        _gpsAddressSync = gpsAddressSync,
        _syncConfiguration = syncConfiguration,
        super(const AttendanceSyncState()) {
    _configSubscription = _syncConfiguration.onChanged.listen((_) {
      _reconfigurePeriodicTimer();
    });

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((isOnline) {
      emit(state.copyWith(isOnline: isOnline));
      if (isOnline && !_paused) {
        unawaited(syncNow(force: true));
      }
    });

    _reconfigurePeriodicTimer();
    unawaited(refreshPendingCount());
  }

  final SyncPendingAttendanceUseCase _syncUseCase;
  final AttendanceRepository _repository;
  final ConnectivityService _connectivity;
  final GpsAddressSyncService _gpsAddressSync;
  final SyncConfigurationService _syncConfiguration;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<SyncConfiguration>? _configSubscription;
  Timer? _retryTimer;
  bool _isSyncing = false;
  bool _paused = false;
  bool _syncRequestedAgain = false;

  void pauseAuthenticatedSync() {
    _paused = true;
    _retryTimer?.cancel();
  }

  void resumeAuthenticatedSync() {
    if (!_paused) {
      return;
    }
    _paused = false;
    _reconfigurePeriodicTimer();
    unawaited(syncNow(force: true));
  }

  void _reconfigurePeriodicTimer() {
    _retryTimer?.cancel();
    if (_paused) {
      return;
    }
    final interval = _syncConfiguration.current.interval;
    _retryTimer = Timer.periodic(interval, (_) {
      if (_paused || !_syncConfiguration.current.autoSync) {
        return;
      }
      unawaited(syncNow());
    });
  }

  Future<void> refreshPendingCount() async {
    final pending = await _repository.getPendingActions();
    if (isClosed) {
      return;
    }
    emit(state.copyWith(pendingCount: pending.length));
  }

  Future<void> syncNow({bool force = false}) async {
    if (_paused || isClosed) {
      return;
    }

    if (_isSyncing) {
      _syncRequestedAgain = true;
      return;
    }

    final pending = await _repository.getPendingActions();
    if (pending.isEmpty) {
      if (!isClosed) {
        emit(
          state.copyWith(
            pendingCount: 0,
            status: AttendanceSyncStatus.idle,
          ),
        );
      }
      return;
    }

    final snapshot = await _connectivity.refreshStatus(reason: 'attendance_sync');
    if (!snapshot.canSync) {
      if (!isClosed) {
        emit(state.copyWith(isOnline: false));
      }
      return;
    }

    if (!force && !_syncConfiguration.current.autoSync) {
      return;
    }

    _isSyncing = true;
    emit(
      state.copyWith(
        status: AttendanceSyncStatus.syncing,
        pendingCount: pending.length,
        clearMessage: true,
        isOnline: true,
      ),
    );

    try {
      final result = await _syncUseCase();
      unawaited(_gpsAddressSync.processQueue());
      final remaining = await _repository.getPendingActions();

      if (isClosed) {
        return;
      }

      switch (result) {
        case Success():
          emit(
            state.copyWith(
              status: AttendanceSyncStatus.success,
              pendingCount: remaining.length,
              lastSyncedAt: DateTime.now(),
              clearMessage: true,
              isOnline: true,
            ),
          );
        case Failure(message: final message, code: final code):
          final offline = code == 'OFFLINE' ||
              code == 'TIMEOUT' ||
              code == 'NETWORK_ERROR';
          emit(
            state.copyWith(
              status: AttendanceSyncStatus.failure,
              pendingCount: remaining.length,
              isOnline: !offline,
              clearMessage: offline,
              message: offline ? null : message,
            ),
          );
      }

      if (_syncRequestedAgain && remaining.isNotEmpty) {
        _syncRequestedAgain = false;
        unawaited(Future<void>.microtask(() => syncNow(force: force)));
      }
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<void> close() {
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_configSubscription?.cancel());
    _retryTimer?.cancel();
    return super.close();
  }
}
