import 'package:equatable/equatable.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_record.dart';

class AttendanceRecordPage extends Equatable {
  const AttendanceRecordPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<AttendanceRecord> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}
