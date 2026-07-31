import 'package:mobile/features/organization/data/mappers/json_helpers.dart';
import 'package:mobile/features/organization/domain/entities/team.dart';

class TeamModel extends Team {
  const TeamModel({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    required super.companyId,
    required super.branchId,
    required super.departmentId,
    super.createdAt,
    super.updatedAt,
    super.regionId,
    super.cityId,
    super.leadId,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: requireString(json, 'id'),
      code: requireString(json, 'code'),
      name: requireString(json, 'name'),
      status: requireString(json, 'status'),
      companyId: requireString(json, 'companyId'),
      branchId: requireString(json, 'branchId'),
      departmentId: requireString(json, 'departmentId'),
      regionId: optionalString(json, 'regionId'),
      cityId: optionalString(json, 'cityId'),
      leadId: optionalString(json, 'leadId'),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'status': status,
      'companyId': companyId,
      'branchId': branchId,
      'departmentId': departmentId,
      'regionId': regionId,
      'cityId': cityId,
      'leadId': leadId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
