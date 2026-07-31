import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/attendance/data/models/attendance_record_model.dart';
import 'package:mobile/features/attendance/data/models/attendance_status_snapshot_model.dart';
import 'package:mobile/features/attendance/data/models/attendance_summary_model.dart';
import 'package:mobile/features/attendance/data/models/attendance_today_model.dart';
import 'package:mobile/features/attendance/data/models/gps_snapshot_model.dart';
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
