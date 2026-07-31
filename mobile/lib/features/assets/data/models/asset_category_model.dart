import 'package:mobile/features/assets/domain/entities/asset_category.dart';

class AssetCategoryModel extends AssetCategory {
  const AssetCategoryModel({
    required super.id,
    required super.name,
    required super.code,
    super.companyId,
    super.description,
    super.icon,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  factory AssetCategoryModel.fromJson(Map<String, dynamic> json) {
    return AssetCategoryModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      isActive: json['isActive'] != false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}
