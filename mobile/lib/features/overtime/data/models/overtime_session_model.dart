import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/data/models/gps_snapshot_model.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
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
    super.isOvernight,
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
    super.approvedHours,
    super.liveElapsedSeconds,
    super.approvedBy,
    super.approvedAt,
    super.rejectedBy,
    super.rejectedAt,
    super.rejectionReason,
    super.createdAt,
    super.workflowVersion,
    super.checkpoints,
    super.nextCheckpoint,
    super.requiresManualReview,
    super.reviewReason,
    super.reviewNotes,
  });

  factory OvertimeSessionModel.fromJson(Map<String, dynamic> json) {
    final startGpsJson = json['startGps'] as Map<String, dynamic>? ?? const {};
    final endGpsJson = json['endGps'] as Map<String, dynamic>?;
    final technicianJson = json['technician'] as Map<String, dynamic>?;
    final approvedByJson = json['approvedBy'] as Map<String, dynamic>?;
    final rejectedByJson = json['rejectedBy'] as Map<String, dynamic>?;
    final checkpointsJson = json['checkpoints'] as Map<String, dynamic>?;

    return OvertimeSessionModel(
      id: requireString(json, 'id'),
      companyId: requireString(json, 'companyId'),
      userId: requireString(json, 'userId'),
      technician: technicianJson == null
          ? null
          : _mapTechnician(technicianJson),
      type: OvertimeType.fromApi(requireString(json, 'type')),
      isOvernight: json['isOvernight'] == true,
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
      eligibleOvertimeMinutes: _readNullableInt(
        json,
        'eligibleOvertimeMinutes',
      ),
      approvedHours: _readNullableDouble(json, 'approvedHours'),
      liveElapsedSeconds: _readNullableInt(json, 'liveElapsedSeconds'),
      approvedBy: approvedByJson == null
          ? null
          : _mapTechnician(approvedByJson),
      approvedAt: parseDateTime(json['approvedAt']),
      rejectedBy: rejectedByJson == null
          ? null
          : _mapTechnician(rejectedByJson),
      rejectedAt: parseDateTime(json['rejectedAt']),
      rejectionReason: optionalString(json, 'rejectionReason'),
      createdAt: parseDateTime(json['createdAt']),
      workflowVersion: OvertimeWorkflowVersion.fromApi(
        optionalString(json, 'workflowVersion'),
      ),
      checkpoints: checkpointsJson == null
          ? null
          : _mapCheckpoints(checkpointsJson),
      nextCheckpoint: OvertimeCheckpointStage.fromApi(
        optionalString(json, 'nextCheckpoint'),
      ),
      requiresManualReview: json['requiresManualReview'] == true,
      reviewReason: optionalString(json, 'reviewReason'),
      reviewNotes: optionalString(json, 'reviewNotes'),
    );
  }

  static OvertimeCheckpoints _mapCheckpoints(Map<String, dynamic> json) {
    return OvertimeCheckpoints(
      startJourney: _mapCheckpoint(json['startJourney']),
      arrivedAtWorkSite: _mapCheckpoint(json['arrivedAtWorkSite']),
      finishedWork: _mapCheckpoint(json['finishedWork']),
      endJourney: _mapCheckpoint(json['endJourney']),
    );
  }

  static OvertimeCheckpoint? _mapCheckpoint(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    final gpsJson = raw['gps'] as Map<String, dynamic>? ?? const {};
    final at = parseDateTime(raw['at']);
    if (at == null) {
      return null;
    }
    return OvertimeCheckpoint(
      at: at,
      gps: _mapGps(gpsJson),
      photoUrl: optionalString(raw, 'photoUrl'),
      voiceNote: _mapVoiceNote(raw['voiceNote']),
      address: optionalString(raw, 'address'),
      deviceId: optionalString(raw, 'deviceId'),
      clientRequestId: optionalString(raw, 'clientRequestId'),
      batteryLevel: _readNullableInt(raw, 'batteryLevel'),
      networkStatus: optionalString(raw, 'networkStatus'),
      notes: optionalString(raw, 'notes'),
    );
  }

  static OvertimeVoiceNote? _mapVoiceNote(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    final url = optionalString(raw, 'url');
    if (url == null || url.isEmpty) {
      return null;
    }
    return OvertimeVoiceNote(
      url: url,
      publicId: optionalString(raw, 'publicId'),
      duration: readOptionalDouble(raw, 'duration'),
      size: _readNullableInt(raw, 'size'),
      format: optionalString(raw, 'format'),
      uploadedAt: parseDateTime(raw['uploadedAt']),
      localPath: optionalString(raw, 'localPath'),
    );
  }

  static Map<String, dynamic>? _voiceNoteToJson(OvertimeVoiceNote? note) {
    if (note == null) {
      return null;
    }
    return {
      'url': note.url,
      'publicId': note.publicId,
      'duration': note.duration,
      'size': note.size,
      'format': note.format,
      'uploadedAt': note.uploadedAt?.toIso8601String(),
      'localPath': note.localPath,
    };
  }

  static GpsSnapshotModel _mapGps(Map<String, dynamic> json) {
    final recordedAt = parseDateTime(json['recordedAt']) ?? DateTime.now();
    return GpsSnapshotModel(
      latitude: readDouble(json, 'latitude'),
      longitude: readDouble(json, 'longitude'),
      accuracy: readDouble(json, 'accuracy'),
      heading: readOptionalDouble(json, 'heading'),
      speed: readOptionalDouble(json, 'speed'),
      altitude: readOptionalDouble(json, 'altitude'),
      provider: optionalString(json, 'provider'),
      recordedAt: recordedAt,
      fullAddress: optionalString(json, 'fullAddress'),
      street: optionalString(json, 'street'),
      area: optionalString(json, 'area'),
      city: optionalString(json, 'city'),
      country: optionalString(json, 'country'),
      addressResolvedAt: parseDateTime(json['addressResolvedAt']),
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

  static double? _readNullableDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static Map<String, dynamic>? _checkpointToJson(OvertimeCheckpoint? cp) {
    if (cp == null) return null;
    return {
      'at': cp.at.toIso8601String(),
      'gps': GpsSnapshotModel.fromEntity(cp.gps).toJson(),
      'photoUrl': cp.photoUrl,
      'voiceNote': _voiceNoteToJson(cp.voiceNote),
      'address': cp.address,
      'deviceId': cp.deviceId,
      'clientRequestId': cp.clientRequestId,
      'accuracy': cp.accuracy,
      'batteryLevel': cp.batteryLevel,
      'networkStatus': cp.networkStatus,
      'notes': cp.notes,
    };
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
      'isOvernight': isOvernight,
      'status': status.apiValue,
      'workflowVersion': workflowVersion.apiValue,
      'nextCheckpoint': nextCheckpoint?.apiValue,
      'requiresManualReview': requiresManualReview,
      'reviewReason': reviewReason,
      'reviewNotes': reviewNotes,
      'checkpoints': checkpoints == null
          ? null
          : {
              'startJourney': _checkpointToJson(checkpoints!.startJourney),
              'arrivedAtWorkSite': _checkpointToJson(
                checkpoints!.arrivedAtWorkSite,
              ),
              'finishedWork': _checkpointToJson(checkpoints!.finishedWork),
              'endJourney': _checkpointToJson(checkpoints!.endJourney),
            },
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
      'approvedHours': approvedHours,
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
