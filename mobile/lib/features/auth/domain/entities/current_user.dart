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
    this.lastLoginAt,
    this.createdAt,
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
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  String get primaryRole => roles.isNotEmpty ? roles.first : 'user';

  /// Executive Dashboard is for Admin / Supervisor only.
  ///
  /// Field technicians use an operational home (Work Orders) instead.
  bool get canAccessExecutiveDashboard {
    final upper = roles.map((role) => role.toUpperCase());
    return upper.contains('ADMIN') || upper.contains('SUPERVISOR');
  }

  /// Technicians and other non-management field roles.
  bool get usesOperationalHome => !canAccessExecutiveDashboard;

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
        lastLoginAt,
        createdAt,
      ];
}
