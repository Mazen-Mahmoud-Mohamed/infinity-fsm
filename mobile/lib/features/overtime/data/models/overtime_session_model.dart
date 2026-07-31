import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/data/models/gps_snapshot_model.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_technician_summary.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';

class OvertimeSessionModel extends OvertimeSession {
  const OvertimeSessionModel({
    required super.id,
    required super.companyId,
    required super.userId,
    required super.type,
    required super.status,
    required super.startAt,
    required super.startGps,
    required super.startDeviceId,
    super.technician,
    super.startAddress,
    super.startPhotoUrl,
    super.endAt,
    super.endGps,
    super.endAddress,
    super.endPhotoUrl,
    super.endDeviceId,
    super.totalDurationMinutes,
    super.workingDurationMinutes,
    super.eligibleOvertimeMinutes,
    super.liveElapsedSeconds,
    super.approvedBy,
    super.approvedAt,
    super.rejectedBy,
    super.rejectedAt,
    super.rejectionReason,
    super.createdAt,
  });

  factory OvertimeSessionModel.fromJson(Map<String, dynamic> json) {
    final startGpsJson = json['startGps'] as Map<String, dynamic>? ?? const {};
    final endGpsJson = json['endGps'] as Map<String, dynamic>?;
    final technicianJson = json['technician'] as Map<String, dynamic>?;
    final approvedByJson = json['approvedBy'] as Map<String, dynamic>?;
    final rejectedByJson = json['rejectedBy'] as Map<String, dynamic>?;

    return OvertimeSessionModel(
      id: requireString(json, 'id'),
      companyId: requireString(json, 'companyId'),
      userId: requireString(json, 'userId'),
      technician: technicianJson == null
          ? null
          : _mapTechnician(technicianJson),
      type: OvertimeType.fromApi(requireString(json, 'type')),
      status: OvertimeStatus.fromApi(requireString(json, 'status')),
      startAt: requireDateTime(json, 'startAt'),
      startGps: _mapGps(startGpsJson),
      startDeviceId: requireString(json, 'startDeviceId'),
      startAddress: optionalString(json, 'startAddress'),
      startPhotoUrl: optionalString(json, 'startPhotoUrl'),
      endAt: parseDateTime(json['endAt']),
      endGps: endGpsJson == null ? null : _mapGps(endGpsJson),
      endAddress: optionalString(json, 'endAddress'),
      endPhotoUrl: optionalString(json, 'endPhotoUrl'),
      endDeviceId: optionalString(json, 'endDeviceId'),
      totalDurationMinutes: _readNullableInt(json, 'totalDurationMinutes'),
      workingDurationMinutes: _readNullableInt(json, 'workingDurationMinutes'),
      eligibleOvertimeMinutes: _readNullableInt(json, 'eligibleOvertimeMinutes'),
      liveElapsedSeconds: _readNullableInt(json, 'liveElapsedSeconds'),
      approvedBy:
          approvedByJson == null ? null : _mapTechnician(approvedByJson),
      approvedAt: parseDateTime(json['approvedAt']),
      rejectedBy:
          rejectedByJson == null ? null : _mapTechnician(rejectedByJson),
      rejectedAt: parseDateTime(json['rejectedAt']),
      rejectionReason: optionalString(json, 'rejectionReason'),
      createdAt: parseDateTime(json['createdAt']),
    );
  }

  static GpsSnapshotModel _mapGps(Map<String, dynamic> json) {
    final recordedAt = parseDateTime(json['recordedAt']) ?? DateTime.now();
    return GpsSnapshotModel(
      latitude: readDouble(json, 'latitude'),
      longitude: readDouble(json, 'longitude'),
      accuracy: readDouble(json, 'accuracy'),
      heading: readOptionalDouble(json, 'heading'),
      speed: readOptionalDouble(json, 'speed'),
      provider: optionalString(json, 'provider'),
      recordedAt: recordedAt,
    );
  }

  static OvertimeTechnicianSummary _mapTechnician(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    return OvertimeTechnicianSummary(
      id: requireString(json, 'id'),
      firstName: optionalString(json, 'firstName'),
      lastName: optionalString(json, 'lastName'),
      fullName: optionalString(json, 'fullName'),
      email: optionalString(json, 'email'),
      roles: rolesRaw is List
          ? rolesRaw.map((item) => item.toString()).toList()
          : const [],
    );
  }

  static int? _readNullableInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'userId': userId,
      'technician': technician == null
          ? null
          : {
              'id': technician!.id,
              'firstName': technician!.firstName,
              'lastName': technician!.lastName,
              'fullName': technician!.fullName,
              'email': technician!.email,
              'roles': technician!.roles,
            },
      'type': type.apiValue,
      'status': status.apiValue,
      'startAt': startAt.toIso8601String(),
      'startGps': GpsSnapshotModel.fromEntity(startGps).toJson(),
      'startDeviceId': startDeviceId,
      'startAddress': startAddress,
      'startPhotoUrl': startPhotoUrl,
      'endAt': endAt?.toIso8601String(),
      'endGps': endGps == null
          ? null
          : GpsSnapshotModel.fromEntity(endGps!).toJson(),
      'endAddress': endAddress,
      'endPhotoUrl': endPhotoUrl,
      'endDeviceId': endDeviceId,
      'totalDurationMinutes': totalDurationMinutes,
      'workingDurationMinutes': workingDurationMinutes,
      'eligibleOvertimeMinutes': eligibleOvertimeMinutes,
      'liveElapsedSeconds': liveElapsedSeconds,
      'approvedBy': approvedBy == null
          ? null
          : {
              'id': approvedBy!.id,
              'firstName': approvedBy!.firstName,
              'lastName': approvedBy!.lastName,
              'fullName': approvedBy!.fullName,
              'email': approvedBy!.email,
              'roles': approvedBy!.roles,
            },
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedBy': rejectedBy == null
          ? null
          : {
              'id': rejectedBy!.id,
              'firstName': rejectedBy!.firstName,
              'lastName': rejectedBy!.lastName,
              'fullName': rejectedBy!.fullName,
              'email': rejectedBy!.email,
              'roles': rejectedBy!.roles,
            },
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
