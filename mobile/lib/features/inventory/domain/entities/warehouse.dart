import 'package:equatable/equatable.dart';

class Warehouse extends Equatable {
  const Warehouse({
    required this.id,
    required this.name,
    required this.code,
    this.companyId,
    this.address,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? companyId;
  final String name;
  final String code;
  final String? address;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        name,
        code,
        address,
        description,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class WarehousePage extends Equatable {
  const WarehousePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<Warehouse> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class WarehouseUpsertInput {
  const WarehouseUpsertInput({
    required this.name,
    required this.code,
    this.address,
    this.description,
    this.isActive = true,
  });

  final String name;
  final String code;
  final String? address;
  final String? description;
  final bool isActive;
}
