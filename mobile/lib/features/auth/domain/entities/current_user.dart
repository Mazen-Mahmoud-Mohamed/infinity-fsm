import 'package:equatable/equatable.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';

class CurrentUser extends Equatable {
  const CurrentUser({
    required this.id,
    required this.companyId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.roles,
    required this.permissions,
    this.employeeId,
    this.phone,
    this.profilePhotoUrl,
    this.branchId,
    this.regionId,
    this.cityId,
    this.departmentId,
    this.teamId,
    this.positionId,
  });

  final String id;
  final String companyId;
  final String? employeeId;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? phone;
  final String? profilePhotoUrl;
  final List<String> roles;
  final List<String> permissions;
  final String? branchId;
  final String? regionId;
  final String? cityId;
  final String? departmentId;
  final String? teamId;
  final String? positionId;

  String get primaryRole => roles.isNotEmpty ? roles.first : 'user';

  PermissionChecker get permissionChecker =>
      PermissionChecker(permissions);

  @override
  List<Object?> get props => [
        id,
        companyId,
        employeeId,
        email,
        firstName,
        lastName,
        fullName,
        phone,
        profilePhotoUrl,
        roles,
        permissions,
        branchId,
        regionId,
        cityId,
        departmentId,
        teamId,
        positionId,
      ];
}
