import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/inventory/data/models/inventory_dashboard_model.dart';
import 'package:mobile/features/inventory/data/models/spare_part_model.dart';
import 'package:mobile/features/inventory/data/models/stock_movement_model.dart';
import 'package:mobile/features/inventory/data/models/warehouse_model.dart';
import 'package:mobile/features/inventory/domain/entities/inventory_dashboard.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/inventory/domain/entities/stock_movement.dart';
import 'package:mobile/features/inventory/domain/entities/warehouse.dart';

class InventoryRemoteDataSource {
  InventoryRemoteDataSource(this._client);

  final DioClient _client;

  Future<InventoryDashboard> getDashboard() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.inventoryDashboard,
    );
    return InventoryDashboardModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<WarehousePage> listWarehouses({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.inventoryWarehouses,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (isActive != null) 'isActive': isActive,
      },
    );
    return _mapWarehousePage(response.data);
  }

  Future<WarehouseModel> getWarehouseById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.inventoryWarehouses}/$id',
    );
    return WarehouseModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WarehouseModel> createWarehouse(WarehouseUpsertInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.inventoryWarehouses,
      data: {
        'name': input.name,
        'code': input.code,
        if (input.address != null) 'address': input.address,
        if (input.description != null) 'description': input.description,
        'isActive': input.isActive,
      },
    );
    return WarehouseModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WarehouseModel> updateWarehouse(
    String id,
    WarehouseUpsertInput input,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${ApiConstants.inventoryWarehouses}/$id',
      data: {
        'name': input.name,
        'code': input.code,
        if (input.address != null) 'address': input.address,
        if (input.description != null) 'description': input.description,
        'isActive': input.isActive,
      },
    );
    return WarehouseModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WarehouseModel> deleteWarehouse(String id) async {
    final response = await _client.delete<Map<String, dynamic>>(
      '${ApiConstants.inventoryWarehouses}/$id',
    );
    return WarehouseModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<SparePartPage> listSpareParts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    StockStatus? stockStatus,
    bool? isActive,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.inventoryParts,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
        if (stockStatus != null) 'stockStatus': stockStatus.apiValue,
        if (isActive != null) 'isActive': isActive,
      },
    );
    return _mapSparePartPage(response.data);
  }

  Future<SparePartModel> getSparePartById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.inventoryParts}/$id',
    );
    return SparePartModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<SparePartModel> createSparePart(SparePartUpsertInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.inventoryParts,
      data: await _buildPartForm(input, includeCurrentQuantity: true),
    );
    return SparePartModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<SparePartModel> updateSparePart(
    String id,
    SparePartUpsertInput input,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${ApiConstants.inventoryParts}/$id',
      data: await _buildPartForm(input, includeCurrentQuantity: false),
    );
    return SparePartModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<SparePartModel> deleteSparePart(String id) async {
    final response = await _client.delete<Map<String, dynamic>>(
      '${ApiConstants.inventoryParts}/$id',
    );
    return SparePartModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<StockMovementPage> listMovements({
    int page = 1,
    int limit = 20,
    String? sparePartId,
    String? warehouseId,
    StockMovementType? type,
    String? search,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.inventoryMovements,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (sparePartId != null) 'sparePartId': sparePartId,
        if (warehouseId != null) 'warehouseId': warehouseId,
        if (type != null) 'type': type.apiValue,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _mapMovementPage(response.data);
  }

  Future<StockMovementResultModel> stockIn(StockInInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.inventoryStockIn,
      data: {
        'sparePartId': input.sparePartId,
        'warehouseId': input.warehouseId,
        'quantity': input.quantity,
        if (input.reason != null) 'reason': input.reason,
        if (input.notes != null) 'notes': input.notes,
        if (input.movementDate != null)
          'movementDate': input.movementDate!.toIso8601String(),
      },
    );
    return StockMovementResultModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<StockMovementResultModel> stockOut(StockOutInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.inventoryStockOut,
      data: {
        'sparePartId': input.sparePartId,
        'warehouseId': input.warehouseId,
        'quantity': input.quantity,
        if (input.reason != null) 'reason': input.reason,
        if (input.notes != null) 'notes': input.notes,
        if (input.movementDate != null)
          'movementDate': input.movementDate!.toIso8601String(),
      },
    );
    return StockMovementResultModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<StockMovementResultModel> transfer(TransferStockInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.inventoryTransfer,
      data: {
        'sparePartId': input.sparePartId,
        'fromWarehouseId': input.fromWarehouseId,
        'toWarehouseId': input.toWarehouseId,
        'quantity': input.quantity,
        if (input.reason != null) 'reason': input.reason,
        if (input.notes != null) 'notes': input.notes,
        if (input.movementDate != null)
          'movementDate': input.movementDate!.toIso8601String(),
      },
    );
    return StockMovementResultModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<StockMovementResultModel> adjustment(AdjustmentInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.inventoryAdjustment,
      data: {
        'sparePartId': input.sparePartId,
        'warehouseId': input.warehouseId,
        'quantity': input.quantity,
        'direction': input.direction.apiValue,
        'reason': input.reason,
        if (input.notes != null) 'notes': input.notes,
        if (input.movementDate != null)
          'movementDate': input.movementDate!.toIso8601String(),
      },
    );
    return StockMovementResultModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<FormData> _buildPartForm(
    SparePartUpsertInput input, {
    required bool includeCurrentQuantity,
  }) async {
    final map = <String, dynamic>{
      'partNumber': input.partNumber,
      'name': input.name,
      'unit': input.unit,
      'minimumQuantity': input.minimumQuantity,
      'isActive': input.isActive,
      if (input.category != null) 'category': input.category,
      if (input.description != null) 'description': input.description,
      if (input.barcode != null) 'barcode': input.barcode,
      if (includeCurrentQuantity && input.currentQuantity != null)
        'currentQuantity': input.currentQuantity,
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

  WarehousePage _mapWarehousePage(Map<String, dynamic>? body) {
    final pagination = _pagination(body);
    final data = body?['data'];
    final items = data is List
        ? data.whereType<Map<String, dynamic>>().map(WarehouseModel.fromJson).toList()
        : <Warehouse>[];
    return WarehousePage(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  SparePartPage _mapSparePartPage(Map<String, dynamic>? body) {
    final pagination = _pagination(body);
    final data = body?['data'];
    final items = data is List
        ? data.whereType<Map<String, dynamic>>().map(SparePartModel.fromJson).toList()
        : <SparePart>[];
    return SparePartPage(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  StockMovementPage _mapMovementPage(Map<String, dynamic>? body) {
    final pagination = _pagination(body);
    final data = body?['data'];
    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(StockMovementModel.fromJson)
            .toList()
        : <StockMovement>[];
    return StockMovementPage(
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
