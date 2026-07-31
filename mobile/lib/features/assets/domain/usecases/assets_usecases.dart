import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/domain/entities/asset_category.dart';
import 'package:mobile/features/assets/domain/entities/asset_history.dart';
import 'package:mobile/features/assets/domain/entities/assets_dashboard.dart';
import 'package:mobile/features/assets/domain/repositories/assets_repository.dart';

class GetAssetsDashboardUseCase {
  GetAssetsDashboardUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<AssetsDashboard>> call() => _repository.getDashboard();
}

class ListAssetCategoriesUseCase {
  ListAssetCategoriesUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<AssetCategoryPage>> call({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) =>
      _repository.listCategories(
        page: page,
        limit: limit,
        search: search,
        isActive: isActive,
      );
}

class CreateAssetCategoryUseCase {
  CreateAssetCategoryUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<AssetCategory>> call(AssetCategoryUpsertInput input) =>
      _repository.createCategory(input);
}

class UpdateAssetCategoryUseCase {
  UpdateAssetCategoryUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<AssetCategory>> call(
    String id,
    AssetCategoryUpsertInput input,
  ) =>
      _repository.updateCategory(id, input);
}

class DeleteAssetCategoryUseCase {
  DeleteAssetCategoryUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<AssetCategory>> call(String id) =>
      _repository.deleteCategory(id);
}

class ListAssetsUseCase {
  ListAssetsUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<AssetPage>> call({
    int page = 1,
    int limit = 20,
    String? search,
    AssetStatus? status,
    String? categoryId,
    String? branchId,
  }) =>
      _repository.listAssets(
        page: page,
        limit: limit,
        search: search,
        status: status,
        categoryId: categoryId,
        branchId: branchId,
      );
}

class GetAssetByIdUseCase {
  GetAssetByIdUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<Asset>> call(String id) => _repository.getAssetById(id);
}

class CreateAssetUseCase {
  CreateAssetUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<Asset>> call(AssetUpsertInput input) =>
      _repository.createAsset(input);
}

class UpdateAssetUseCase {
  UpdateAssetUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<Asset>> call(String id, AssetUpsertInput input) =>
      _repository.updateAsset(id, input);
}

class DeleteAssetUseCase {
  DeleteAssetUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<Asset>> call(String id) => _repository.deleteAsset(id);
}

class ListAssetHistoryUseCase {
  ListAssetHistoryUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<AssetHistoryPage>> call({
    int page = 1,
    int limit = 20,
    String? assetId,
    AssetHistoryType? type,
    String? search,
  }) =>
      _repository.listHistory(
        page: page,
        limit: limit,
        assetId: assetId,
        type: type,
        search: search,
      );
}

class AddAssetHistoryUseCase {
  AddAssetHistoryUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<AssetHistory>> call(AssetHistoryCreateInput input) =>
      _repository.addHistory(input);
}

class SyncPendingAssetsUseCase {
  SyncPendingAssetsUseCase(this._repository);
  final AssetsRepository _repository;
  Future<Result<int>> call() => _repository.syncPendingActions();
}
