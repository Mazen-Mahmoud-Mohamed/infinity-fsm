import 'package:mobile/features/organization/domain/entities/org_entity.dart';

class Department extends OrgEntity {
  const Department({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    required this.companyId,
    required this.branchId,
    super.createdAt,
    super.updatedAt,
    this.regionId,
    this.cityId,
    this.supervisorIds = const [],
  });

  final String companyId;
  final String branchId;
  final String? regionId;
  final String? cityId;
  final List<String> supervisorIds;

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        status,
        companyId,
        branchId,
        regionId,
        cityId,
        supervisorIds,
        createdAt,
        updatedAt,
      ];
}
