import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/warehouse.dart';
import 'package:mobile/features/inventory/domain/repositories/inventory_repository.dart';

class ListWarehousesUseCase {
  ListWarehousesUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<WarehousePage>> call({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) {
    return _repository.listWarehouses(
      page: page,
      limit: limit,
      search: search,
      isActive: isActive,
    );
  }
}
