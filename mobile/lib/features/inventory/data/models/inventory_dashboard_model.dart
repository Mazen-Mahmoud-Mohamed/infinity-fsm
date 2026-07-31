import 'package:mobile/features/inventory/domain/entities/inventory_dashboard.dart';
import 'package:mobile/features/inventory/data/models/stock_movement_model.dart';

class InventoryDashboardModel extends InventoryDashboard {
  const InventoryDashboardModel({
    required super.totalParts,
    required super.lowStock,
    required super.outOfStock,
    super.recentMovements,
  });

  factory InventoryDashboardModel.fromJson(Map<String, dynamic> json) {
    final movements = json['recentMovements'];
    return InventoryDashboardModel(
      totalParts: (json['totalParts'] as num?)?.toInt() ?? 0,
      lowStock: (json['lowStock'] as num?)?.toInt() ?? 0,
      outOfStock: (json['outOfStock'] as num?)?.toInt() ?? 0,
      recentMovements: movements is List
          ? movements
              .whereType<Map<String, dynamic>>()
              .map(StockMovementModel.fromJson)
              .toList()
          : const [],
    );
  }
}
