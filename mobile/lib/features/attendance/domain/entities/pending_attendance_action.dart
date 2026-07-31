import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_event.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';

/// A locally queued attendance action awaiting synchronization with the
/// server. Selfie bytes are embedded directly so the queue survives app
/// restarts without depending on the platform filesystem.
class PendingAttendanceAction extends Equatable {
  const PendingAttendanceAction({
    required this.clientEventId,
    required this.type,
    required this.gps,
    required this.deviceId,
    required this.clientRecordedAt,
    required this.createdAt,
    this.selfieBytes,
    this.retryCount = 0,
    this.lastError,
  });

  final String clientEventId;
  final AttendanceEventType type;
  final GpsSnapshot gps;
  final Uint8List? selfieBytes;
  final String deviceId;
  final DateTime clientRecordedAt;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  bool get requiresSelfie =>
      type == AttendanceEventType.clockIn || type == AttendanceEventType.clockOut;

  PendingAttendanceAction copyWith({
    GpsSnapshot? gps,
    int? retryCount,
    String? lastError,
    bool clearError = false,
  }) {
    return PendingAttendanceAction(
      clientEventId: clientEventId,
      type: type,
      gps: gps ?? this.gps,
      selfieBytes: selfieBytes,
      deviceId: deviceId,
      clientRecordedAt: clientRecordedAt,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }

  @override
  List<Object?> get props => [
        clientEventId,
        type,
        gps,
        deviceId,
        clientRecordedAt,
        createdAt,
        retryCount,
        lastError,
      ];
}
