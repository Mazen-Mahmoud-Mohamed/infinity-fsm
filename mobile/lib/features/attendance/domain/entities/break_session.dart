import 'package:equatable/equatable.dart';

enum BreakSessionStatus { active, completed }

class BreakSessionEntity extends Equatable {
  const BreakSessionEntity({
    required this.id,
    required this.status,
    required this.startAt,
    required this.durationMinutes,
    this.endAt,
  });

  final String id;
  final BreakSessionStatus status;
  final DateTime startAt;
  final DateTime? endAt;
  final int durationMinutes;

  @override
  List<Object?> get props => [id, status, startAt, endAt, durationMinutes];
}
