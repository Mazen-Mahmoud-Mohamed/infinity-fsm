import 'package:equatable/equatable.dart';
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

  bool get isRunning => session?.isRunning ?? false;
  bool get isBusy => busyAction != null;
  bool get isStartingNormal => busyAction == OvertimeBusyAction.startNormal;
  bool get isStartingTravel => busyAction == OvertimeBusyAction.startTravel;
  bool get isEnding => busyAction == OvertimeBusyAction.end;

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
      ];
}
