import 'package:equatable/equatable.dart';
import 'package:mobile/features/reports_center/domain/entities/reports_center_module.dart';

/// Lightweight presentation row mapped from existing domain entities.
/// Does not replace or duplicate domain models.
class ReportListRow extends Equatable {
  const ReportListRow({
    required this.id,
    required this.module,
    required this.title,
    required this.route,
    this.subtitle,
    this.statusLabel,
    this.date,
    this.meta,
  });

  final String id;
  final ReportsCenterModule module;
  final String title;
  final String? subtitle;
  final String? statusLabel;
  final DateTime? date;
  final String? meta;
  final String route;

  @override
  List<Object?> get props =>
      [id, module, title, subtitle, statusLabel, date, meta, route];
}

class ReportEmployeeOption extends Equatable {
  const ReportEmployeeOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  @override
  List<Object?> get props => [id, label];
}
