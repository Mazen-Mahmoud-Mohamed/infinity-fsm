import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/assets/data/datasources/assets_local_datasource.dart';
import 'package:mobile/features/assets/data/datasources/assets_remote_datasource.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/domain/entities/asset_category.dart';
import 'package:mobile/features/assets/domain/entities/asset_history.dart';
import 'package:mobile/features/assets/domain/entities/assets_dashboard.dart';
import 'package:mobile/features/assets/domain/entities/pending_asset_action.dart';
import 'package:mobile/features/assets/domain/repositories/assets_repository.dart';

class AssetsRepositoryImpl implements AssetsRepository {
  AssetsRepositoryImpl({
    required AssetsRemoteDataSource remote,
    required AssetsLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final AssetsRemoteDataSource _remote;
  final AssetsLocalDataSource _local;

  @override
  Future<Result<AssetsDashboard>> getDashboard() async {
    try {
      return Success(await _remote.getDashboard());
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<AssetCategoryPage>> listCategories({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) async {
    try {
      return Success(
        await _remote.listCategories(
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
  Future<Result<AssetCategory>> getCategoryById(String id) async {
    try {
      return Success(await _remote.getCategoryById(id));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<AssetCategory>> createCategory(
    AssetCategoryUpsertInput input,
  ) async {
    try {
      return Success(await _remote.createCategory(input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<AssetCategory>> updateCategory(
    String id,
    AssetCategoryUpsertInput input,
  ) async {
    try {
      return Success(await _remote.updateCategory(id, input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<AssetCategory>> deleteCategory(String id) async {
    try {
      return Success(await _remote.deleteCategory(id));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<AssetPage>> listAssets({
    int page = 1,
    int limit = 20,
    String? search,
    AssetStatus? status,
    String? categoryId,
    String? branchId,
  }) async {
    try {
      return Success(
        await _remote.listAssets(
          page: page,
          limit: limit,
          search: search,
          status: status,
          categoryId: categoryId,
          branchId: branchId,
        ),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<Asset>> getAssetById(String id) async {
    try {
      return Success(await _remote.getAssetById(id));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<Asset>> createAsset(AssetUpsertInput input) async {
    try {
      return Success(await _remote.createAsset(input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<Asset>> updateAsset(String id, AssetUpsertInput input) async {
    try {
      return Success(await _remote.updateAsset(id, input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<Asset>> deleteAsset(String id) async {
    try {
      return Success(await _remote.deleteAsset(id));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<AssetHistoryPage>> listHistory({
    int page = 1,
    int limit = 20,
    String? assetId,
    AssetHistoryType? type,
    String? search,
  }) async {
    try {
      return Success(
        await _remote.listHistory(
          page: page,
          limit: limit,
          assetId: assetId,
          type: type,
          search: search,
        ),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<AssetHistory>> addHistory(AssetHistoryCreateInput input) async {
    try {
      return Success(await _remote.addHistory(input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<List<PendingAssetAction>> getPendingActions() async {
    return _local.readPendingQueue();
  }

  @override
  Future<Result<int>> syncPendingActions() async {
    return const Success(0);
  }
}
