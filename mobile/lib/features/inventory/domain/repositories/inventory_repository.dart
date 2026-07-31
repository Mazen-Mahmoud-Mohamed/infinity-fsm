import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/inventory_dashboard.dart';
import 'package:mobile/features/inventory/domain/entities/pending_inventory_action.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/inventory/domain/entities/stock_movement.dart';
import 'package:mobile/features/inventory/domain/entities/warehouse.dart';

abstract class InventoryRepository {
  Future<Result<InventoryDashboard>> getDashboard();

  Future<Result<WarehousePage>> listWarehouses({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  });

  Future<Result<Warehouse>> getWarehouseById(String id);

  Future<Result<Warehouse>> createWarehouse(WarehouseUpsertInput input);

  Future<Result<Warehouse>> updateWarehouse(String id, WarehouseUpsertInput input);

  Future<Result<Warehouse>> deleteWarehouse(String id);

  Future<Result<SparePartPage>> listSpareParts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    StockStatus? stockStatus,
    bool? isActive,
  });

  Future<Result<SparePart>> getSparePartById(String id);

  Future<Result<SparePart>> createSparePart(SparePartUpsertInput input);

  Future<Result<SparePart>> updateSparePart(String id, SparePartUpsertInput input);

  Future<Result<SparePart>> deleteSparePart(String id);

  Future<Result<StockMovementPage>> listMovements({
    int page = 1,
    int limit = 20,
    String? sparePartId,
    String? warehouseId,
    StockMovementType? type,
    String? search,
  });

  Future<Result<StockMovementResult>> stockIn(StockInInput input);

  Future<Result<StockMovementResult>> stockOut(StockOutInput input);

  Future<Result<StockMovementResult>> transfer(TransferStockInput input);

  Future<Result<StockMovementResult>> adjustment(AdjustmentInput input);

  /// Offline sync prep — returns queued actions (empty in online MVP).
  Future<List<PendingInventoryAction>> getPendingActions();

  /// Offline sync prep — no-op online MVP, returns Success(0).
  Future<Result<int>> syncPendingActions();
}
