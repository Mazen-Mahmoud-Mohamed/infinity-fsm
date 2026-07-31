import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/warehouse.dart';
import 'package:mobile/features/inventory/domain/repositories/inventory_repository.dart';

class GetWarehouseByIdUseCase {
  GetWarehouseByIdUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<Warehouse>> call(String id) => _repository.getWarehouseById(id);
}

class CreateWarehouseUseCase {
  CreateWarehouseUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<Warehouse>> call(WarehouseUpsertInput input) {
    return _repository.createWarehouse(input);
  }
}

class UpdateWarehouseUseCase {
  UpdateWarehouseUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<Warehouse>> call(String id, WarehouseUpsertInput input) {
    return _repository.updateWarehouse(id, input);
  }
}

class DeleteWarehouseUseCase {
  DeleteWarehouseUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<Warehouse>> call(String id) => _repository.deleteWarehouse(id);
}
