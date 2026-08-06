import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';

enum PendingOvertimeActionType { start, arrivedAtWorkSite, finishedWork, end }

class PendingOvertimeAction extends Equatable {
  const PendingOvertimeAction({
    required this.id,
    required this.type,
    required this.gps,
    required this.photoBytes,
    this.voiceBytes = const [],
    this.voiceDurationSeconds,
    required this.deviceId,
    required this.clientRequestId,
    required this.createdAt,
    this.overtimeType,
    this.isOvernight = false,
    this.sessionId,
    this.address,
    this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.checkpointAt,
    this.notes,
    this.batteryLevel,
    this.networkStatus,
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final PendingOvertimeActionType type;
  final OvertimeType? overtimeType;

  /// Travel overnight stay for START actions. Defaults false for legacy queue items.
  final bool isOvernight;
  final String? sessionId;
  final GpsSnapshot gps;
  final List<int> photoBytes;
  final List<int> voiceBytes;
  final double? voiceDurationSeconds;
  final String deviceId;
  final String clientRequestId;
  final String? address;

  /// Original offline start timestamp. Present on START and END actions.
  final DateTime? startedAt;

  /// Offline end timestamp. Present on END actions.
  final DateTime? endedAt;

  /// `endedAt - startedAt` in seconds. Present on END actions.
  final int? durationSeconds;

  /// Mid-journey checkpoint timestamp (arrived / finished).
  final DateTime? checkpointAt;

  final String? notes;
  final int? batteryLevel;
  final String? networkStatus;

  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  bool get isMidCheckpoint =>
      type == PendingOvertimeActionType.arrivedAtWorkSite ||
      type == PendingOvertimeActionType.finishedWork;

  OvertimeCheckpointStage? get checkpointStage {
    switch (type) {
      case PendingOvertimeActionType.start:
        return OvertimeCheckpointStage.startJourney;
      case PendingOvertimeActionType.arrivedAtWorkSite:
        return OvertimeCheckpointStage.arrivedAtWorkSite;
      case PendingOvertimeActionType.finishedWork:
        return OvertimeCheckpointStage.finishedWork;
      case PendingOvertimeActionType.end:
        return OvertimeCheckpointStage.endJourney;
    }
  }

  PendingOvertimeAction copyWith({
    GpsSnapshot? gps,
    String? address,
    int? retryCount,
    String? lastError,
    String? sessionId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    DateTime? checkpointAt,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    bool clearVoice = false,
  }) {
    return PendingOvertimeAction(
      id: id,
      type: type,
      overtimeType: overtimeType,
      isOvernight: isOvernight,
      sessionId: sessionId ?? this.sessionId,
      gps: gps ?? this.gps,
      photoBytes: photoBytes,
      voiceBytes: clearVoice ? const [] : (voiceBytes ?? this.voiceBytes),
      voiceDurationSeconds: clearVoice
          ? null
          : (voiceDurationSeconds ?? this.voiceDurationSeconds),
      deviceId: deviceId,
      clientRequestId: clientRequestId,
      address: address ?? this.address,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      checkpointAt: checkpointAt ?? this.checkpointAt,
      notes: notes ?? this.notes,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      networkStatus: networkStatus ?? this.networkStatus,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    overtimeType,
    isOvernight,
    sessionId,
    gps,
    photoBytes,
    voiceBytes,
    voiceDurationSeconds,
    deviceId,
    clientRequestId,
    address,
    startedAt,
    endedAt,
    durationSeconds,
    checkpointAt,
    notes,
    batteryLevel,
    networkStatus,
    createdAt,
    retryCount,
    lastError,
  ];
}
