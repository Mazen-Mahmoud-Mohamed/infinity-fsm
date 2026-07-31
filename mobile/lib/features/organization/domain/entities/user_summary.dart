import 'package:mobile/features/organization/domain/entities/org_entity.dart';

class UserSummary extends OrgEntity {
  const UserSummary({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    required this.companyId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.roles,
    required this.branchId,
    required this.departmentId,
    super.createdAt,
    super.updatedAt,
    this.employeeId,
    this.phone,
    this.avatarUrl,
    this.regionId,
    this.cityId,
    this.teamId,
    this.positionId,
  });

  final String companyId;
  final String? employeeId;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final List<String> roles;
  final String branchId;
  final String? regionId;
  final String? cityId;
  final String departmentId;
  final String? teamId;
  final String? positionId;

  String get primaryRole => roles.isNotEmpty ? roles.first : 'user';

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        status,
        companyId,
        employeeId,
        email,
        firstName,
        lastName,
        fullName,
        phone,
        avatarUrl,
        roles,
        branchId,
        regionId,
        cityId,
        departmentId,
        teamId,
        positionId,
        createdAt,
        updatedAt,
      ];
}
