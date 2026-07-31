import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/service_reports/data/models/service_report_models.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';

class ServiceReportsRemoteDataSource {
  ServiceReportsRemoteDataSource(this._client);
  final DioClient _client;

  Future<ServiceReportsDashboard> getDashboard() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.reportsDashboard,
    );
    return ServiceReportsDashboardModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<ServiceReportPage> listReports({
    int page = 1,
    int limit = 20,
    String? search,
    ServiceReportStatus? status,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.reports,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null) 'status': status.apiValue,
      },
    );
    return _mapReportPage(response.data);
  }

  Future<ServiceReportModel> getReportById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.reports}/$id',
    );
    return ServiceReportModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<ServiceReportModel> generateReport(
    GenerateServiceReportInput input,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.reportsGenerate,
      data: {
        if (input.companyName != null) 'companyName': input.companyName,
        if (input.companyLogoUrl != null)
          'companyLogoUrl': input.companyLogoUrl,
        if (input.workOrderId != null) 'workOrderId': input.workOrderId,
        if (input.signatureId != null) 'signatureId': input.signatureId,
        'workOrder': input.workOrder.toJson(),
        'asset': input.asset.toJson(),
        'technician': input.technician.toJson(),
        if (input.startTime != null)
          'startTime': input.startTime!.toIso8601String(),
        if (input.endTime != null) 'endTime': input.endTime!.toIso8601String(),
        if (input.totalDurationMinutes != null)
          'totalDurationMinutes': input.totalDurationMinutes,
        'beforePhotos':
            input.beforePhotos.map((e) => e.toJson()).toList(),
        'progressPhotos':
            input.progressPhotos.map((e) => e.toJson()).toList(),
        'afterPhotos': input.afterPhotos.map((e) => e.toJson()).toList(),
        if (input.technicianNotes != null)
          'technicianNotes': input.technicianNotes,
        if (input.customerNotes != null) 'customerNotes': input.customerNotes,
      },
    );
    return ServiceReportModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<ServiceReportDownloadModel> downloadReport(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.reports}/$id/download',
    );
    return ServiceReportDownloadModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<CustomerSignaturePage> listSignatures({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.reportsSignatures,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _mapSignaturePage(response.data);
  }

  Future<CustomerSignatureModel> getSignatureById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.reportsSignatures}/$id',
    );
    return CustomerSignatureModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<CustomerSignatureModel> createSignature(
    CreateSignatureInput input,
  ) async {
    final formData = FormData.fromMap({
      'customerName': input.customerName,
      if (input.customerPosition != null)
        'customerPosition': input.customerPosition,
      if (input.workOrderId != null) 'workOrderId': input.workOrderId,
      if (input.workOrderNumber != null)
        'workOrderNumber': input.workOrderNumber,
      if (input.signedAt != null)
        'signedAt': input.signedAt!.toIso8601String(),
      if (input.notes != null) 'notes': input.notes,
      'signature': MultipartFile.fromBytes(
        input.signatureBytes,
        filename: input.fileName,
      ),
    });

    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.reportsSignatures,
      data: formData,
    );
    return CustomerSignatureModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<CustomerSignatureModel> deleteSignature(String id) async {
    final response = await _client.delete<Map<String, dynamic>>(
      '${ApiConstants.reportsSignatures}/$id',
    );
    return CustomerSignatureModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  ServiceReportPage _mapReportPage(Map<String, dynamic>? body) {
    final pagination = _pagination(body);
    final data = body?['data'];
    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(ServiceReportModel.fromJson)
            .toList()
        : <ServiceReport>[];
    return ServiceReportPage(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
    );
  }

  CustomerSignaturePage _mapSignaturePage(Map<String, dynamic>? body) {
    final pagination = _pagination(body);
    final data = body?['data'];
    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(CustomerSignatureModel.fromJson)
            .toList()
        : <CustomerSignature>[];
    return CustomerSignaturePage(
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
