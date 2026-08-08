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

/// Serializes overtime pending-queue uploads.
///
/// Concurrent [syncNow] calls while a cycle is running are coalesced into a
/// single follow-up pass so actions enqueued mid-sync (e.g. Finish Work) are
/// never discarded.
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

  /// Set when [syncNow] is requested while a cycle is already running.
  bool _syncRequestedAgain = false;

  /// Safety cap for follow-up cycles within one worker entry.
  static const int _maxCyclesPerEntry = 8;

  Future<void> refreshPendingCount() async {
    final pending = await _repository.getPendingActions();
    if (isClosed) {
      return;
    }
    emit(state.copyWith(pendingCount: pending.length, pendingActions: pending));
  }

  Future<void> syncNow({bool force = false}) async {
    if (isClosed) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'cubit closed',
      );
      return;
    }

    if (_isSyncing) {
      _syncRequestedAgain = true;
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'already syncing | queued follow-up request',
        queueLength: state.pendingCount,
      );
      return;
    }

    if (!await _connectivity.isConnected) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'offline',
      );
      if (!isClosed) {
        emit(state.copyWith(isOnline: false));
      }
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

    _isSyncing = true;
    if (!isClosed) {
      emit(state.copyWith(status: OvertimeSyncStatus.syncing, isOnline: true));
    }

    try {
      OvertimeOfflineTrace.step(
        'SYNC_LOOP',
        status: 'entered',
        detail: 'started',
      );

      var cycles = 0;
      while (!isClosed && cycles < _maxCyclesPerEntry) {
        cycles += 1;
        _syncRequestedAgain = false;

        if (!await _connectivity.isConnected) {
          OvertimeOfflineTrace.step(
            'SYNC_LOOP',
            status: 'failure',
            detail: 'offline mid-loop',
          );
          if (!isClosed) {
            emit(state.copyWith(isOnline: false));
          }
          break;
        }

        final pendingBefore = await _repository.getPendingActions();
        if (pendingBefore.isEmpty) {
          unawaited(_gpsAddressSync.processQueue());
          OvertimeOfflineTrace.step(
            'SYNC_LOOP',
            status: 'success',
            queueLength: 0,
            detail: 'drained',
          );
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
          break;
        }

        for (final action in pendingBefore) {
          OvertimeOfflineTrace.step(
            'SYNC_LOOP',
            status: 'entered',
            objectId: action.id,
            detail: 'processing | type=${action.type.name}',
            queueLength: pendingBefore.length,
          );
        }

        OvertimeOfflineTrace.step(
          'SYNC_SCHEDULER',
          status: 'entered',
          queueLength: pendingBefore.length,
          detail: 'connectivity online | cycle=$cycles',
        );

        late final Result<int> result;
        try {
          result = await _syncUseCase();
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
          // Still honour coalesced requests after an unexpected throw.
          if (_syncRequestedAgain) {
            OvertimeOfflineTrace.step(
              'SYNC_LOOP',
              status: 'entered',
              detail: 'follow-up required',
            );
            OvertimeOfflineTrace.step(
              'SYNC_SCHEDULER',
              status: 'entered',
              detail: 'follow-up started',
            );
            continue;
          }
          break;
        }

        unawaited(_gpsAddressSync.processQueue());
        if (isClosed) {
          break;
        }

        final pendingAfter = await _repository.getPendingActions();
        OvertimeOfflineTrace.step(
          'SYNC_LOOP',
          status: 'success',
          queueLength: pendingAfter.length,
          detail: 'completed | remainingQueue=${pendingAfter.length}',
        );

        var syncedCount = 0;
        var hardFailure = false;
        var offlineFailure = false;

        switch (result) {
          case Success(data: final synced):
            syncedCount = synced;
            OvertimeOfflineTrace.step(
              'SYNC_SCHEDULER',
              status: 'success',
              queueLength: pendingAfter.length,
              detail: 'syncedCount=$synced | cycle=$cycles',
            );
            if (!isClosed) {
              emit(
                state.copyWith(
                  status: pendingAfter.isEmpty
                      ? OvertimeSyncStatus.success
                      : OvertimeSyncStatus.syncing,
                  pendingCount: pendingAfter.length,
                  pendingActions: pendingAfter,
                  clearMessage: true,
                  isOnline: true,
                ),
              );
            }
          case Failure(message: final message, code: final code):
            hardFailure = true;
            offlineFailure = code == 'OFFLINE' ||
                code == 'TIMEOUT' ||
                code == 'NETWORK_ERROR';
            OvertimeOfflineTrace.step(
              'SYNC_SCHEDULER',
              status: 'failure',
              detail: 'code=$code message=$message',
              queueLength: pendingAfter.length,
            );
            if (!isClosed) {
              emit(
                state.copyWith(
                  status: OvertimeSyncStatus.failure,
                  pendingCount: pendingAfter.length,
                  pendingActions: pendingAfter,
                  clearMessage: offlineFailure,
                  message: offlineFailure ? null : message,
                  isOnline: !offlineFailure,
                ),
              );
            }
        }

        if (pendingAfter.isEmpty && !_syncRequestedAgain) {
          OvertimeOfflineTrace.step(
            'SYNC_LOOP',
            status: 'success',
            queueLength: 0,
            detail: 'drained',
          );
          break;
        }

        // Coalesced enqueue during this cycle — must process new snapshot.
        if (_syncRequestedAgain) {
          OvertimeOfflineTrace.step(
            'SYNC_LOOP',
            status: 'entered',
            queueLength: pendingAfter.length,
            detail: 'follow-up required',
          );
          OvertimeOfflineTrace.step(
            'SYNC_SCHEDULER',
            status: 'entered',
            queueLength: pendingAfter.length,
            detail: 'follow-up started',
          );
          continue;
        }

        // Made progress with leftovers (e.g. START then mid-stage on next
        // snapshot) — one more pass. Stop on no-progress to avoid spinning
        // forever on a legitimate blocking API error.
        if (!hardFailure &&
            !offlineFailure &&
            syncedCount > 0 &&
            pendingAfter.isNotEmpty) {
          OvertimeOfflineTrace.step(
            'SYNC_LOOP',
            status: 'entered',
            queueLength: pendingAfter.length,
            detail: 'follow-up required',
          );
          continue;
        }

        break;
      }
    } finally {
      _isSyncing = false;
      // Race: another caller set the flag after the loop last cleared it while
      // we still held _isSyncing. Schedule exactly one non-recursive follow-up.
      if (_syncRequestedAgain && !isClosed) {
        _syncRequestedAgain = false;
        OvertimeOfflineTrace.step(
          'SYNC_SCHEDULER',
          status: 'entered',
          detail: 'follow-up started',
        );
        unawaited(Future<void>.microtask(() => syncNow(force: force)));
      }
    }
  }

  @override
  Future<void> close() {
    unawaited(_connectivitySubscription?.cancel());
    _retryTimer?.cancel();
    return super.close();
  }
}
