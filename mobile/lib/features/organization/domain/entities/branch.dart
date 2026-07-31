import 'package:mobile/features/organization/domain/entities/org_entity.dart';

class Branch extends OrgEntity {
  const Branch({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    required this.companyId,
    super.createdAt,
    super.updatedAt,
    this.addressCity,
    this.addressCountry,
  });

  final String companyId;
  final String? addressCity;
  final String? addressCountry;

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        status,
        companyId,
        createdAt,
        updatedAt,
        addressCity,
        addressCountry,
      ];
}
