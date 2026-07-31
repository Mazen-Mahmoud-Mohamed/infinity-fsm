import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:mobile/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:mobile/features/inventory/domain/entities/inventory_dashboard.dart';
import 'package:mobile/features/inventory/domain/entities/pending_inventory_action.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/inventory/domain/entities/stock_movement.dart';
import 'package:mobile/features/inventory/domain/entities/warehouse.dart';
import 'package:mobile/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl({
    required InventoryRemoteDataSource remote,
    required InventoryLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final InventoryRemoteDataSource _remote;
  final InventoryLocalDataSource _local;

  @override
  Future<Result<InventoryDashboard>> getDashboard() async {
    try {
      return Success(await _remote.getDashboard());
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WarehousePage>> listWarehouses({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) async {
    try {
      return Success(
        await _remote.listWarehouses(
          page: page,
          limit: limit,
          search: search,
          isActive: isActive,
        ),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<Warehouse>> getWarehouseById(String id) async {
    try {
      return Success(await _remote.getWarehouseById(id));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<Warehouse>> createWarehouse(WarehouseUpsertInput input) async {
    try {
      return Success(await _remote.createWarehouse(input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<Warehouse>> updateWarehouse(
    String id,
    WarehouseUpsertInput input,
  ) async {
    try {
      return Success(await _remote.updateWarehouse(id, input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<Warehouse>> deleteWarehouse(String id) async {
    try {
      return Success(await _remote.deleteWarehouse(id));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<SparePartPage>> listSpareParts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    StockStatus? stockStatus,
    bool? isActive,
  }) async {
    try {
      return Success(
        await _remote.listSpareParts(
          page: page,
          limit: limit,
          search: search,
          category: category,
          stockStatus: stockStatus,
          isActive: isActive,
        ),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<SparePart>> getSparePartById(String id) async {
    try {
      return Success(await _remote.getSparePartById(id));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<SparePart>> createSparePart(SparePartUpsertInput input) async {
    try {
      return Success(await _remote.createSparePart(input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<SparePart>> updateSparePart(
    String id,
    SparePartUpsertInput input,
  ) async {
    try {
      return Success(await _remote.updateSparePart(id, input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<SparePart>> deleteSparePart(String id) async {
    try {
      return Success(await _remote.deleteSparePart(id));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<StockMovementPage>> listMovements({
    int page = 1,
    int limit = 20,
    String? sparePartId,
    String? warehouseId,
    StockMovementType? type,
    String? search,
  }) async {
    try {
      return Success(
        await _remote.listMovements(
          page: page,
          limit: limit,
          sparePartId: sparePartId,
          warehouseId: warehouseId,
          type: type,
          search: search,
        ),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<StockMovementResult>> stockIn(StockInInput input) async {
    try {
      return Success(await _remote.stockIn(input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<StockMovementResult>> stockOut(StockOutInput input) async {
    try {
      return Success(await _remote.stockOut(input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<StockMovementResult>> transfer(TransferStockInput input) async {
    try {
      return Success(await _remote.transfer(input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<StockMovementResult>> adjustment(AdjustmentInput input) async {
    try {
      return Success(await _remote.adjustment(input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<List<PendingInventoryAction>> getPendingActions() async {
    return _local.readPendingQueue();
  }

  @override
  Future<Result<int>> syncPendingActions() async {
    // Online MVP: offline mutation queue is not executed yet.
    return const Success(0);
  }
}
