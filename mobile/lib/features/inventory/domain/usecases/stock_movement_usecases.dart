import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/stock_movement.dart';
import 'package:mobile/features/inventory/domain/repositories/inventory_repository.dart';

class ListStockMovementsUseCase {
  ListStockMovementsUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<StockMovementPage>> call({
    int page = 1,
    int limit = 20,
    String? sparePartId,
    String? warehouseId,
    StockMovementType? type,
    String? search,
  }) {
    return _repository.listMovements(
      page: page,
      limit: limit,
      sparePartId: sparePartId,
      warehouseId: warehouseId,
      type: type,
      search: search,
    );
  }
}

class StockInUseCase {
  StockInUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<StockMovementResult>> call(StockInInput input) {
    return _repository.stockIn(input);
  }
}

class StockOutUseCase {
  StockOutUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<StockMovementResult>> call(StockOutInput input) {
    return _repository.stockOut(input);
  }
}

class TransferStockUseCase {
  TransferStockUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<StockMovementResult>> call(TransferStockInput input) {
    return _repository.transfer(input);
  }
}

class AdjustmentStockUseCase {
  AdjustmentStockUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<StockMovementResult>> call(AdjustmentInput input) {
    return _repository.adjustment(input);
  }
}

class SyncPendingInventoryUseCase {
  SyncPendingInventoryUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<int>> call() => _repository.syncPendingActions();
}
