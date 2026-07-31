import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/domain/entities/asset_category.dart';
import 'package:mobile/features/assets/domain/entities/asset_history.dart';
import 'package:mobile/features/assets/domain/entities/assets_dashboard.dart';
import 'package:mobile/features/assets/domain/entities/pending_asset_action.dart';

abstract class AssetsRepository {
  Future<Result<AssetsDashboard>> getDashboard();

  Future<Result<AssetCategoryPage>> listCategories({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  });

  Future<Result<AssetCategory>> getCategoryById(String id);

  Future<Result<AssetCategory>> createCategory(AssetCategoryUpsertInput input);

  Future<Result<AssetCategory>> updateCategory(
    String id,
    AssetCategoryUpsertInput input,
  );

  Future<Result<AssetCategory>> deleteCategory(String id);

  Future<Result<AssetPage>> listAssets({
    int page = 1,
    int limit = 20,
    String? search,
    AssetStatus? status,
    String? categoryId,
    String? branchId,
  });

  Future<Result<Asset>> getAssetById(String id);

  Future<Result<Asset>> createAsset(AssetUpsertInput input);

  Future<Result<Asset>> updateAsset(String id, AssetUpsertInput input);

  Future<Result<Asset>> deleteAsset(String id);

  Future<Result<AssetHistoryPage>> listHistory({
    int page = 1,
    int limit = 20,
    String? assetId,
    AssetHistoryType? type,
    String? search,
  });

  Future<Result<AssetHistory>> addHistory(AssetHistoryCreateInput input);

  /// Offline sync prep — returns queued actions (empty in online MVP).
  Future<List<PendingAssetAction>> getPendingActions();

  /// Offline sync prep — no-op online MVP, returns Success(0).
  Future<Result<int>> syncPendingActions();
}
