import 'package:mobile/features/organization/data/mappers/json_helpers.dart';
import 'package:mobile/features/organization/domain/entities/department.dart';

class DepartmentModel extends Department {
  const DepartmentModel({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    required super.companyId,
    required super.branchId,
    super.createdAt,
    super.updatedAt,
    super.regionId,
    super.cityId,
    super.supervisorIds,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: requireString(json, 'id'),
      code: requireString(json, 'code'),
      name: requireString(json, 'name'),
      status: requireString(json, 'status'),
      companyId: requireString(json, 'companyId'),
      branchId: requireString(json, 'branchId'),
      regionId: optionalString(json, 'regionId'),
      cityId: optionalString(json, 'cityId'),
      supervisorIds: stringList(json['supervisorIds']),
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
      'regionId': regionId,
      'cityId': cityId,
      'supervisorIds': supervisorIds,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
