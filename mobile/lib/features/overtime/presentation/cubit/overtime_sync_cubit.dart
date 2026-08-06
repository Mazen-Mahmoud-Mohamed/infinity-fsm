import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/services/overtime_upload_policy_service.dart';
import 'package:mobile/features/overtime/domain/usecases/sync_pending_overtime_usecase.dart';
import 'package:mobile/features/overtime/data/trace/overtime_offline_trace.dart';

enum OvertimeSyncStatus { idle, syncing, success, failure }

class OvertimeSyncState extends Equatable {
  const OvertimeSyncState({
    this.status = OvertimeSyncStatus.idle,
    this.pendingCount = 0,
    this.pendingActions = const [],
    this.isOnline = true,
    this.message,
  });

  final OvertimeSyncStatus status;
  final int pendingCount;
  final List<PendingOvertimeAction> pendingActions;
  final bool isOnline;
  final String? message;

  OvertimeSyncState copyWith({
    OvertimeSyncStatus? status,
    int? pendingCount,
    List<PendingOvertimeAction>? pendingActions,
    bool? isOnline,
    String? message,
    bool clearMessage = false,
  }) {
    return OvertimeSyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      pendingActions: pendingActions ?? this.pendingActions,
      isOnline: isOnline ?? this.isOnline,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props =>
      [status, pendingCount, pendingActions, isOnline, message];
}

class OvertimeSyncCubit extends Cubit<OvertimeSyncState> {
  OvertimeSyncCubit({
    required SyncPendingOvertimeUseCase syncUseCase,
    required OvertimeRepository repository,
    required ConnectivityService connectivity,
    required GpsAddressSyncService gpsAddressSync,
    required OvertimeUploadPolicyService uploadPolicy,
  })  : _syncUseCase = syncUseCase,
        _repository = repository,
        _connectivity = connectivity,
        _gpsAddressSync = gpsAddressSync,
        _uploadPolicy = uploadPolicy,
        super(const OvertimeSyncState()) {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((isOnline) {
      OvertimeOfflineTrace.step(
        'CONNECTIVITY',
        status: isOnline ? 'success' : 'failure',
        detail: isOnline ? 'restored' : 'lost',
      );
      emit(state.copyWith(isOnline: isOnline));
      if (isOnline) {
        unawaited(syncNow());
      }
    });

    _retryTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => syncNow(),
    );

    unawaited(refreshPendingCount());
  }

  final SyncPendingOvertimeUseCase _syncUseCase;
  final OvertimeRepository _repository;
  final ConnectivityService _connectivity;
  final GpsAddressSyncService _gpsAddressSync;
  final OvertimeUploadPolicyService _uploadPolicy;
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _isSyncing = false;

  Future<void> refreshPendingCount() async {
    final pending = await _repository.getPendingActions();
    if (isClosed) {
      return;
    }
    emit(state.copyWith(pendingCount: pending.length, pendingActions: pending));
  }

  Future<void> syncNow({bool force = false}) async {
    if (_isSyncing || isClosed) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: _isSyncing ? 'already syncing' : 'cubit closed',
      );
      return;
    }

    if (!await _connectivity.isConnected) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'offline',
      );
      emit(state.copyWith(isOnline: false));
      return;
    }

    if (!force && !await _uploadPolicy.shouldAutoSync()) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'upload policy deferred',
      );
      return;
    }

    final pendingBefore = await _repository.getPendingActions();
    OvertimeOfflineTrace.step(
      'SYNC_SCHEDULER',
      status: 'entered',
      queueLength: pendingBefore.length,
      detail: 'connectivity online',
    );
    if (pendingBefore.isEmpty) {
      unawaited(_gpsAddressSync.processQueue());
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OvertimeSyncStatus.idle,
            pendingCount: 0,
            pendingActions: const [],
            isOnline: true,
          ),
        );
      }
      return;
    }

    _isSyncing = true;
    emit(state.copyWith(status: OvertimeSyncStatus.syncing, isOnline: true));

    try {
      final result = await _syncUseCase();
      unawaited(_gpsAddressSync.processQueue());
      if (isClosed) {
        return;
      }

      switch (result) {
        case Success(data: final synced):
          final pending = await _repository.getPendingActions();
          OvertimeOfflineTrace.step(
            'SYNC_SCHEDULER',
            status: 'success',
            queueLength: pending.length,
            detail: 'syncedCount=$synced',
          );
          emit(
            state.copyWith(
              status: OvertimeSyncStatus.success,
              pendingCount: pending.length,
              pendingActions: pending,
              clearMessage: true,
            ),
          );
        case Failure(message: final message, code: final code):
          final offline = code == 'OFFLINE' ||
              code == 'TIMEOUT' ||
              code == 'NETWORK_ERROR';
          OvertimeOfflineTrace.step(
            'SYNC_SCHEDULER',
            status: 'failure',
            detail: 'code=$code message=$message',
          );
          emit(
            state.copyWith(
              status: OvertimeSyncStatus.failure,
              clearMessage: offline,
              message: offline ? null : message,
              isOnline: !offline,
            ),
          );
      }
    } on Object catch (error) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: error.toString(),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: OvertimeSyncStatus.failure,
            message: error.toString(),
          ),
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<void> close() {
    unawaited(_connectivitySubscription?.cancel());
    _retryTimer?.cancel();
    return super.close();
  }
}
