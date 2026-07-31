import 'package:mobile/features/organization/domain/entities/org_entity.dart';

class Position extends OrgEntity {
  const Position({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    required this.companyId,
    super.createdAt,
    super.updatedAt,
    this.description,
  });

  final String companyId;
  final String? description;

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        status,
        companyId,
        description,
        createdAt,
        updatedAt,
      ];
}
