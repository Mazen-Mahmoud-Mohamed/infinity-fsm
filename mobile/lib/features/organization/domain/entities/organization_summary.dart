import 'package:equatable/equatable.dart';

class OrganizationSummary extends Equatable {
  const OrganizationSummary({
    required this.employees,
    required this.departments,
    required this.teams,
    required this.branches,
    required this.positions,
    this.assets = 0,
    this.workOrders = 0,
    this.attendance = 0,
    this.overtime = 0,
  });

  final int employees;
  final int departments;
  final int teams;
  final int branches;
  final int positions;
  final int assets;
  final int workOrders;
  final int attendance;
  final int overtime;

  @override
  List<Object?> get props => [
        employees,
        departments,
        teams,
        branches,
        positions,
        assets,
        workOrders,
        attendance,
        overtime,
      ];
}
