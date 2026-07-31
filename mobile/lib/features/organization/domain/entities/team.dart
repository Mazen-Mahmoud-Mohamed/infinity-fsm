import 'package:mobile/features/organization/domain/entities/org_entity.dart';

class Team extends OrgEntity {
  const Team({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    required this.companyId,
    required this.branchId,
    required this.departmentId,
    super.createdAt,
    super.updatedAt,
    this.regionId,
    this.cityId,
    this.leadId,
  });

  final String companyId;
  final String branchId;
  final String departmentId;
  final String? regionId;
  final String? cityId;
  final String? leadId;

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        status,
        companyId,
        branchId,
        departmentId,
        regionId,
        cityId,
        leadId,
        createdAt,
        updatedAt,
      ];
}
