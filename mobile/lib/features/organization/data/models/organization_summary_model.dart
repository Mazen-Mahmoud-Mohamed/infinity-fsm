import 'package:mobile/features/organization/domain/entities/organization_summary.dart';

class OrganizationSummaryModel extends OrganizationSummary {
  const OrganizationSummaryModel({
    required super.employees,
    required super.departments,
    required super.teams,
    required super.branches,
    required super.positions,
    super.assets,
    super.workOrders,
    super.attendance,
    super.overtime,
  });

  factory OrganizationSummaryModel.fromJson(Map<String, dynamic> json) {
    int readInt(String key) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return OrganizationSummaryModel(
      employees: readInt('employees'),
      departments: readInt('departments'),
      teams: readInt('teams'),
      branches: readInt('branches'),
      positions: readInt('positions'),
      assets: readInt('assets'),
      workOrders: readInt('workOrders'),
      attendance: readInt('attendance'),
      overtime: readInt('overtime'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employees': employees,
      'departments': departments,
      'teams': teams,
      'branches': branches,
      'positions': positions,
      'assets': assets,
      'workOrders': workOrders,
      'attendance': attendance,
      'overtime': overtime,
    };
  }
}
