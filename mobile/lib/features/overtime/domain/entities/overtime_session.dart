import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_technician_summary.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';

class OvertimeSession extends Equatable {
  const OvertimeSession({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.type,
    required this.status,
    required this.startAt,
    required this.startGps,
    required this.startDeviceId,
    this.technician,
    this.startAddress,
    this.startPhotoUrl,
    this.endAt,
    this.endGps,
    this.endAddress,
    this.endPhotoUrl,
    this.endDeviceId,
    this.totalDurationMinutes,
    this.workingDurationMinutes,
    this.eligibleOvertimeMinutes,
    this.liveElapsedSeconds,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    this.createdAt,
  });

  final String id;
  final String companyId;
  final String userId;
  final OvertimeTechnicianSummary? technician;
  final OvertimeType type;
  final OvertimeStatus status;
  final DateTime startAt;
  final GpsSnapshot startGps;
  final String startDeviceId;
  final String? startAddress;
  final String? startPhotoUrl;
  final DateTime? endAt;
  final GpsSnapshot? endGps;
  final String? endAddress;
  final String? endPhotoUrl;
  final String? endDeviceId;
  final int? totalDurationMinutes;
  final int? workingDurationMinutes;
  final int? eligibleOvertimeMinutes;
  final int? liveElapsedSeconds;
  final OvertimeTechnicianSummary? approvedBy;
  final DateTime? approvedAt;
  final OvertimeTechnicianSummary? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? createdAt;

  bool get isRunning => status == OvertimeStatus.running;
  bool get isPendingReview => status == OvertimeStatus.pendingReview;

  int get elapsedSeconds {
    if (liveElapsedSeconds != null) {
      return liveElapsedSeconds!;
    }
    if (!isRunning) {
      if (endAt != null) {
        final seconds = endAt!.difference(startAt).inSeconds;
        return seconds < 0 ? 0 : seconds;
      }
      return totalDurationMinutes != null ? totalDurationMinutes! * 60 : 0;
    }
    return DateTime.now().difference(startAt).inSeconds;
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        userId,
        technician,
        type,
        status,
        startAt,
        startGps,
        startDeviceId,
        startAddress,
        startPhotoUrl,
        endAt,
        endGps,
        endAddress,
        endPhotoUrl,
        endDeviceId,
        totalDurationMinutes,
        workingDurationMinutes,
        eligibleOvertimeMinutes,
        liveElapsedSeconds,
        approvedBy,
        approvedAt,
        rejectedBy,
        rejectedAt,
        rejectionReason,
        createdAt,
      ];
}

class OvertimeSessionPage extends Equatable {
  const OvertimeSessionPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<OvertimeSession> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}
