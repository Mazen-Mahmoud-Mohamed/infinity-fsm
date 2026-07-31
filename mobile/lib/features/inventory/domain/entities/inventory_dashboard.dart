import 'package:equatable/equatable.dart';
import 'package:mobile/features/inventory/domain/entities/stock_movement.dart';

class InventoryDashboard extends Equatable {
  const InventoryDashboard({
    required this.totalParts,
    required this.lowStock,
    required this.outOfStock,
    this.recentMovements = const [],
  });

  final int totalParts;
  final int lowStock;
  final int outOfStock;
  final List<StockMovement> recentMovements;

  @override
  List<Object?> get props => [
        totalParts,
        lowStock,
        outOfStock,
        recentMovements,
      ];
}
