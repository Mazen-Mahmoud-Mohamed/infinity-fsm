import 'package:mobile/features/organization/data/models/branch_model.dart';
import 'package:mobile/features/organization/data/models/company_model.dart';
import 'package:mobile/features/organization/data/models/department_model.dart';
import 'package:mobile/features/organization/data/models/position_model.dart';
import 'package:mobile/features/organization/data/models/team_model.dart';
import 'package:mobile/features/organization/domain/entities/organization_context.dart';

class OrganizationContextModel extends OrganizationContext {
  const OrganizationContextModel({
    super.company,
    super.branch,
    super.department,
    super.team,
    super.position,
  });

  factory OrganizationContextModel.fromJson(Map<String, dynamic> json) {
    return OrganizationContextModel(
      company: json['company'] is Map<String, dynamic>
          ? CompanyModel.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      branch: json['branch'] is Map<String, dynamic>
          ? BranchModel.fromJson(json['branch'] as Map<String, dynamic>)
          : null,
      department: json['department'] is Map<String, dynamic>
          ? DepartmentModel.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      team: json['team'] is Map<String, dynamic>
          ? TeamModel.fromJson(json['team'] as Map<String, dynamic>)
          : null,
      position: json['position'] is Map<String, dynamic>
          ? PositionModel.fromJson(json['position'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company is CompanyModel
          ? (company! as CompanyModel).toJson()
          : null,
      'branch':
          branch is BranchModel ? (branch! as BranchModel).toJson() : null,
      'department': department is DepartmentModel
          ? (department! as DepartmentModel).toJson()
          : null,
      'team': team is TeamModel ? (team! as TeamModel).toJson() : null,
      'position': position is PositionModel
          ? (position! as PositionModel).toJson()
          : null,
    };
  }
}
