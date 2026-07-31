import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/attendance/data/models/gps_snapshot_model.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/data/models/overtime_session_model.dart';
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
    required String deviceId,
    required String clientRequestId,
    required String? address,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) async {
    final formData = _buildForm(
      gps: gps,
      deviceId: deviceId,
      photoBytes: photoBytes,
      address: address,
      extra: {
        'type': type.apiValue,
        'clientRequestId': clientRequestId,
        if (startedAt != null) 'startedAt': startedAt.toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt.toIso8601String(),
        if (durationSeconds != null)
          'durationSeconds': durationSeconds.toString(),
      },
    );

    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.overtimeStart,
      data: formData,
    );
    return OvertimeSessionModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<OvertimeSessionModel> end({
    required String sessionId,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    required String deviceId,
    required String? address,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) async {
    final formData = _buildForm(
      gps: gps,
      deviceId: deviceId,
      photoBytes: photoBytes,
      address: address,
      extra: {
        if (startedAt != null) 'startedAt': startedAt.toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt.toIso8601String(),
        if (durationSeconds != null)
          'durationSeconds': durationSeconds.toString(),
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

  Future<OvertimeSessionModel> approve(String id) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.overtimeSessions}/$id/approve',
    );
    return OvertimeSessionModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<OvertimeSessionModel> reject(
    String id, {
    String? rejectionReason,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.overtimeSessions}/$id/reject',
      data: {
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
          'rejectionReason': rejectionReason.trim(),
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
    final totalPages = _asInt(pagination['totalPages']) ??
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
    required String? address,
    Map<String, String> extra = const {},
  }) {
    final fields = GpsSnapshotModel.fromEntity(gps).toFormFields();
    return FormData.fromMap({
      ...fields,
      ...extra,
      'deviceId': deviceId,
      if (address != null && address.isNotEmpty) 'address': address,
      'photo': MultipartFile.fromBytes(
        photoBytes,
        filename: 'overtime.jpg',
      ),
    });
  }
}
