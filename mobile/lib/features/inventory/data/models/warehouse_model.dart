import 'package:mobile/features/inventory/domain/entities/warehouse.dart';

class WarehouseModel extends Warehouse {
  const WarehouseModel({
    required super.id,
    required super.name,
    required super.code,
    super.companyId,
    super.address,
    super.description,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      address: json['address']?.toString(),
      description: json['description']?.toString(),
      isActive: json['isActive'] != false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
