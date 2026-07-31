import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/constants/attendance_constants.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
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

/// Watches connectivity and periodically retries any attendance events that
/// were captured while offline, keeping the pending queue synchronized with
/// the server without blocking the UI thread.
class AttendanceSyncCubit extends Cubit<AttendanceSyncState> {
  AttendanceSyncCubit({
    required this._syncUseCase,
    required this._repository,
    required this._connectivity,
    required this._gpsAddressSync,
  }) : super(const AttendanceSyncState()) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      isOnline,
    ) {
      emit(state.copyWith(isOnline: isOnline));
      if (isOnline) {
        unawaited(syncNow());
      }
    });

    _retryTimer = Timer.periodic(
      AttendanceConstants.syncRetryInterval,
      (_) => syncNow(),
    );

    unawaited(refreshPendingCount());
  }

  final SyncPendingAttendanceUseCase _syncUseCase;
  final AttendanceRepository _repository;
  final ConnectivityService _connectivity;
  final GpsAddressSyncService _gpsAddressSync;
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _isSyncing = false;

  Future<void> refreshPendingCount() async {
    final pending = await _repository.getPendingActions();
    if (isClosed) {
      return;
    }
    emit(state.copyWith(pendingCount: pending.length));
  }

  Future<void> syncNow() async {
    if (_isSyncing || isClosed) {
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

    _isSyncing = true;
    emit(
      state.copyWith(
        status: AttendanceSyncStatus.syncing,
        pendingCount: pending.length,
        clearMessage: true,
      ),
    );

    final result = await _syncUseCase();
    unawaited(_gpsAddressSync.processQueue());
    final remaining = await _repository.getPendingActions();

    if (isClosed) {
      _isSyncing = false;
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

    _isSyncing = false;
  }

  @override
  Future<void> close() {
    unawaited(_connectivitySubscription?.cancel());
    _retryTimer?.cancel();
    return super.close();
  }
}
