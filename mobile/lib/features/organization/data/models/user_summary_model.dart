import 'package:mobile/features/organization/data/mappers/json_helpers.dart';
import 'package:mobile/features/organization/domain/entities/user_summary.dart';

class UserSummaryModel extends UserSummary {
  const UserSummaryModel({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    required super.companyId,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.roles,
    required super.branchId,
    required super.departmentId,
    super.createdAt,
    super.updatedAt,
    super.employeeId,
    super.phone,
    super.avatarUrl,
    super.regionId,
    super.cityId,
    super.teamId,
    super.positionId,
  });

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserSummaryModel(
      id: requireString(json, 'id'),
      code: optionalString(json, 'code') ??
          optionalString(json, 'employeeId') ??
          requireString(json, 'id'),
      name: optionalString(json, 'name') ??
          optionalString(json, 'fullName') ??
          '${optionalString(json, 'firstName') ?? ''} ${optionalString(json, 'lastName') ?? ''}'
              .trim(),
      status: requireString(json, 'status'),
      companyId: requireString(json, 'companyId'),
      employeeId: optionalString(json, 'employeeId'),
      email: requireString(json, 'email'),
      firstName: requireString(json, 'firstName'),
      lastName: requireString(json, 'lastName'),
      fullName: optionalString(json, 'fullName') ??
          '${requireString(json, 'firstName')} ${requireString(json, 'lastName')}',
      phone: optionalString(json, 'phone'),
      avatarUrl: optionalString(json, 'avatarUrl'),
      roles: stringList(json['roles']),
      branchId: requireString(json, 'branchId'),
      regionId: optionalString(json, 'regionId'),
      cityId: optionalString(json, 'cityId'),
      departmentId: requireString(json, 'departmentId'),
      teamId: optionalString(json, 'teamId'),
      positionId: optionalString(json, 'positionId'),
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
      'employeeId': employeeId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'roles': roles,
      'branchId': branchId,
      'regionId': regionId,
      'cityId': cityId,
      'departmentId': departmentId,
      'teamId': teamId,
      'positionId': positionId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
