import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/services/sync_configuration_service.dart';
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
    required SyncConfigurationService syncConfiguration,
  })  : _syncUseCase = syncUseCase,
        _repository = repository,
        _connectivity = connectivity,
        _gpsAddressSync = gpsAddressSync,
        _uploadPolicy = uploadPolicy,
        _syncConfiguration = syncConfiguration,
        super(const OvertimeSyncState()) {
    _configSubscription = _syncConfiguration.onChanged.listen((_) {
      _reconfigurePeriodicTimer();
    });

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((isOnline) {
      OvertimeOfflineTrace.step(
        'CONNECTIVITY',
        status: isOnline ? 'success' : 'failure',
        detail: isOnline ? 'restored' : 'lost',
      );
      emit(state.copyWith(isOnline: isOnline));
      if (isOnline && !_paused) {
        unawaited(syncNow(force: true, reason: 'connectivity_restored'));
      }
    });

    _reconfigurePeriodicTimer();
    unawaited(refreshPendingCount());
  }

  final SyncPendingOvertimeUseCase _syncUseCase;
  final OvertimeRepository _repository;
  final ConnectivityService _connectivity;
  final GpsAddressSyncService _gpsAddressSync;
  final OvertimeUploadPolicyService _uploadPolicy;
  final SyncConfigurationService _syncConfiguration;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<SyncConfiguration>? _configSubscription;
  Timer? _retryTimer;

  bool _isSyncing = false;
  bool _paused = false;

  /// Set when [syncNow] is requested while a cycle is already running.
  bool _syncRequestedAgain = false;

  /// Safety cap for follow-up cycles within one worker entry.
  static const int _maxCyclesPerEntry = 8;

  void pauseAuthenticatedSync() {
    _paused = true;
    _retryTimer?.cancel();
    OvertimeOfflineTrace.step(
      'SYNC_SCHEDULER',
      status: 'failure',
      detail: 'paused (logout)',
    );
  }

  void resumeAuthenticatedSync() {
    if (!_paused) {
      return;
    }
    _paused = false;
    _reconfigurePeriodicTimer();
    OvertimeOfflineTrace.step(
      'SYNC_SCHEDULER',
      status: 'entered',
      detail: 'resumed (login)',
    );
    unawaited(syncNow(force: true, reason: 'login'));
  }

  void _reconfigurePeriodicTimer() {
    _retryTimer?.cancel();
    if (_paused) {
      return;
    }

    final interval = _syncConfiguration.current.interval;
    OvertimeOfflineTrace.step(
      'SYNC_SCHEDULER',
      status: 'entered',
      detail: 'interval=${interval.inMinutes}m',
    );

    _retryTimer = Timer.periodic(interval, (_) {
      if (_paused || !_syncConfiguration.current.autoSync) {
        return;
      }
      OvertimeOfflineTrace.step('SYNC_SCHEDULER', status: 'entered', detail: 'timer tick');
      unawaited(syncNow(reason: 'timer'));
    });
  }

  Future<void> refreshPendingCount() async {
    final pending = await _repository.getPendingActions();
    if (isClosed) {
      return;
    }
    emit(state.copyWith(pendingCount: pending.length, pendingActions: pending));
  }

  Future<void> syncNow({
    bool force = false,
    String reason = 'manual',
  }) async {
    if (isClosed) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'cubit closed',
      );
      return;
    }

    if (_paused) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'paused',
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

    final pending = await _repository.getPendingActions();
    if (pending.isEmpty && !force) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'success',
        detail: 'queue empty',
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            pendingCount: 0,
            pendingActions: const [],
            status: OvertimeSyncStatus.idle,
          ),
        );
      }
      return;
    }

    final snapshot = await _connectivity.refreshStatus(reason: 'sync_$reason');
    if (!snapshot.canSync) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'deferred | level=${snapshot.level.name} reason=${snapshot.reason}',
      );
      if (!isClosed) {
        emit(state.copyWith(isOnline: false));
      }
      return;
    }

    if (!force && !_syncConfiguration.current.autoSync) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'auto sync disabled',
      );
      return;
    }

    if (!force && _syncConfiguration.current.wifiOnlySync &&
        !await _uploadPolicy.isWifi) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'wifi-only preference',
      );
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
        detail: 'started | trigger=$reason',
      );

      var cycles = 0;
      while (!isClosed && cycles < _maxCyclesPerEntry) {
        cycles += 1;
        _syncRequestedAgain = false;

        final loopSnapshot =
            await _connectivity.refreshStatus(reason: 'sync_loop');
        if (!loopSnapshot.canSync) {
          OvertimeOfflineTrace.step(
            'SYNC_LOOP',
            status: 'failure',
            detail: 'api unavailable mid-loop',
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
            'SYNC_ITEM_START',
            status: 'entered',
            objectId: action.id,
            detail: 'type=${action.type.name}',
            queueLength: pendingBefore.length,
          );
        }

        OvertimeOfflineTrace.step(
          'SYNC_SCHEDULER',
          status: 'entered',
          queueLength: pendingBefore.length,
          detail: 'api online | cycle=$cycles | trigger=$reason',
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
          if (_syncRequestedAgain) {
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
              'SYNC_ITEM_SUCCESS',
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
              'SYNC_ITEM_FAILURE',
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
          break;
        }

        if (_syncRequestedAgain) {
          continue;
        }

        if (!hardFailure &&
            !offlineFailure &&
            syncedCount > 0 &&
            pendingAfter.isNotEmpty) {
          continue;
        }

        break;
      }
    } finally {
      _isSyncing = false;
      if (_syncRequestedAgain && !isClosed) {
        _syncRequestedAgain = false;
        unawaited(Future<void>.microtask(() => syncNow(force: force, reason: reason)));
      }
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
