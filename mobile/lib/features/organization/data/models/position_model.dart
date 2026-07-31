import 'package:mobile/features/organization/data/mappers/json_helpers.dart';
import 'package:mobile/features/organization/domain/entities/position.dart';

class PositionModel extends Position {
  const PositionModel({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    required super.companyId,
    super.createdAt,
    super.updatedAt,
    super.description,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: requireString(json, 'id'),
      code: requireString(json, 'code'),
      name: requireString(json, 'name'),
      status: requireString(json, 'status'),
      companyId: requireString(json, 'companyId'),
      description: optionalString(json, 'description'),
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
      'companyId': companyId,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
