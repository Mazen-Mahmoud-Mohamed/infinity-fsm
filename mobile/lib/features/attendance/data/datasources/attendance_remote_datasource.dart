import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/attendance/data/models/attendance_event_model.dart';
import 'package:mobile/features/attendance/data/models/attendance_record_model.dart';
import 'package:mobile/features/attendance/data/models/attendance_status_snapshot_model.dart';
import 'package:mobile/features/attendance/data/models/attendance_summary_model.dart';
import 'package:mobile/features/attendance/data/models/attendance_today_model.dart';
import 'package:mobile/features/attendance/data/models/break_session_model.dart';
import 'package:mobile/features/attendance/data/models/gps_snapshot_model.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_admin_detail.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_record_page.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';

class AttendanceRemoteDataSource {
  AttendanceRemoteDataSource(this._client);

  final DioClient _client;

  Future<AttendanceRecordModel> clockIn({
    required GpsSnapshot gps,
    required List<int> selfieBytes,
    required String deviceId,
    required String clientEventId,
    required DateTime? clientRecordedAt,
  }) async {
    final formData = _buildActionForm(
      gps: gps,
      deviceId: deviceId,
      clientEventId: clientEventId,
      clientRecordedAt: clientRecordedAt,
      selfieBytes: selfieBytes,
    );

    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.attendanceClockIn,
      data: formData,
    );
    return AttendanceRecordModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<AttendanceRecordModel> clockOut({
    required GpsSnapshot gps,
    required List<int> selfieBytes,
    required String deviceId,
    required String clientEventId,
    required DateTime? clientRecordedAt,
  }) async {
    final formData = _buildActionForm(
      gps: gps,
      deviceId: deviceId,
      clientEventId: clientEventId,
      clientRecordedAt: clientRecordedAt,
      selfieBytes: selfieBytes,
    );

    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.attendanceClockOut,
      data: formData,
    );
    return AttendanceRecordModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<AttendanceRecordModel> breakStart({
    required GpsSnapshot gps,
    required String deviceId,
    required String clientEventId,
    required DateTime? clientRecordedAt,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.attendanceBreakStart,
      data: _buildActionJson(
        gps: gps,
        deviceId: deviceId,
        clientEventId: clientEventId,
        clientRecordedAt: clientRecordedAt,
      ),
    );
    return AttendanceRecordModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<AttendanceRecordModel> breakEnd({
    required GpsSnapshot gps,
    required String deviceId,
    required String clientEventId,
    required DateTime? clientRecordedAt,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.attendanceBreakEnd,
      data: _buildActionJson(
        gps: gps,
        deviceId: deviceId,
        clientEventId: clientEventId,
        clientRecordedAt: clientRecordedAt,
      ),
    );
    return AttendanceRecordModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<AttendanceStatusSnapshotModel> getStatus() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.attendanceStatus,
    );
    return AttendanceStatusSnapshotModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<AttendanceTodayModel> getToday() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.attendanceToday,
    );
    return AttendanceTodayModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<List<AttendanceSummaryModel>> getHistory({
    required int page,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.attendanceHistory,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      },
    );
    final data = response.data?['data'];
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(AttendanceSummaryModel.fromJson)
        .toList();
  }

  Future<AttendanceRecordPage> listAdmin({
    int page = 1,
    int limit = 20,
    AttendanceStatus? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? role,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.attendanceSessions,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.apiValue,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (startDate != null)
          'startDate': startDate.toIso8601String().substring(0, 10),
        if (endDate != null)
          'endDate': endDate.toIso8601String().substring(0, 10),
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      },
    );
    return _mapPage(response.data);
  }

  Future<AttendanceAdminDetail> getAdminDetail(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.attendanceById(id),
    );
    final data = response.data?['data'] as Map<String, dynamic>;
    final attendanceJson = data['attendance'] as Map<String, dynamic>;
    final eventsRaw = data['events'];
    final breaksRaw = data['breakSessions'];

    final events = eventsRaw is List
        ? eventsRaw
            .whereType<Map<String, dynamic>>()
            .map(AttendanceEventModel.fromJson)
            .toList()
        : <AttendanceEventModel>[];

    final breakSessions = breaksRaw is List
        ? breaksRaw
            .whereType<Map<String, dynamic>>()
            .map(BreakSessionModel.fromJson)
            .toList()
        : <BreakSessionModel>[];

    return AttendanceAdminDetail(
      attendance: AttendanceRecordModel.fromJson(attendanceJson),
      events: events,
      breakSessions: breakSessions,
    );
  }

  AttendanceRecordPage _mapPage(Map<String, dynamic>? body) {
    final data = body?['data'];
    final meta = body?['meta'] as Map<String, dynamic>?;
    final pagination = meta?['pagination'] as Map<String, dynamic>? ?? {};

    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(AttendanceRecordModel.fromJson)
            .toList()
        : <AttendanceRecordModel>[];

    final page = _asInt(pagination['page']) ?? 1;
    final limit = _asInt(pagination['limit']) ?? 20;
    final total = _asInt(pagination['total']) ?? items.length;
    final totalPages = _asInt(pagination['totalPages']) ??
        (limit == 0 ? 1 : (total / limit).ceil().clamp(1, 999999));

    return AttendanceRecordPage(
      items: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
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

  Map<String, dynamic> _buildActionJson({
    required GpsSnapshot gps,
    required String deviceId,
    required String clientEventId,
    required DateTime? clientRecordedAt,
  }) {
    return {
      ...GpsSnapshotModel.fromEntity(gps).toJson(),
      'deviceId': deviceId,
      'clientEventId': clientEventId,
      if (clientRecordedAt != null)
        'clientRecordedAt': clientRecordedAt.toIso8601String(),
    };
  }

  FormData _buildActionForm({
    required GpsSnapshot gps,
    required String deviceId,
    required String clientEventId,
    required DateTime? clientRecordedAt,
    required List<int> selfieBytes,
  }) {
    final fields = GpsSnapshotModel.fromEntity(gps).toFormFields();

    return FormData.fromMap({
      ...fields,
      'deviceId': deviceId,
      'clientEventId': clientEventId,
      if (clientRecordedAt != null)
        'clientRecordedAt': clientRecordedAt.toIso8601String(),
      'selfie': MultipartFile.fromBytes(
        selfieBytes,
        filename: 'selfie.jpg',
      ),
    });
  }
}
