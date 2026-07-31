import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';

class AttendanceActionRecord extends Equatable {
  const AttendanceActionRecord({
    required this.at,
    required this.gps,
    required this.selfieUrl,
    required this.deviceId,
    required this.source,
  });

  final DateTime at;
  final GpsSnapshot gps;
  final String? selfieUrl;
  final String deviceId;
  final String source;

  @override
  List<Object?> get props => [at, gps, selfieUrl, deviceId, source];
}
