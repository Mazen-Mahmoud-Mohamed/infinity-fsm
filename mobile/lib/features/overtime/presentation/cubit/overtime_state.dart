import 'package:equatable/equatable.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';

enum OvertimeLoadStatus {
  initial,
  loading,
  actionInProgress,
  ready,
  failure,
}

enum OvertimeBusyAction {
  startNormal,
  startTravel,
  arrivedAtWorkSite,
  finishedWork,
  end,
}

class OvertimeState extends Equatable {
  const OvertimeState({
    this.status = OvertimeLoadStatus.initial,
    this.session,
    this.completedSession,
    this.elapsedSeconds = 0,
    this.currentAddress,
    this.message,
    this.isError = false,
    this.isOffline = false,
    this.busyAction,
    this.isRefreshing = false,
    this.notesDraft,
    this.offerContinueSession = false,
    this.liveBatteryLevel,
    this.liveNetworkStatus,
    this.gpsAccuracyMeters,
    this.pendingSyncCount = 0,
  });

  final OvertimeLoadStatus status;
  final OvertimeSession? session;
  final OvertimeSession? completedSession;
  final int elapsedSeconds;
  final String? currentAddress;
  final String? message;
  final bool isError;
  final bool isOffline;
  final OvertimeBusyAction? busyAction;
  final bool isRefreshing;
  final String? notesDraft;

  /// True when a running session already exists (server conflict or local
  /// recovery) and the UI should offer to continue it instead of starting.
  final bool offerContinueSession;

  /// Live telemetry refreshed periodically while a session is running.
  final int? liveBatteryLevel;
  final String? liveNetworkStatus;
  final double? gpsAccuracyMeters;
  final int pendingSyncCount;

  bool get isRunning => session?.isRunning ?? false;
  bool get isBusy => busyAction != null;
  bool get isStartingNormal => busyAction == OvertimeBusyAction.startNormal;
  bool get isStartingTravel => busyAction == OvertimeBusyAction.startTravel;
  bool get isRecordingArrived =>
      busyAction == OvertimeBusyAction.arrivedAtWorkSite;
  bool get isRecordingFinishedWork =>
      busyAction == OvertimeBusyAction.finishedWork;
  bool get isEnding => busyAction == OvertimeBusyAction.end;

  OvertimeCheckpointStage? get nextCheckpoint =>
      session?.effectiveNextCheckpoint;

  OvertimeState copyWith({
    OvertimeLoadStatus? status,
    OvertimeSession? session,
    bool clearSession = false,
    OvertimeSession? completedSession,
    bool clearCompleted = false,
    int? elapsedSeconds,
    String? currentAddress,
    bool clearAddress = false,
    String? message,
    bool clearMessage = false,
    bool? isError,
    bool? isOffline,
    OvertimeBusyAction? busyAction,
    bool clearBusyAction = false,
    bool? isRefreshing,
    String? notesDraft,
    bool clearNotesDraft = false,
    bool? offerContinueSession,
    int? liveBatteryLevel,
    bool clearLiveBatteryLevel = false,
    String? liveNetworkStatus,
    bool clearLiveNetworkStatus = false,
    double? gpsAccuracyMeters,
    bool clearGpsAccuracyMeters = false,
    int? pendingSyncCount,
  }) {
    return OvertimeState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      completedSession:
          clearCompleted ? null : (completedSession ?? this.completedSession),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      currentAddress:
          clearAddress ? null : (currentAddress ?? this.currentAddress),
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
      isOffline: isOffline ?? this.isOffline,
      busyAction: clearBusyAction ? null : (busyAction ?? this.busyAction),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      notesDraft: clearNotesDraft ? null : (notesDraft ?? this.notesDraft),
      offerContinueSession: offerContinueSession ?? this.offerContinueSession,
      liveBatteryLevel: clearLiveBatteryLevel
          ? null
          : (liveBatteryLevel ?? this.liveBatteryLevel),
      liveNetworkStatus: clearLiveNetworkStatus
          ? null
          : (liveNetworkStatus ?? this.liveNetworkStatus),
      gpsAccuracyMeters: clearGpsAccuracyMeters
          ? null
          : (gpsAccuracyMeters ?? this.gpsAccuracyMeters),
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        session,
        completedSession,
        elapsedSeconds,
        currentAddress,
        message,
        isError,
        isOffline,
        busyAction,
        isRefreshing,
        notesDraft,
        offerContinueSession,
        liveBatteryLevel,
        liveNetworkStatus,
        gpsAccuracyMeters,
        pendingSyncCount,
      ];
}
