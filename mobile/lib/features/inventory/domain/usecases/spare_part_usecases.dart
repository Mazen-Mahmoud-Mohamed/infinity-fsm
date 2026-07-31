import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/inventory/domain/repositories/inventory_repository.dart';

class ListSparePartsUseCase {
  ListSparePartsUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<SparePartPage>> call({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    StockStatus? stockStatus,
    bool? isActive,
  }) {
    return _repository.listSpareParts(
      page: page,
      limit: limit,
      search: search,
      category: category,
      stockStatus: stockStatus,
      isActive: isActive,
    );
  }
}

class GetSparePartByIdUseCase {
  GetSparePartByIdUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<SparePart>> call(String id) => _repository.getSparePartById(id);
}

class CreateSparePartUseCase {
  CreateSparePartUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<SparePart>> call(SparePartUpsertInput input) {
    return _repository.createSparePart(input);
  }
}

class UpdateSparePartUseCase {
  UpdateSparePartUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<SparePart>> call(String id, SparePartUpsertInput input) {
    return _repository.updateSparePart(id, input);
  }
}

class DeleteSparePartUseCase {
  DeleteSparePartUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<SparePart>> call(String id) => _repository.deleteSparePart(id);
}
