import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
///
/// The periodic scheduler is owned by this long-lived cubit (GetIt singleton),
/// not by OvertimePage / OvertimeCubit.
class OvertimeSyncCubit extends Cubit<OvertimeSyncState> {
  OvertimeSyncCubit({
    required SyncPendingOvertimeUseCase syncUseCase,
    required OvertimeRepository repository,
    required ConnectivityService connectivity,
    required GpsAddressSyncService gpsAddressSync,
    required OvertimeUploadPolicyService uploadPolicy,
    required SyncConfigurationService syncConfiguration,
    @visibleForTesting Duration? periodicIntervalOverride,
  })  : _syncUseCase = syncUseCase,
        _repository = repository,
        _connectivity = connectivity,
        _gpsAddressSync = gpsAddressSync,
        _uploadPolicy = uploadPolicy,
        _syncConfiguration = syncConfiguration,
        _periodicIntervalOverride = periodicIntervalOverride,
        super(const OvertimeSyncState()) {
    // ignore: avoid_print
    debugPrint(
      '[SYNC_DEBUG] OvertimeSyncCubit CREATED hash=$hashCode '
      'override=${_periodicIntervalOverride?.inSeconds}',
    );

    _configSubscription = _syncConfiguration.onChanged.listen((config) {
      _onSyncConfigurationChanged(config);
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

    // Starts paused — do not arm until [resumeAuthenticatedSync].
    unawaited(refreshPendingCount());
  }

  final SyncPendingOvertimeUseCase _syncUseCase;
  final OvertimeRepository _repository;
  final ConnectivityService _connectivity;
  final GpsAddressSyncService _gpsAddressSync;
  final OvertimeUploadPolicyService _uploadPolicy;
  final SyncConfigurationService _syncConfiguration;

  /// Test/debug only. Production builds leave this null so Sync Settings win.
  final Duration? _periodicIntervalOverride;

  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<SyncConfiguration>? _configSubscription;
  Timer? _retryTimer;

  /// Interval/autoSync/wifiOnly that the active timer was armed with.
  int? _armedIntervalMinutes;
  bool? _armedAutoSync;
  bool? _armedWifiOnly;

  bool _isSyncing = false;

  /// Starts paused until [resumeAuthenticatedSync] after login / session restore.
  bool _paused = true;

  /// Set when [syncNow] is requested while a cycle is already running.
  bool _syncRequestedAgain = false;

  /// Safety cap for follow-up cycles within one worker entry.
  static const int _maxCyclesPerEntry = 8;

  /// Compile-time debug override: `--dart-define=SYNC_DEBUG_INTERVAL_SECONDS=10`
  /// Production APK must leave this unset (0).
  static const int debugIntervalSeconds = int.fromEnvironment(
    'SYNC_DEBUG_INTERVAL_SECONDS',
    defaultValue: 0,
  );

  bool get isPeriodicTimerActive => _retryTimer?.isActive ?? false;

  Duration get _effectivePeriodicInterval {
    final override = _periodicIntervalOverride;
    if (override != null) {
      return override;
    }
    if (debugIntervalSeconds > 0) {
      return Duration(seconds: debugIntervalSeconds);
    }
    return _syncConfiguration.current.interval;
  }

  void pauseAuthenticatedSync() {
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] pauseAuthenticatedSync()');
    _paused = true;
    _cancelPeriodicTimer(reason: 'pause');
    OvertimeOfflineTrace.step(
      'SYNC_SCHEDULER',
      status: 'failure',
      detail: 'paused (logout)',
    );
  }

  /// Arms the configured periodic timer (if needed) and drains the queue.
  ///
  /// Repeated calls while already running **must not** reset the countdown —
  /// that was wiping the 5-minute wait whenever resume was invoked again.
  void resumeAuthenticatedSync() {
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] resumeAuthenticatedSync() paused=$_paused '
        'timerActive=$isPeriodicTimerActive');
    final wasPaused = _paused;
    _paused = false;

    if (wasPaused || !isPeriodicTimerActive) {
      _armPeriodicTimer(reason: wasPaused ? 'resume' : 'resume_missing_timer');
    } else {
      // ignore: avoid_print
      debugPrint(
        '[SYNC_DEBUG] scheduler already armed — keeping existing countdown '
        'intervalMinutes=${_armedIntervalMinutes}',
      );
    }

    OvertimeOfflineTrace.step(
      'SYNC_SCHEDULER',
      status: 'entered',
      detail: 'resumed (login)',
    );
    unawaited(syncNow(force: true, reason: 'login'));
  }

  void _onSyncConfigurationChanged(SyncConfiguration config) {
    // ignore: avoid_print
    debugPrint(
      '[SYNC_DEBUG] sync config changed autoSync=${config.autoSync} '
      'intervalMinutes=${config.intervalMinutes} '
      'wifiOnlySync=${config.wifiOnlySync}',
    );
    if (_paused) {
      return;
    }

    final sameInterval = _armedIntervalMinutes == config.intervalMinutes;
    final sameAuto = _armedAutoSync == config.autoSync;
    final sameWifi = _armedWifiOnly == config.wifiOnlySync;
    if (isPeriodicTimerActive && sameInterval && sameAuto && sameWifi) {
      // ignore: avoid_print
      debugPrint('[SYNC_DEBUG] config unchanged — keeping timer countdown');
      return;
    }

    _armPeriodicTimer(reason: 'config_changed');
  }

  void _cancelPeriodicTimer({required String reason}) {
    if (_retryTimer != null) {
      // ignore: avoid_print
      debugPrint(
        '[SYNC_DEBUG] scheduler CANCEL reason=$reason '
        'timer identity=${identityHashCode(_retryTimer)}',
      );
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    _armedIntervalMinutes = null;
    _armedAutoSync = null;
    _armedWifiOnly = null;
  }

  void _armPeriodicTimer({required String reason}) {
    _cancelPeriodicTimer(reason: 'rearm_before_$reason');
    if (_paused) {
      // ignore: avoid_print
      debugPrint('[SYNC_DEBUG] scheduler ARM skipped (paused)');
      return;
    }

    final config = _syncConfiguration.current;
    final interval = _effectivePeriodicInterval;
    _armedIntervalMinutes = config.intervalMinutes;
    _armedAutoSync = config.autoSync;
    _armedWifiOnly = config.wifiOnlySync;

    // ignore: avoid_print
    debugPrint(
      '[SYNC_DEBUG] scheduler ARM reason=$reason '
      'interval = ${interval.inMinutes} minutes '
      '(${interval.inSeconds}s) '
      'autoSync=${config.autoSync} wifiOnlySync=${config.wifiOnlySync}',
    );

    _retryTimer = Timer.periodic(interval, (_) {
      _onPeriodicTick();
    });

    // ignore: avoid_print
    debugPrint(
      '[SYNC_DEBUG] timer identity = ${identityHashCode(_retryTimer)}',
    );

    OvertimeOfflineTrace.step(
      'SYNC_SCHEDULER',
      status: 'entered',
      detail: 'armed interval=${interval.inMinutes}m reason=$reason',
    );
  }

  void _onPeriodicTick() {
    final config = _syncConfiguration.current;
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] PERIODIC TICK');
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] paused = $_paused');
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] autoSync = ${config.autoSync}');
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] intervalMinutes = ${config.intervalMinutes}');
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] wifiOnlySync = ${config.wifiOnlySync}');
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] syncing = $_isSyncing');
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] pendingCount = ${state.pendingCount}');

    if (_paused || !config.autoSync) {
      // ignore: avoid_print
      debugPrint(
        '[SYNC_DEBUG] PERIODIC TICK skipped '
        'reason=${_paused ? 'paused' : 'autoSync_disabled'}',
      );
      return;
    }

    OvertimeOfflineTrace.step(
      'SYNC_SCHEDULER',
      status: 'entered',
      detail: 'timer tick',
    );
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] PERIODIC SYNC START');
    unawaited(syncNow(reason: 'timer').whenComplete(() {
      // ignore: avoid_print
      debugPrint(
        '[SYNC_DEBUG] PERIODIC SYNC END pendingCountAfter=${state.pendingCount}',
      );
    }));
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
      // ignore: avoid_print
      debugPrint('[SYNC_DEBUG] sync skipped — paused');
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
      // ignore: avoid_print
      debugPrint(
        '[SYNC_DEBUG] tick/sync skipped — already syncing (coalesced)',
      );
      return;
    }

    final pending = await _repository.getPendingActions();
    // ignore: avoid_print
    debugPrint(
      '[SYNC_DEBUG] sync started reason=$reason force=$force '
      'pending count = ${pending.length}',
    );
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
    // ignore: avoid_print
    debugPrint(
      '[SYNC_DEBUG] connectivity snapshot = level=${snapshot.level.name} '
      'apiReachable=${snapshot.apiReachable} '
      'networkInterface=${snapshot.networkType} '
      'reason=${snapshot.reason ?? 'none'}',
    );
    if (!snapshot.canSync) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail:
            'deferred | level=${snapshot.level.name} reason=${snapshot.reason}',
      );
      // ignore: avoid_print
      debugPrint(
        '[SYNC_DEBUG] sync allowed = false reason=api_unreachable',
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
      // ignore: avoid_print
      debugPrint('[SYNC_DEBUG] sync allowed = false reason=autoSync_disabled');
      return;
    }

    if (!force &&
        _syncConfiguration.current.wifiOnlySync &&
        !await _uploadPolicy.isWifi) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'wifi-only preference',
      );
      // ignore: avoid_print
      debugPrint('[SYNC_DEBUG] sync allowed = false reason=wifi_only_pref');
      return;
    }

    // Capture-time upload policy must NOT permanently block the scheduled
    // pending-queue drain. `force` (login / connectivity) and `timer` /
    // `post_queue` exist specifically to upload already-queued stages when
    // Sync Settings autoSync is enabled. Policy still gates immediate upload
    // at capture via shouldAttemptImmediateUpload.
    final isScheduledQueueDrain =
        reason == 'timer' || reason == 'post_queue';
    if (!force &&
        !isScheduledQueueDrain &&
        !await _uploadPolicy.shouldAutoSync()) {
      OvertimeOfflineTrace.step(
        'SYNC_SCHEDULER',
        status: 'failure',
        detail: 'upload policy deferred',
      );
      // ignore: avoid_print
      debugPrint('[SYNC_DEBUG] sync allowed = false reason=upload_policy');
      return;
    }

    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] sync allowed = true');
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] syncing = true');

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
        // ignore: avoid_print
        debugPrint(
          '[SYNC_DEBUG] sync finished pending count after sync = '
          '${pendingAfter.length}',
        );

        var syncedCount = 0;
        var hardFailure = false;
        var offlineFailure = false;

        switch (result) {
          case Success(data: final synced):
            syncedCount = synced;
            // ignore: avoid_print
            debugPrint('[SYNC_DEBUG] sync result = success synced=$synced');
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
            // ignore: avoid_print
            debugPrint('[SYNC_DEBUG] sync result = failure code=$code');
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
      // ignore: avoid_print
      debugPrint('[SYNC_DEBUG] syncing = false');
      if (_syncRequestedAgain && !isClosed) {
        _syncRequestedAgain = false;
        unawaited(
          Future<void>.microtask(
            () => syncNow(force: force, reason: reason),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    // ignore: avoid_print
    debugPrint('[SYNC_DEBUG] OvertimeSyncCubit DISPOSED hash=$hashCode');
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_configSubscription?.cancel());
    _cancelPeriodicTimer(reason: 'dispose');
    return super.close();
  }
}
