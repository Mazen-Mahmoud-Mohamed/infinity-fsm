import 'package:equatable/equatable.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';

enum StockMovementType {
  stockIn,
  stockOut,
  transfer,
  adjustment;

  String get apiValue {
    switch (this) {
      case StockMovementType.stockIn:
        return 'STOCK_IN';
      case StockMovementType.stockOut:
        return 'STOCK_OUT';
      case StockMovementType.transfer:
        return 'TRANSFER';
      case StockMovementType.adjustment:
        return 'ADJUSTMENT';
    }
  }

  static StockMovementType fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'STOCK_OUT':
        return StockMovementType.stockOut;
      case 'TRANSFER':
        return StockMovementType.transfer;
      case 'ADJUSTMENT':
        return StockMovementType.adjustment;
      case 'STOCK_IN':
      default:
        return StockMovementType.stockIn;
    }
  }
}

enum AdjustmentDirection {
  increase,
  decrease;

  String get apiValue {
    switch (this) {
      case AdjustmentDirection.increase:
        return 'INCREASE';
      case AdjustmentDirection.decrease:
        return 'DECREASE';
    }
  }
}

class InventoryNamedRef extends Equatable {
  const InventoryNamedRef({
    required this.id,
    this.name,
    this.code,
  });

  final String id;
  final String? name;
  final String? code;

  @override
  List<Object?> get props => [id, name, code];
}

class StockMovementSparePartRef extends Equatable {
  const StockMovementSparePartRef({
    required this.id,
    this.partNumber,
    this.name,
    this.unit,
  });

  final String id;
  final String? partNumber;
  final String? name;
  final String? unit;

  @override
  List<Object?> get props => [id, partNumber, name, unit];
}

class StockMovement extends Equatable {
  const StockMovement({
    required this.id,
    required this.type,
    required this.quantity,
    required this.quantityDelta,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.sparePart,
    this.companyId,
    this.warehouse,
    this.fromWarehouse,
    this.toWarehouse,
    this.user,
    this.movementDate,
    this.reason,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String? companyId;
  final StockMovementType type;
  final double quantity;
  final double quantityDelta;
  final double quantityBefore;
  final double quantityAfter;
  final StockMovementSparePartRef sparePart;
  final InventoryNamedRef? warehouse;
  final InventoryNamedRef? fromWarehouse;
  final InventoryNamedRef? toWarehouse;
  final InventoryNamedRef? user;
  final DateTime? movementDate;
  final String? reason;
  final String? notes;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        type,
        quantity,
        quantityDelta,
        quantityBefore,
        quantityAfter,
        sparePart,
        warehouse,
        fromWarehouse,
        toWarehouse,
        user,
        movementDate,
        reason,
        notes,
        createdAt,
      ];
}

class StockMovementPage extends Equatable {
  const StockMovementPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<StockMovement> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class StockMovementResult extends Equatable {
  const StockMovementResult({
    required this.movement,
    required this.sparePart,
  });

  final StockMovement movement;
  final SparePart sparePart;

  @override
  List<Object?> get props => [movement, sparePart];
}

class StockInInput {
  const StockInInput({
    required this.sparePartId,
    required this.warehouseId,
    required this.quantity,
    this.reason,
    this.notes,
    this.movementDate,
  });

  final String sparePartId;
  final String warehouseId;
  final double quantity;
  final String? reason;
  final String? notes;
  final DateTime? movementDate;
}

class StockOutInput {
  const StockOutInput({
    required this.sparePartId,
    required this.warehouseId,
    required this.quantity,
    this.reason,
    this.notes,
    this.movementDate,
  });

  final String sparePartId;
  final String warehouseId;
  final double quantity;
  final String? reason;
  final String? notes;
  final DateTime? movementDate;
}

class TransferStockInput {
  const TransferStockInput({
    required this.sparePartId,
    required this.fromWarehouseId,
    required this.toWarehouseId,
    required this.quantity,
    this.reason,
    this.notes,
    this.movementDate,
  });

  final String sparePartId;
  final String fromWarehouseId;
  final String toWarehouseId;
  final double quantity;
  final String? reason;
  final String? notes;
  final DateTime? movementDate;
}

class AdjustmentInput {
  const AdjustmentInput({
    required this.sparePartId,
    required this.warehouseId,
    required this.quantity,
    required this.reason,
    this.direction = AdjustmentDirection.increase,
    this.notes,
    this.movementDate,
  });

  final String sparePartId;
  final String warehouseId;
  final double quantity;
  final String reason;
  final AdjustmentDirection direction;
  final String? notes;
  final DateTime? movementDate;
}
