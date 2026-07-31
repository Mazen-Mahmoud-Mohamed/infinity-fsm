import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';

enum PendingOvertimeActionType { start, end }

class PendingOvertimeAction extends Equatable {
  const PendingOvertimeAction({
    required this.id,
    required this.type,
    required this.gps,
    required this.photoBytes,
    required this.deviceId,
    required this.clientRequestId,
    required this.createdAt,
    this.overtimeType,
    this.sessionId,
    this.address,
    this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final PendingOvertimeActionType type;
  final OvertimeType? overtimeType;
  final String? sessionId;
  final GpsSnapshot gps;
  final List<int> photoBytes;
  final String deviceId;
  final String clientRequestId;
  final String? address;

  /// Original offline start timestamp. Present on START and END actions.
  final DateTime? startedAt;

  /// Offline end timestamp. Present on END actions.
  final DateTime? endedAt;

  /// `endedAt - startedAt` in seconds. Present on END actions.
  final int? durationSeconds;

  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  PendingOvertimeAction copyWith({
    GpsSnapshot? gps,
    String? address,
    int? retryCount,
    String? lastError,
    String? sessionId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) {
    return PendingOvertimeAction(
      id: id,
      type: type,
      overtimeType: overtimeType,
      sessionId: sessionId ?? this.sessionId,
      gps: gps ?? this.gps,
      photoBytes: photoBytes,
      deviceId: deviceId,
      clientRequestId: clientRequestId,
      address: address ?? this.address,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
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
        sessionId,
        gps,
        photoBytes,
        deviceId,
        clientRequestId,
        address,
        startedAt,
        endedAt,
        durationSeconds,
        createdAt,
        retryCount,
        lastError,
      ];
}
