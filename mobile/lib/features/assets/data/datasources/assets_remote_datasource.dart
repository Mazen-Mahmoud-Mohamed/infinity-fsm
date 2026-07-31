import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/assets/data/models/asset_category_model.dart';
import 'package:mobile/features/assets/data/models/asset_history_model.dart';
import 'package:mobile/features/assets/data/models/asset_model.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/domain/entities/asset_category.dart';
import 'package:mobile/features/assets/domain/entities/asset_history.dart';
import 'package:mobile/features/assets/domain/entities/assets_dashboard.dart';

class AssetsRemoteDataSource {
  AssetsRemoteDataSource(this._client);

  final DioClient _client;

  Future<AssetsDashboard> getDashboard() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.assetsDashboard,
    );
    return AssetsDashboardModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<AssetCategoryPage> listCategories({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.assetsCategories,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (isActive != null) 'isActive': isActive,
      },
    );
    return _mapCategoryPage(response.data);
  }

  Future<AssetCategoryModel> getCategoryById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.assetsCategories}/$id',
    );
    return AssetCategoryModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<AssetCategoryModel> createCategory(AssetCategoryUpsertInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.assetsCategories,
      data: {
        'name': input.name,
        'code': input.code,
        if (input.description != null) 'description': input.description,
        if (input.icon != null) 'icon': input.icon,
        'isActive': input.isActive,
      },
    );
    return AssetCategoryModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<AssetCategoryModel> updateCategory(
    String id,
    AssetCategoryUpsertInput input,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${ApiConstants.assetsCategories}/$id',
      data: {
        'name': input.name,
        'code': input.code,
        if (input.description != null) 'description': input.description,
        if (input.icon != null) 'icon': input.icon,
        'isActive': input.isActive,
      },
    );
    return AssetCategoryModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<AssetCategoryModel> deleteCategory(String id) async {
    final response = await _client.delete<Map<String, dynamic>>(
      '${ApiConstants.assetsCategories}/$id',
    );
    return AssetCategoryModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<AssetPage> listAssets({
    int page = 1,
    int limit = 20,
    String? search,
    AssetStatus? status,
    String? categoryId,
    String? branchId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.assets,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null) 'status': status.apiValue,
        if (categoryId != null) 'categoryId': categoryId,
        if (branchId != null) 'branchId': branchId,
      },
    );
    return _mapAssetPage(response.data);
  }

  Future<AssetModel> getAssetById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.assets}/$id',
    );
    return AssetModel.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<AssetModel> createAsset(AssetUpsertInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.assets,
      data: await _buildAssetForm(input),
    );
    return AssetModel.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<AssetModel> updateAsset(String id, AssetUpsertInput input) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${ApiConstants.assets}/$id',
      data: await _buildAssetForm(input),
    );
    return AssetModel.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<AssetModel> deleteAsset(String id) async {
    final response = await _client.delete<Map<String, dynamic>>(
      '${ApiConstants.assets}/$id',
    );
    return AssetModel.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<AssetHistoryPage> listHistory({
    int page = 1,
    int limit = 20,
    String? assetId,
    AssetHistoryType? type,
    String? search,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.assetsHistory,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (assetId != null) 'assetId': assetId,
        if (type != null) 'type': type.apiValue,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _mapHistoryPage(response.data);
  }

  Future<AssetHistoryModel> addHistory(AssetHistoryCreateInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.assetsHistory,
      data: {
        'assetId': input.assetId,
        'type': input.type.apiValue,
        if (input.title != null) 'title': input.title,
        if (input.description != null) 'description': input.description,
        if (input.toStatus != null) 'toStatus': input.toStatus,
        if (input.eventDate != null)
          'eventDate': input.eventDate!.toIso8601String(),
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? const {};
    final historyJson = data['history'] as Map<String, dynamic>? ?? data;
    return AssetHistoryModel.fromJson(historyJson);
  }

  Future<FormData> _buildAssetForm(AssetUpsertInput input) async {
    final map = <String, dynamic>{
      'assetNumber': input.assetNumber,
      'name': input.name,
      'status': input.status.apiValue,
      if (input.categoryId != null) 'categoryId': input.categoryId,
      if (input.serialNumber != null) 'serialNumber': input.serialNumber,
      if (input.manufacturer != null) 'manufacturer': input.manufacturer,
      if (input.model != null) 'model': input.model,
      if (input.installationDate != null)
        'installationDate': input.installationDate!.toIso8601String(),
      if (input.warrantyExpiry != null)
        'warrantyExpiry': input.warrantyExpiry!.toIso8601String(),
      if (input.branchId != null) 'branchId': input.branchId,
      if (input.regionName != null) 'regionName': input.regionName,
      if (input.cityName != null) 'cityName': input.cityName,
      if (input.gps != null) 'gps': jsonEncode({
        'latitude': input.gps!.latitude,
        'longitude': input.gps!.longitude,
        'accuracy': input.gps!.accuracy,
        'address': input.gps!.address,
      }),
      if (input.qrCode != null) 'qrCode': input.qrCode,
      if (input.barcode != null) 'barcode': input.barcode,
      if (input.customer != null) 'customer': input.customer,
      if (input.notes != null) 'notes': input.notes,
      if (input.removeImage) 'removeImage': true,
    };

    final formData = FormData.fromMap(map);
    if (input.image != null) {
      formData.files.add(
        MapEntry(
          'image',
          MultipartFile.fromBytes(
            input.image!.bytes,
            filename: input.image!.fileName,
          ),
        ),
      );
    }
    return formData;
  }

  AssetCategoryPage _mapCategoryPage(Map<String, dynamic>? body) {
    final pagination = _pagination(body);
    final data = body?['data'];
    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(AssetCategoryModel.fromJson)
            .toList()
        : <AssetCategory>[];
    return AssetCategoryPage(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  AssetPage _mapAssetPage(Map<String, dynamic>? body) {
    final pagination = _pagination(body);
    final data = body?['data'];
    final items = data is List
        ? data.whereType<Map<String, dynamic>>().map(AssetModel.fromJson).toList()
        : <Asset>[];
    return AssetPage(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  AssetHistoryPage _mapHistoryPage(Map<String, dynamic>? body) {
    final pagination = _pagination(body);
    final data = body?['data'];
    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(AssetHistoryModel.fromJson)
            .toList()
        : <AssetHistory>[];
    return AssetHistoryPage(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  ({int page, int limit, int total, int totalPages}) _pagination(
    Map<String, dynamic>? body,
  ) {
    final meta = body?['meta'];
    final pagination = meta is Map<String, dynamic>
        ? meta['pagination'] as Map<String, dynamic>?
        : null;
    return (
      page: (pagination?['page'] as num?)?.toInt() ?? 1,
      limit: (pagination?['limit'] as num?)?.toInt() ?? 20,
      total: (pagination?['total'] as num?)?.toInt() ?? 0,
      totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
