import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/attendance/data/models/gps_snapshot_model.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/data/models/overtime_session_model.dart';
import 'package:mobile/features/overtime/data/trace/overtime_offline_trace.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_export_filters.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';

class OvertimeRemoteDataSource {
  OvertimeRemoteDataSource(this._client);

  final DioClient _client;

  Future<OvertimeSessionModel?> getRunning() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.overtimeRunning,
    );
    final data = response.data?['data'];
    if (data == null) {
      return null;
    }
    if (data is! Map<String, dynamic>) {
      return null;
    }
    return OvertimeSessionModel.fromJson(data);
  }

  Future<OvertimeSessionModel> start({
    required OvertimeType type,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    String? voiceFilename,
    required String deviceId,
    required String clientRequestId,
    required String? address,
    bool isOvernight = false,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    OvertimeOfflineTrace.step(
      'HTTP_REQUEST',
      status: 'entered',
      objectId: clientRequestId,
      detail:
          'POST ${ApiConstants.overtimeStart} photoBytes=${photoBytes.length}',
    );
    final formData = _buildForm(
      gps: gps,
      deviceId: deviceId,
      photoBytes: photoBytes,
      voiceBytes: voiceBytes,
      voiceFilename: voiceFilename,
      address: address,
      extra: {
        'type': type.apiValue,
        'isOvernight': isOvernight ? 'true' : 'false',
        'clientRequestId': clientRequestId,
        if (startedAt != null) 'startedAt': startedAt.toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt.toIso8601String(),
        if (durationSeconds != null)
          'durationSeconds': durationSeconds.toString(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (batteryLevel != null) 'batteryLevel': batteryLevel.toString(),
        if (networkStatus != null && networkStatus.isNotEmpty)
          'networkStatus': networkStatus,
      },
    );

    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.overtimeStart,
      data: formData,
    );
    OvertimeOfflineTrace.step(
      'HTTP_RESPONSE',
      status: 'success',
      objectId: clientRequestId,
      serverId: (response.data?['data'] as Map?)?['id']?.toString(),
      detail:
          'POST ${ApiConstants.overtimeStart} status=${response.statusCode}',
    );
    return OvertimeSessionModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<OvertimeSessionModel> end({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    String? voiceFilename,
    required String deviceId,
    required String? address,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    String? notes,
    String? clientRequestId,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    final formData = _buildForm(
      gps: gps,
      deviceId: deviceId,
      photoBytes: photoBytes,
      voiceBytes: voiceBytes,
      voiceFilename: voiceFilename,
      address: address,
      extra: {
        if (startedAt != null) 'startedAt': startedAt.toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt.toIso8601String(),
        if (durationSeconds != null)
          'durationSeconds': durationSeconds.toString(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (clientRequestId != null && clientRequestId.isNotEmpty)
          'clientRequestId': clientRequestId,
        if (batteryLevel != null) 'batteryLevel': batteryLevel.toString(),
        if (networkStatus != null && networkStatus.isNotEmpty)
          'networkStatus': networkStatus,
      },
    );

    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.overtimeSessions}/$sessionId/end',
      data: formData,
    );
    return OvertimeSessionModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<OvertimeSessionModel> recordArrivedAtWorkSite({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    String? voiceFilename,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    DateTime? checkpointAt,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) {
    return _postCheckpoint(
      path: ApiConstants.overtimeArrivedAtWorkSite(sessionId),
      gps: gps,
      photoBytes: photoBytes,
      voiceBytes: voiceBytes,
      voiceFilename: voiceFilename,
      deviceId: deviceId,
      address: address,
      clientRequestId: clientRequestId,
      checkpointAt: checkpointAt,
      notes: notes,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
    );
  }

  Future<OvertimeSessionModel> recordFinishedWork({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    String? voiceFilename,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    DateTime? checkpointAt,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) {
    return _postCheckpoint(
      path: ApiConstants.overtimeFinishedWork(sessionId),
      gps: gps,
      photoBytes: photoBytes,
      voiceBytes: voiceBytes,
      voiceFilename: voiceFilename,
      deviceId: deviceId,
      address: address,
      clientRequestId: clientRequestId,
      checkpointAt: checkpointAt,
      notes: notes,
      batteryLevel: batteryLevel,
      networkStatus: networkStatus,
    );
  }

  Future<OvertimeSessionModel> _postCheckpoint({
    required String path,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    String? voiceFilename,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    DateTime? checkpointAt,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    final formData = _buildForm(
      gps: gps,
      deviceId: deviceId,
      photoBytes: photoBytes,
      voiceBytes: voiceBytes,
      voiceFilename: voiceFilename,
      address: address,
      extra: {
        'clientRequestId': clientRequestId,
        if (checkpointAt != null)
          'checkpointAt': checkpointAt.toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (batteryLevel != null) 'batteryLevel': batteryLevel.toString(),
        if (networkStatus != null && networkStatus.isNotEmpty)
          'networkStatus': networkStatus,
      },
    );

    final response = await _client.post<Map<String, dynamic>>(
      path,
      data: formData,
    );
    return OvertimeSessionModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<OvertimeSessionPage> listAdmin({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
    String? search,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.overtimeSessions,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': _statusQuery(status),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _mapPage(response.data);
  }

  Future<OvertimeExcelExportResult> exportExcel(
    OvertimeExportFilters filters,
  ) async {
    final response = await _client.get<List<int>>(
      ApiConstants.overtimeExport,
      queryParameters: filters.toQueryParameters(),
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final raw = response.data;
    final bytes = raw is List<int> ? raw : <int>[];
    final disposition = response.headers.value('content-disposition');
    var fileName = 'overtime-export.xlsx';
    if (disposition != null) {
      final match = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
      if (match != null) {
        fileName = match.group(1) ?? fileName;
      }
    }
    final rowHeader = response.headers.value('x-export-row-count');
    return OvertimeExcelExportResult(
      bytes: bytes,
      fileName: fileName,
      rowCount: int.tryParse(rowHeader ?? ''),
    );
  }

  Future<OvertimeSessionPage> listMine({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.overtimeMine,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': _statusQuery(status),
      },
    );
    return _mapPage(response.data);
  }

  Future<OvertimeSessionModel> getById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.overtimeSessions}/$id',
    );
    return OvertimeSessionModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<OvertimeSessionModel> approve(
    String id, {
    String? reviewNotes,
    double? approvedHours,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.overtimeSessions}/$id/approve',
      data: {
        if (reviewNotes != null && reviewNotes.trim().isNotEmpty)
          'reviewNotes': reviewNotes.trim(),
        if (approvedHours != null) 'approvedHours': approvedHours,
      },
    );
    return OvertimeSessionModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<OvertimeSessionModel> reject(
    String id, {
    String? rejectionReason,
    String? reviewNotes,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.overtimeSessions}/$id/reject',
      data: {
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
          'rejectionReason': rejectionReason.trim(),
        if (reviewNotes != null && reviewNotes.trim().isNotEmpty)
          'reviewNotes': reviewNotes.trim(),
      },
    );
    return OvertimeSessionModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  OvertimeSessionPage _mapPage(Map<String, dynamic>? body) {
    final data = body?['data'];
    final meta = body?['meta'] as Map<String, dynamic>?;
    final pagination = meta?['pagination'] as Map<String, dynamic>? ?? {};

    final items = data is List
        ? data
              .whereType<Map<String, dynamic>>()
              .map(OvertimeSessionModel.fromJson)
              .toList()
        : <OvertimeSessionModel>[];

    final page = _asInt(pagination['page']) ?? 1;
    final limit = _asInt(pagination['limit']) ?? 20;
    final total = _asInt(pagination['total']) ?? items.length;
    final totalPages =
        _asInt(pagination['totalPages']) ??
        (limit == 0 ? 1 : (total / limit).ceil().clamp(1, 999999));

    return OvertimeSessionPage(
      items: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  String _statusQuery(OvertimeStatus status) {
    if (status == OvertimeStatus.pendingReview) {
      return 'PENDING';
    }
    return status.apiValue;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  FormData _buildForm({
    required GpsSnapshot gps,
    required String deviceId,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    String? voiceFilename,
    required String? address,
    Map<String, String> extra = const {},
  }) {
    final fields = GpsSnapshotModel.fromEntity(gps).toFormFields();
    final map = <String, dynamic>{
      ...fields,
      ...extra,
      'deviceId': deviceId,
      if (address != null && address.isNotEmpty) 'address': address,
      'photo': MultipartFile.fromBytes(photoBytes, filename: 'overtime.jpg'),
    };
    if (voiceBytes != null && voiceBytes.isNotEmpty) {
      map['voiceNote'] = MultipartFile.fromBytes(
        voiceBytes,
        filename: voiceFilename ?? 'voice.m4a',
        contentType: DioMediaType('audio', 'mp4'),
      );
    }
    return FormData.fromMap(map);
  }
}
