import 'package:mobile/features/organization/data/mappers/json_helpers.dart';
import 'package:mobile/features/organization/domain/entities/branch.dart';

class BranchModel extends Branch {
  const BranchModel({
    required super.id,
    required super.code,
    required super.name,
    required super.status,
    required super.companyId,
    super.createdAt,
    super.updatedAt,
    super.addressCity,
    super.addressCountry,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    return BranchModel(
      id: requireString(json, 'id'),
      code: requireString(json, 'code'),
      name: requireString(json, 'name'),
      status: requireString(json, 'status'),
      companyId: requireString(json, 'companyId'),
      addressCity: optionalString(address, 'city'),
      addressCountry: optionalString(address, 'country'),
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
      'address': {
        'city': addressCity,
        'country': addressCountry,
      },
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
