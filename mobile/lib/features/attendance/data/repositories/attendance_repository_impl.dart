import 'package:flutter/foundation.dart';
import 'package:mobile/core/constants/attendance_constants.dart';
import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/utils/device_id_generator.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:mobile/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:mobile/features/attendance/data/models/attendance_record_model.dart';
import 'package:mobile/features/attendance/data/models/attendance_status_snapshot_model.dart';
import 'package:mobile/features/attendance/data/models/pending_attendance_action_model.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_admin_detail.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_event.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_record_page.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status_snapshot.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_summary.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_today.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/attendance/domain/entities/pending_attendance_action.dart';
import 'package:mobile/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mobile/features/attendance/domain/services/attendance_rules.dart';

String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);

bool _isNetworkFailureCode(String? code) {
  return code == 'OFFLINE' || code == 'TIMEOUT' || code == 'NETWORK_ERROR';
}

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl({
    required this._remote,
    required this._local,
    required this._connectivity,
    required this._addressResolver,
    required this._gpsAddressSync,
  });

  final AttendanceRemoteDataSource _remote;
  final AttendanceLocalDataSource _local;
  final ConnectivityService _connectivity;
  final AddressResolverService _addressResolver;
  final GpsAddressSyncService _gpsAddressSync;

  @override
  Future<Result<AttendanceStatusSnapshot>> getStatus({
    bool forceRefresh = false,
  }) async {
    final isOnline = await _connectivity.isConnected;

    if (!isOnline) {
      final cached = _local.readStatus();
      if (cached != null) {
        return Success(cached);
      }
      return const Failure(
        'errorNoInternet',
        code: 'OFFLINE',
      );
    }

    try {
      final remote = await _remote.getStatus();
      await _local.saveStatus(remote);
      return Success(remote);
    } on Object catch (error) {
      final cached = _local.readStatus();
      if (cached != null) {
        return Success(cached);
      }
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<AttendanceToday>> getToday({bool forceRefresh = false}) async {
    final isOnline = await _connectivity.isConnected;

    if (!isOnline) {
      final cached = _local.readToday();
      if (cached != null) {
        return Success(cached);
      }
      return const Failure(
        'errorNoInternet',
        code: 'OFFLINE',
      );
    }

    try {
      final remote = await _remote.getToday();
      await _local.saveToday(remote);
      return Success(remote);
    } on Object catch (error) {
      final cached = _local.readToday();
      if (cached != null) {
        return Success(cached);
      }
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<List<AttendanceSummaryEntity>>> getHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final isOnline = await _connectivity.isConnected;

    if (!isOnline) {
      final cached = _local.readHistory();
      if (cached.isNotEmpty) {
        return Success(cached);
      }
      return const Failure(
        'errorNoInternet',
        code: 'OFFLINE',
      );
    }

    try {
      final remote = await _remote.getHistory(
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );
      if (page == 1) {
        await _local.saveHistory(remote);
      }
      return Success(remote);
    } on Object catch (error) {
      final cached = _local.readHistory();
      if (cached.isNotEmpty) {
        return Success(cached);
      }
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<AttendanceRecordPage>> listAdmin({
    int page = 1,
    int limit = 20,
    AttendanceStatus? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? role,
  }) async {
    try {
      final result = await _remote.listAdmin(
        page: page,
        limit: limit,
        status: status,
        search: search,
        startDate: startDate,
        endDate: endDate,
        userId: userId,
        role: role,
      );
      return Success(result);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<AttendanceAdminDetail>> getAdminDetail(String id) async {
    try {
      final result = await _remote.getAdminDetail(id);
      return Success(result);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<AttendanceActionOutcome>> clockIn({
    required GpsSnapshot gps,
    required List<int> selfieBytes,
    required String deviceId,
  }) {
    return _performAction(
      type: AttendanceEventType.clockIn,
      gps: gps,
      selfieBytes: selfieBytes,
      deviceId: deviceId,
      validate: AttendanceRules.assertCanClockIn,
      submitOnline: (clientEventId, resolvedGps) => _remote.clockIn(
        gps: resolvedGps,
        selfieBytes: selfieBytes,
        deviceId: deviceId,
        clientEventId: clientEventId,
        clientRecordedAt: null,
      ),
    );
  }

  @override
  Future<Result<AttendanceActionOutcome>> clockOut({
    required GpsSnapshot gps,
    required List<int> selfieBytes,
    required String deviceId,
  }) {
    return _performAction(
      type: AttendanceEventType.clockOut,
      gps: gps,
      selfieBytes: selfieBytes,
      deviceId: deviceId,
      validate: AttendanceRules.assertCanClockOut,
      submitOnline: (clientEventId, resolvedGps) => _remote.clockOut(
        gps: resolvedGps,
        selfieBytes: selfieBytes,
        deviceId: deviceId,
        clientEventId: clientEventId,
        clientRecordedAt: null,
      ),
    );
  }

  @override
  Future<Result<AttendanceActionOutcome>> breakStart({
    required GpsSnapshot gps,
    required String deviceId,
  }) {
    return _performAction(
      type: AttendanceEventType.breakStart,
      gps: gps,
      selfieBytes: const [],
      deviceId: deviceId,
      validate: AttendanceRules.assertCanStartBreak,
      submitOnline: (clientEventId, resolvedGps) => _remote.breakStart(
        gps: resolvedGps,
        deviceId: deviceId,
        clientEventId: clientEventId,
        clientRecordedAt: null,
      ),
    );
  }

  @override
  Future<Result<AttendanceActionOutcome>> breakEnd({
    required GpsSnapshot gps,
    required String deviceId,
  }) {
    return _performAction(
      type: AttendanceEventType.breakEnd,
      gps: gps,
      selfieBytes: const [],
      deviceId: deviceId,
      validate: AttendanceRules.assertCanEndBreak,
      submitOnline: (clientEventId, resolvedGps) => _remote.breakEnd(
        gps: resolvedGps,
        deviceId: deviceId,
        clientEventId: clientEventId,
        clientRecordedAt: null,
      ),
    );
  }

  @override
  Future<List<PendingAttendanceAction>> getPendingActions() async {
    return _local.readQueue();
  }

  @override
  Future<Result<void>> syncPendingActions() async {
    if (!await _connectivity.isConnected) {
      return const Failure(
        'errorNoInternet',
        code: 'OFFLINE',
      );
    }

    final queue = _local.readQueue();
    if (queue.isEmpty) {
      return const Success(null);
    }

    for (final action in List<PendingAttendanceActionModel>.of(queue)) {
      final result = await _submitQueuedAction(action);

      switch (result) {
        case Success():
          await _local.removeFromQueue(action.clientEventId);
        case Failure(message: final message, code: final code):
          final bumped = action.copyWith(
            retryCount: action.retryCount + 1,
            lastError: message,
          );

          if (_isNetworkFailureCode(code)) {
            await _local.updateQueueItem(
              PendingAttendanceActionModel.fromEntity(bumped),
            );
            return Failure(message, code: code);
          }

          if (bumped.retryCount >= AttendanceConstants.maxSyncRetries) {
            await _local.removeFromQueue(action.clientEventId);
          } else {
            await _local.updateQueueItem(
              PendingAttendanceActionModel.fromEntity(bumped),
            );
          }
      }
    }

    return const Success(null);
  }

  Future<Result<void>> _submitQueuedAction(
    PendingAttendanceActionModel action,
  ) async {
    try {
      final gps = await _enrichGpsAddress(action.gps);
      if (gps != action.gps) {
        await _local.updateQueueItem(
          PendingAttendanceActionModel.fromEntity(
            action.copyWith(gps: gps),
          ),
        );
      }

      switch (action.type) {
        case AttendanceEventType.clockIn:
          await _remote.clockIn(
            gps: gps,
            selfieBytes: action.selfieBytes ?? const [],
            deviceId: action.deviceId,
            clientEventId: action.clientEventId,
            clientRecordedAt: action.clientRecordedAt,
          );
        case AttendanceEventType.clockOut:
          await _remote.clockOut(
            gps: gps,
            selfieBytes: action.selfieBytes ?? const [],
            deviceId: action.deviceId,
            clientEventId: action.clientEventId,
            clientRecordedAt: action.clientRecordedAt,
          );
        case AttendanceEventType.breakStart:
          await _remote.breakStart(
            gps: gps,
            deviceId: action.deviceId,
            clientEventId: action.clientEventId,
            clientRecordedAt: action.clientRecordedAt,
          );
        case AttendanceEventType.breakEnd:
          await _remote.breakEnd(
            gps: gps,
            deviceId: action.deviceId,
            clientEventId: action.clientEventId,
            clientRecordedAt: action.clientRecordedAt,
          );
      }
      if (gps.needsAddressResolution) {
        await _gpsAddressSync.enqueueAttendance(
          clientEventId: action.clientEventId,
          gps: gps,
        );
      }
      return const Success(null);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  /// Resolves address for queued offline actions without blocking sync on failure.
  Future<GpsSnapshot> _enrichGpsAddress(GpsSnapshot gps) async {
    if (!gps.needsAddressResolution) {
      return gps;
    }
    try {
      final resolved = await _addressResolver.resolveStructured(gps);
      return _addressResolver.apply(gps, resolved);
    } on Object {
      return gps;
    }
  }

  Future<Result<AttendanceActionOutcome>> _performAction({
    required AttendanceEventType type,
    required GpsSnapshot gps,
    required List<int> selfieBytes,
    required String deviceId,
    required void Function(AttendanceStatus status) validate,
    required Future<AttendanceRecordModel> Function(
      String clientEventId,
      GpsSnapshot gps,
    ) submitOnline,
  }) async {
    try {
      AttendanceRules.assertGpsAccuracy(
        gps,
        AttendanceConstants.gpsAccuracyThresholdMeters,
      );

      final effectiveStatus = await _resolveEffectiveStatus();
      validate(effectiveStatus);

      final requiresSelfie = type == AttendanceEventType.clockIn ||
          type == AttendanceEventType.clockOut;
      final isOnline = await _connectivity.isConnected;
      final clientEventId = DeviceIdGenerator.generate();
      final clientRecordedAt = gps.recordedAt;
      final resolvedGps = await _enrichGpsAddress(gps);

      if (!isOnline) {
        if (requiresSelfie && kIsWeb) {
          return const Failure(
            'attendanceWebOfflinePhotoRequired',
            code: 'WEB_OFFLINE_UNSUPPORTED',
          );
        }
        return _queueAction(
          type: type,
          gps: resolvedGps,
          selfieBytes: requiresSelfie ? selfieBytes : null,
          deviceId: deviceId,
          clientEventId: clientEventId,
          clientRecordedAt: clientRecordedAt,
        );
      }

      try {
        final record = await submitOnline(clientEventId, resolvedGps);
        if (resolvedGps.needsAddressResolution) {
          await _gpsAddressSync.enqueueAttendance(
            clientEventId: clientEventId,
            gps: resolvedGps,
          );
        }
        return _onActionSuccess(record);
      } on Object catch (error) {
        final mapped = NetworkErrorMapper.map<AttendanceActionOutcome>(error);
        final isNetworkFailure = _isNetworkFailureCode(mapped.code);

        if (isNetworkFailure && !(requiresSelfie && kIsWeb)) {
          return _queueAction(
            type: type,
            gps: resolvedGps,
            selfieBytes: requiresSelfie ? selfieBytes : null,
            deviceId: deviceId,
            clientEventId: clientEventId,
            clientRecordedAt: clientRecordedAt,
          );
        }
        return mapped;
      }
    } on AttendanceGpsRejected catch (error) {
      return Failure(error.message, code: 'GPS_ACCURACY_TOO_LOW');
    } on AttendanceRuleViolation catch (error) {
      return Failure(error.message, code: 'RULE_VIOLATION');
    }
  }

  Future<Result<AttendanceActionOutcome>> _onActionSuccess(
    AttendanceRecordModel record,
  ) async {
    final snapshot = AttendanceStatusSnapshotModel(
      status: record.status,
      date: record.date,
      clockInAt: record.clockIn?.at,
      clockOutAt: record.clockOut?.at,
      activeBreakStartAt:
          record.status == AttendanceStatus.onBreak ? DateTime.now() : null,
      workingMinutes: record.workingMinutes,
      breakMinutes: record.breakMinutes,
      breakCount: record.breakCount,
      liveWorkingSeconds: record.workingMinutes * 60,
      serverTime: DateTime.now(),
    );

    await _local.saveStatus(snapshot);

    return Success(
      AttendanceActionOutcome(status: snapshot, queuedOffline: false),
    );
  }

  Future<Result<AttendanceActionOutcome>> _queueAction({
    required AttendanceEventType type,
    required GpsSnapshot gps,
    required List<int>? selfieBytes,
    required String deviceId,
    required String clientEventId,
    required DateTime clientRecordedAt,
  }) async {
    final action = PendingAttendanceActionModel(
      clientEventId: clientEventId,
      type: type,
      gps: gps,
      selfieBytes: selfieBytes != null ? Uint8List.fromList(selfieBytes) : null,
      deviceId: deviceId,
      clientRecordedAt: clientRecordedAt,
      createdAt: DateTime.now(),
    );

    await _local.enqueue(action);

    final snapshot = _buildOptimisticSnapshot(type, clientRecordedAt);
    await _local.saveStatus(snapshot);

    return Success(
      AttendanceActionOutcome(status: snapshot, queuedOffline: true),
    );
  }

  Future<AttendanceStatus> _resolveEffectiveStatus() async {
    var snapshot = _local.readStatus();

    if (await _connectivity.isConnected) {
      try {
        final remote = await _remote.getStatus();
        snapshot = remote;
        await _local.saveStatus(remote);
      } on Object {
        // Fall back to cached snapshot below.
      }
    }

    final base = snapshot != null && snapshot.date == _todayKey()
        ? snapshot.status
        : AttendanceStatus.notStarted;

    return _applyQueueToStatus(base, _local.readQueue());
  }

  AttendanceStatus _applyQueueToStatus(
    AttendanceStatus base,
    List<PendingAttendanceActionModel> queue,
  ) {
    var status = base;
    for (final action in queue) {
      switch (action.type) {
        case AttendanceEventType.clockIn:
          status = AttendanceStatus.clockedIn;
        case AttendanceEventType.clockOut:
          status = AttendanceStatus.clockedOut;
        case AttendanceEventType.breakStart:
          status = AttendanceStatus.onBreak;
        case AttendanceEventType.breakEnd:
          status = AttendanceStatus.clockedIn;
      }
    }
    return status;
  }

  AttendanceStatusSnapshotModel _buildOptimisticSnapshot(
    AttendanceEventType type,
    DateTime at,
  ) {
    final previous = _local.readStatus();
    final sameDay = previous != null && previous.date == _todayKey();

    var status = sameDay ? previous.status : AttendanceStatus.notStarted;
    var clockInAt = sameDay ? previous.clockInAt : null;
    var clockOutAt = sameDay ? previous.clockOutAt : null;
    var activeBreakStartAt = sameDay ? previous.activeBreakStartAt : null;
    var breakCount = sameDay ? previous.breakCount : 0;
    var breakMinutes = sameDay ? previous.breakMinutes : 0;
    final workingMinutes = sameDay ? previous.workingMinutes : 0;

    switch (type) {
      case AttendanceEventType.clockIn:
        status = AttendanceStatus.clockedIn;
        clockInAt = at;
      case AttendanceEventType.clockOut:
        status = AttendanceStatus.clockedOut;
        clockOutAt = at;
      case AttendanceEventType.breakStart:
        status = AttendanceStatus.onBreak;
        activeBreakStartAt = at;
        breakCount += 1;
      case AttendanceEventType.breakEnd:
        status = AttendanceStatus.clockedIn;
        if (activeBreakStartAt != null) {
          breakMinutes += at.difference(activeBreakStartAt).inMinutes;
        }
        activeBreakStartAt = null;
    }

    return AttendanceStatusSnapshotModel(
      status: status,
      date: _todayKey(),
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
      activeBreakStartAt: activeBreakStartAt,
      workingMinutes: workingMinutes,
      breakMinutes: breakMinutes,
      breakCount: breakCount,
      liveWorkingSeconds: workingMinutes * 60,
      serverTime: at,
    );
  }
}
