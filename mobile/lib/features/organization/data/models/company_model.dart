import 'package:mobile/features/organization/data/mappers/json_helpers.dart';
import 'package:mobile/features/organization/domain/entities/company.dart';

class CompanyModel extends Company {
  const CompanyModel({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    super.createdAt,
    super.updatedAt,
    super.logoUrl,
    super.enabledModules,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: requireString(json, 'id'),
      code: requireString(json, 'code'),
      name: requireString(json, 'name'),
      status: requireString(json, 'status'),
      logoUrl: optionalString(json, 'logoUrl'),
      enabledModules: stringList(json['enabledModules']),
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
      'logoUrl': logoUrl,
      'enabledModules': enabledModules,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
