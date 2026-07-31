import 'package:mobile/features/auth/domain/entities/current_user.dart';

class CurrentUserModel extends CurrentUser {
  const CurrentUserModel({
    required super.id,
    required super.companyId,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.roles,
    required super.permissions,
    super.employeeId,
    super.phone,
    super.profilePhotoUrl,
    super.branchId,
    super.regionId,
    super.cityId,
    super.departmentId,
    super.teamId,
    super.positionId,
  });

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) {
    final organization = json['organization'] as Map<String, dynamic>? ?? {};

    return CurrentUserModel(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      employeeId: json['employeeId'] as String?,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      profilePhotoUrl: json['avatarUrl'] as String?,
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((role) => role as String)
          .toList(),
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((permission) => permission as String)
          .toList(),
      branchId: organization['branchId'] as String?,
      regionId: organization['regionId'] as String?,
      cityId: organization['cityId'] as String?,
      departmentId: organization['departmentId'] as String?,
      teamId: organization['teamId'] as String?,
      positionId: organization['positionId'] as String?,
    );
  }

  factory CurrentUserModel.fromEntity(CurrentUser user) {
    return CurrentUserModel(
      id: user.id,
      companyId: user.companyId,
      employeeId: user.employeeId,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      fullName: user.fullName,
      phone: user.phone,
      profilePhotoUrl: user.profilePhotoUrl,
      roles: user.roles,
      permissions: user.permissions,
      branchId: user.branchId,
      regionId: user.regionId,
      cityId: user.cityId,
      departmentId: user.departmentId,
      teamId: user.teamId,
      positionId: user.positionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'employeeId': employeeId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': profilePhotoUrl,
      'roles': roles,
      'permissions': permissions,
      'organization': {
        'branchId': branchId,
        'regionId': regionId,
        'cityId': cityId,
        'departmentId': departmentId,
        'teamId': teamId,
        'positionId': positionId,
      },
    };
  }
}
