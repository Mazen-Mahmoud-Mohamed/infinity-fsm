import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';

enum AttendanceEventType { clockIn, clockOut, breakStart, breakEnd }

class AttendanceEventEntity extends Equatable {
  const AttendanceEventEntity({
    required this.id,
    required this.type,
    required this.at,
    required this.gps,
    required this.deviceId,
    required this.source,
    this.selfieUrl,
  });

  final String id;
  final AttendanceEventType type;
  final DateTime at;
  final GpsSnapshot gps;
  final String? selfieUrl;
  final String deviceId;
  final String source;

  @override
  List<Object?> get props => [id, type, at, gps, selfieUrl, deviceId, source];
}
