import 'package:equatable/equatable.dart';

class AssetCategory extends Equatable {
  const AssetCategory({
    required this.id,
    required this.name,
    required this.code,
    this.companyId,
    this.description,
    this.icon,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? companyId;
  final String name;
  final String code;
  final String? description;
  final String? icon;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        name,
        code,
        description,
        icon,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class AssetCategoryPage extends Equatable {
  const AssetCategoryPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<AssetCategory> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class AssetCategoryUpsertInput {
  const AssetCategoryUpsertInput({
    required this.name,
    required this.code,
    this.description,
    this.icon,
    this.isActive = true,
  });

  final String name;
  final String code;
  final String? description;
  final String? icon;
  final bool isActive;
}
