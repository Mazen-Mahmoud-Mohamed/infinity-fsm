import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';

/// Four-stage journey workflow (v2). Legacy sessions use start/end only (v1).
enum OvertimeWorkflowVersion {
  v1,
  v2;

  static OvertimeWorkflowVersion fromApi(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'v2':
        return OvertimeWorkflowVersion.v2;
      default:
        return OvertimeWorkflowVersion.v1;
    }
  }

  String get apiValue => this == OvertimeWorkflowVersion.v2 ? 'v2' : 'v1';
}

enum OvertimeCheckpointStage {
  startJourney,
  arrivedAtWorkSite,
  finishedWork,
  endJourney;

  static OvertimeCheckpointStage? fromApi(String? value) {
    switch ((value ?? '').trim()) {
      case 'startJourney':
        return OvertimeCheckpointStage.startJourney;
      case 'arrivedAtWorkSite':
        return OvertimeCheckpointStage.arrivedAtWorkSite;
      case 'finishedWork':
        return OvertimeCheckpointStage.finishedWork;
      case 'endJourney':
        return OvertimeCheckpointStage.endJourney;
      default:
        return null;
    }
  }

  String get apiValue {
    switch (this) {
      case OvertimeCheckpointStage.startJourney:
        return 'startJourney';
      case OvertimeCheckpointStage.arrivedAtWorkSite:
        return 'arrivedAtWorkSite';
      case OvertimeCheckpointStage.finishedWork:
        return 'finishedWork';
      case OvertimeCheckpointStage.endJourney:
        return 'endJourney';
    }
  }

  static const List<OvertimeCheckpointStage> ordered = [
    OvertimeCheckpointStage.startJourney,
    OvertimeCheckpointStage.arrivedAtWorkSite,
    OvertimeCheckpointStage.finishedWork,
    OvertimeCheckpointStage.endJourney,
  ];
}

class OvertimeCheckpoint extends Equatable {
  const OvertimeCheckpoint({
    required this.at,
    required this.gps,
    this.photoUrl,
    this.address,
    this.deviceId,
    this.clientRequestId,
    this.batteryLevel,
    this.networkStatus,
    this.notes,
  });

  final DateTime at;
  final GpsSnapshot gps;
  final String? photoUrl;
  final String? address;
  final String? deviceId;
  final String? clientRequestId;
  final int? batteryLevel;
  final String? networkStatus;
  final String? notes;

  /// GPS accuracy in meters (from nested GPS snapshot).
  double? get accuracy => gps.accuracy;

  @override
  List<Object?> get props => [
        at,
        gps,
        photoUrl,
        address,
        deviceId,
        clientRequestId,
        batteryLevel,
        networkStatus,
        notes,
      ];
}

class OvertimeCheckpoints extends Equatable {
  const OvertimeCheckpoints({
    this.startJourney,
    this.arrivedAtWorkSite,
    this.finishedWork,
    this.endJourney,
  });

  final OvertimeCheckpoint? startJourney;
  final OvertimeCheckpoint? arrivedAtWorkSite;
  final OvertimeCheckpoint? finishedWork;
  final OvertimeCheckpoint? endJourney;

  OvertimeCheckpoint? forStage(OvertimeCheckpointStage stage) {
    switch (stage) {
      case OvertimeCheckpointStage.startJourney:
        return startJourney;
      case OvertimeCheckpointStage.arrivedAtWorkSite:
        return arrivedAtWorkSite;
      case OvertimeCheckpointStage.finishedWork:
        return finishedWork;
      case OvertimeCheckpointStage.endJourney:
        return endJourney;
    }
  }

  OvertimeCheckpoints copyWith({
    OvertimeCheckpoint? startJourney,
    OvertimeCheckpoint? arrivedAtWorkSite,
    OvertimeCheckpoint? finishedWork,
    OvertimeCheckpoint? endJourney,
  }) {
    return OvertimeCheckpoints(
      startJourney: startJourney ?? this.startJourney,
      arrivedAtWorkSite: arrivedAtWorkSite ?? this.arrivedAtWorkSite,
      finishedWork: finishedWork ?? this.finishedWork,
      endJourney: endJourney ?? this.endJourney,
    );
  }

  /// Next incomplete stage for a v2 session, or null when all done / not v2.
  OvertimeCheckpointStage? get nextStage {
    for (final stage in OvertimeCheckpointStage.ordered) {
      if (forStage(stage) == null) {
        return stage;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
        startJourney,
        arrivedAtWorkSite,
        finishedWork,
        endJourney,
      ];
}
