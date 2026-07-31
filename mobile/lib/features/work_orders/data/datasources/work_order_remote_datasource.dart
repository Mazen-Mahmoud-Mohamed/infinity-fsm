import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/work_orders/data/models/work_order_model.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';

class WorkOrderRemoteDataSource {
  WorkOrderRemoteDataSource(this._client);

  final DioClient _client;

  Future<WorkOrderPage> list({
    int page = 1,
    int limit = 20,
    WorkOrderStatus? status,
    String? search,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.workOrders,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.apiValue,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _mapPage(response.data);
  }

  Future<WorkOrderPage> listMine({
    int page = 1,
    int limit = 20,
    WorkOrderStatus? status,
    String? search,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.workOrdersMine,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.apiValue,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _mapPage(response.data);
  }

  Future<WorkOrderModel> getById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id',
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> create(WorkOrderUpsertInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.workOrders,
      data: await _buildForm(input),
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> update(String id, WorkOrderUpsertInput input) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id',
      data: await _buildForm(input),
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<void> delete(String id) async {
    await _client.delete<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id',
    );
  }

  Future<WorkOrderModel> assign({
    required String id,
    required String technicianId,
    WorkOrderPriority? priority,
    DateTime? scheduledAt,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id/assign',
      data: {
        'assignedTechnicianId': technicianId,
        if (priority != null) 'priority': priority.apiValue,
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
      },
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> accept(String id) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id/accept',
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> reject(String id, {String? rejectionReason}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id/reject',
      data: {
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
          'rejectionReason': rejectionReason.trim(),
      },
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> start(
    String id, {
    required WorkOrderLocationInput location,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id/start',
      data: _locationBody(location),
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> complete(
    String id, {
    required WorkOrderLocationInput location,
    String? completionNotes,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id/complete',
      data: {
        ..._locationBody(location),
        if (completionNotes != null && completionNotes.trim().isNotEmpty)
          'completionNotes': completionNotes.trim(),
      },
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> cancel(String id, {String? cancellationReason}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id/cancel',
      data: {
        if (cancellationReason != null && cancellationReason.trim().isNotEmpty)
          'cancellationReason': cancellationReason.trim(),
      },
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> saveBeforeWork(
    String id, {
    String? beforeNotes,
    List<WorkOrderAttachmentInput> photos = const [],
  }) async {
    final formData = FormData.fromMap({
      if (beforeNotes != null) 'beforeNotes': beforeNotes,
    });
    for (final photo in photos) {
      formData.files.add(
        MapEntry(
          'photos',
          MultipartFile.fromBytes(photo.bytes, filename: photo.fileName),
        ),
      );
    }
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id/before-work',
      data: formData,
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> addProgressNote(String id, {required String text}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id/progress-notes',
      data: {'text': text},
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> addProgressPhotos(
    String id, {
    required List<WorkOrderAttachmentInput> photos,
  }) async {
    final formData = FormData();
    for (final photo in photos) {
      formData.files.add(
        MapEntry(
          'photos',
          MultipartFile.fromBytes(photo.bytes, filename: photo.fileName),
        ),
      );
    }
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id/progress-photos',
      data: formData,
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> addAfterPhotos(
    String id, {
    required List<WorkOrderAttachmentInput> photos,
  }) async {
    final formData = FormData();
    for (final photo in photos) {
      formData.files.add(
        MapEntry(
          'photos',
          MultipartFile.fromBytes(photo.bytes, filename: photo.fileName),
        ),
      );
    }
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id/after-photos',
      data: formData,
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<WorkOrderModel> removePhoto(
    String id, {
    required WorkOrderPhotoCategory category,
    required String url,
  }) async {
    final response = await _client.delete<Map<String, dynamic>>(
      '${ApiConstants.workOrders}/$id/photos',
      data: {
        'category': category.name,
        'url': url,
      },
    );
    return WorkOrderModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _locationBody(WorkOrderLocationInput location) {
    return {
      'latitude': location.latitude,
      'longitude': location.longitude,
      if (location.accuracy != null) 'accuracy': location.accuracy,
      if (location.address != null) 'address': location.address,
      'recordedAt': location.recordedAt.toIso8601String(),
    };
  }

  Future<FormData> _buildForm(WorkOrderUpsertInput input) async {
    final map = <String, dynamic>{
      'jobTitle': input.jobTitle,
      'priority': input.priority.apiValue,
      // Always send so clears persist on update (empty string → null server-side).
      'customerName': input.customerName ?? '',
      'locationLabel': input.locationLabel ?? '',
      'description': input.description ?? '',
      'notes': input.notes ?? '',
      'scheduledAt': input.scheduledAt?.toIso8601String() ?? '',
      'assignedTechnicianId': input.assignedTechnicianId ?? '',
      if (input.estimatedDurationMinutes != null)
        'estimatedDurationMinutes': input.estimatedDurationMinutes.toString(),
      if (input.customerAddress != null)
        'customerAddress': jsonEncode(input.customerAddress!.toJson()),
      if (input.replaceAttachments) 'replaceAttachments': 'true',
      if (input.keepAttachmentUrls.isNotEmpty)
        'keepAttachmentUrls': jsonEncode(input.keepAttachmentUrls),
    };

    final formData = FormData.fromMap(map);
    for (final attachment in input.attachments) {
      formData.files.add(
        MapEntry(
          'attachments',
          MultipartFile.fromBytes(
            attachment.bytes,
            filename: attachment.fileName,
          ),
        ),
      );
    }
    return formData;
  }

  WorkOrderPage _mapPage(Map<String, dynamic>? body) {
    final data = body?['data'];
    final meta = body?['meta'];
    final pagination = meta is Map<String, dynamic>
        ? meta['pagination'] as Map<String, dynamic>?
        : null;

    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(WorkOrderModel.fromJson)
            .toList()
        : <WorkOrder>[];

    return WorkOrderPage(
      items: items,
      page: (pagination?['page'] as num?)?.toInt() ?? 1,
      limit: (pagination?['limit'] as num?)?.toInt() ?? 20,
      total: (pagination?['total'] as num?)?.toInt() ?? items.length,
      totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
