import 'package:mobile/features/inventory/domain/entities/stock_movement.dart';
import 'package:mobile/features/inventory/data/models/spare_part_model.dart';

class StockMovementModel extends StockMovement {
  const StockMovementModel({
    required super.id,
    required super.type,
    required super.quantity,
    required super.quantityDelta,
    required super.quantityBefore,
    required super.quantityAfter,
    required super.sparePart,
    super.companyId,
    super.warehouse,
    super.fromWarehouse,
    super.toWarehouse,
    super.user,
    super.movementDate,
    super.reason,
    super.notes,
    super.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    final sparePartJson = json['sparePart'];
    return StockMovementModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      type: StockMovementType.fromApi(json['type']?.toString()),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      quantityDelta: (json['quantityDelta'] as num?)?.toDouble() ?? 0,
      quantityBefore: (json['quantityBefore'] as num?)?.toDouble() ?? 0,
      quantityAfter: (json['quantityAfter'] as num?)?.toDouble() ?? 0,
      sparePart: sparePartJson is Map<String, dynamic>
          ? StockMovementSparePartRef(
              id: sparePartJson['id']?.toString() ?? '',
              partNumber: sparePartJson['partNumber']?.toString(),
              name: sparePartJson['name']?.toString(),
              unit: sparePartJson['unit']?.toString(),
            )
          : StockMovementSparePartRef(id: json['sparePartId']?.toString() ?? ''),
      warehouse: _mapNamedRef(json['warehouse']),
      fromWarehouse: _mapNamedRef(json['fromWarehouse']),
      toWarehouse: _mapNamedRef(json['toWarehouse']),
      user: _mapNamedRef(json['user']),
      movementDate: _parseDate(json['movementDate']),
      reason: json['reason']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static InventoryNamedRef? _mapNamedRef(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return InventoryNamedRef(
      id: id,
      name: value['name']?.toString(),
      code: value['code']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class StockMovementResultModel extends StockMovementResult {
  const StockMovementResultModel({
    required super.movement,
    required super.sparePart,
  });

  factory StockMovementResultModel.fromJson(Map<String, dynamic> json) {
    return StockMovementResultModel(
      movement: StockMovementModel.fromJson(
        json['movement'] as Map<String, dynamic>? ?? const {},
      ),
      sparePart: SparePartModel.fromJson(
        json['sparePart'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
