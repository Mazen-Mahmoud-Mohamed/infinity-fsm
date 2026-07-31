import 'package:mobile/features/organization/domain/entities/org_entity.dart';

class Company extends OrgEntity {
  const Company({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    super.createdAt,
    super.updatedAt,
    this.logoUrl,
    this.enabledModules = const [],
  });

  final String? logoUrl;
  final List<String> enabledModules;

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        status,
        createdAt,
        updatedAt,
        logoUrl,
        enabledModules,
      ];
}
