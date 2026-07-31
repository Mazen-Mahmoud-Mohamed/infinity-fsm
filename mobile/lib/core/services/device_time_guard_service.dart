import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/attendance_constants.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/monotonic_clock_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';

/// Result of device clock validation before attendance/overtime.
class DeviceTimeCheckResult {
  const DeviceTimeCheckResult.ok({this.trustedUtc})
      : isValid = true,
        reasonCode = null;

  const DeviceTimeCheckResult.rejected(this.reasonCode)
      : isValid = false,
        trustedUtc = null;

  final bool isValid;

  /// Estimated current UTC from server + monotonic elapsed (never raw device).
  final DateTime? trustedUtc;

  /// Stable message key for localization (`deviceTimeIncorrect`).
  final String? reasonCode;
}

/// Validates device wall clock against server UTC (online) or
/// last trusted server timestamp + platform monotonic elapsed (offline).
class DeviceTimeGuardService {
  DeviceTimeGuardService({
    required DioClient dioClient,
    required PreferencesService preferences,
    required ConnectivityService connectivity,
    required MonotonicClockService monotonicClock,
    this.maxSkew = AttendanceConstants.maxDeviceClockSkew,
  })  : _dio = dioClient,
        _preferences = preferences,
        _connectivity = connectivity,
        _monotonic = monotonicClock;

  final DioClient _dio;
  final PreferencesService _preferences;
  final ConnectivityService _connectivity;
  final MonotonicClockService _monotonic;
  final Duration maxSkew;

  DateTime? _cachedTrustedUtc;
  DateTime? _cachedTrustedAt;
  static const _onlineTimeCacheTtl = Duration(seconds: 45);

  Future<DeviceTimeCheckResult> validate({
    DateTime? lastAttendanceAt,
    String module = 'attendance',
  }) async {
    final cached = _cachedTrustedUtc;
    final cachedAt = _cachedTrustedAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) <= _onlineTimeCacheTtl) {
      final monoTrusted = cached.add(DateTime.now().difference(cachedAt));
      return DeviceTimeCheckResult.ok(trustedUtc: monoTrusted);
    }

    final isOnline = await _connectivity.isConnected;
    if (isOnline) {
      return _validateOnline(module: module);
    }
    return _validateOffline(
      lastAttendanceAt: lastAttendanceAt,
      module: module,
    );
  }

  Future<DeviceTimeCheckResult> _validateOnline({required String module}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.serverTime,
      );
      final data = _unwrap(response.data);
      final unixMs = data['unixMs'];
      final utcNowRaw = data['utcNow']?.toString();
      final skewSeconds = data['maxSkewSeconds'];

      final serverUtc = unixMs is num
          ? DateTime.fromMillisecondsSinceEpoch(unixMs.toInt(), isUtc: true)
          : (utcNowRaw != null
              ? DateTime.parse(utcNowRaw).toUtc()
              : null);

      if (serverUtc == null) {
        return _validateOffline(module: module);
      }

      final effectiveSkew = skewSeconds is num
          ? Duration(seconds: skewSeconds.toInt())
          : maxSkew;

      final deviceUtc = DateTime.now().toUtc();
      final delta = deviceUtc.difference(serverUtc).abs();

      await _rememberServerTime(serverUtc);

      if (delta > effectiveSkew) {
        _cachedTrustedUtc = null;
        _cachedTrustedAt = null;
        await _queueSecurityEvent(
          type: 'device_clock_skew',
          module: module,
          metadata: {
            'mode': 'online',
            'deviceUtc': deviceUtc.toIso8601String(),
            'serverUtc': serverUtc.toIso8601String(),
            'deltaSeconds': delta.inSeconds,
            'thresholdSeconds': effectiveSkew.inSeconds,
          },
        );
        return const DeviceTimeCheckResult.rejected('deviceTimeIncorrect');
      }

      _cachedTrustedUtc = serverUtc;
      _cachedTrustedAt = DateTime.now();
      return DeviceTimeCheckResult.ok(trustedUtc: serverUtc);
    } on Object {
      return _validateOffline(module: module);
    }
  }

  Future<DeviceTimeCheckResult> _validateOffline({
    DateTime? lastAttendanceAt,
    required String module,
  }) async {
    final deviceUtc = DateTime.now().toUtc();
    final lastServerMs =
        _preferences.getInt(StorageKeys.lastSyncedServerUtcMs);
    final lastMonoMs = _preferences.getInt(StorageKeys.lastSyncedMonoMs);
    final lastAttendanceMs =
        _preferences.getInt(StorageKeys.lastAttendanceUtcMs);

    final lastServer = lastServerMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastServerMs, isUtc: true)
        : null;
    final lastAttendance = lastAttendanceAt ??
        (lastAttendanceMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastAttendanceMs, isUtc: true)
            : null);

    // Without a prior successful server sync, never trust the device clock.
    if (lastServer == null || lastMonoMs == null) {
      await _queueSecurityEvent(
        type: 'device_clock_no_anchor',
        module: module,
        metadata: {
          'mode': 'offline',
          'deviceUtc': deviceUtc.toIso8601String(),
          'hasServerAnchor': lastServer != null,
          'hasMonoAnchor': lastMonoMs != null,
        },
      );
      return const DeviceTimeCheckResult.rejected('deviceTimeIncorrect');
    }

    final monoNow = await _monotonic.elapsedRealtimeMs();

    // Monotonic clock reset (reboot) — require online re-sync before trusting time.
    if (monoNow < lastMonoMs) {
      await _queueSecurityEvent(
        type: 'device_clock_mono_reset',
        module: module,
        metadata: {
          'mode': 'offline',
          'deviceUtc': deviceUtc.toIso8601String(),
          'lastServerUtc': lastServer.toIso8601String(),
          'monoNow': monoNow,
          'lastMonoMs': lastMonoMs,
        },
      );
      return const DeviceTimeCheckResult.rejected('deviceTimeIncorrect');
    }

    final monoElapsed = Duration(milliseconds: monoNow - lastMonoMs);
    final trustedNow = lastServer.add(monoElapsed);

    // Compare device wall clock against trusted monotonic estimate.
    final wallDrift = deviceUtc.difference(trustedNow).abs();
    if (wallDrift > maxSkew) {
      await _queueSecurityEvent(
        type: 'device_clock_monotonic_drift',
        module: module,
        metadata: {
          'mode': 'offline',
          'deviceUtc': deviceUtc.toIso8601String(),
          'trustedUtc': trustedNow.toIso8601String(),
          'lastServerUtc': lastServer.toIso8601String(),
          'monoElapsedSeconds': monoElapsed.inSeconds,
          'driftSeconds': wallDrift.inSeconds,
          'thresholdSeconds': maxSkew.inSeconds,
        },
      );
      return const DeviceTimeCheckResult.rejected('deviceTimeIncorrect');
    }

    // Extra safety: wall clock rolled before last attendance / last server time.
    if (deviceUtc.isBefore(lastServer.subtract(maxSkew))) {
      await _queueSecurityEvent(
        type: 'device_clock_rollback',
        module: module,
        metadata: {
          'mode': 'offline',
          'deviceUtc': deviceUtc.toIso8601String(),
          'lastServerUtc': lastServer.toIso8601String(),
        },
      );
      return const DeviceTimeCheckResult.rejected('deviceTimeIncorrect');
    }

    if (lastAttendance != null &&
        deviceUtc.isBefore(lastAttendance.subtract(maxSkew))) {
      await _queueSecurityEvent(
        type: 'device_clock_before_attendance',
        module: module,
        metadata: {
          'mode': 'offline',
          'deviceUtc': deviceUtc.toIso8601String(),
          'lastAttendanceUtc': lastAttendance.toUtc().toIso8601String(),
        },
      );
      return const DeviceTimeCheckResult.rejected('deviceTimeIncorrect');
    }

    return DeviceTimeCheckResult.ok(trustedUtc: trustedNow);
  }

  Future<void> rememberSuccessfulAttendance(DateTime at) async {
    await _preferences.setInt(
      StorageKeys.lastAttendanceUtcMs,
      at.toUtc().millisecondsSinceEpoch,
    );
  }

  Future<void> _rememberServerTime(DateTime serverUtc) async {
    final monoMs = await _monotonic.elapsedRealtimeMs();
    await Future.wait([
      _preferences.setInt(
        StorageKeys.lastSyncedServerUtcMs,
        serverUtc.millisecondsSinceEpoch,
      ),
      _preferences.setInt(
        StorageKeys.lastSyncedDeviceUtcMs,
        DateTime.now().toUtc().millisecondsSinceEpoch,
      ),
      _preferences.setInt(StorageKeys.lastSyncedMonoMs, monoMs),
    ]);
  }

  Future<void> syncSecurityEvents() async {
    if (!await _connectivity.isConnected) {
      return;
    }

    final raw = _preferences.getString(StorageKeys.securityEventQueue);
    if (raw == null || raw.isEmpty) {
      return;
    }

    List<dynamic> events;
    try {
      events = jsonDecode(raw) as List<dynamic>;
    } on Object {
      await _preferences.remove(StorageKeys.securityEventQueue);
      return;
    }

    if (events.isEmpty) {
      return;
    }

    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.securityEvents,
        data: {'events': events},
      );
      await _preferences.remove(StorageKeys.securityEventQueue);
    } on DioException {
      // Keep queued for a later sync attempt.
    } on Object {
      // Keep queued.
    }
  }

  Future<void> _queueSecurityEvent({
    required String type,
    required String module,
    required Map<String, dynamic> metadata,
  }) async {
    final deviceId = _preferences.getString(StorageKeys.deviceId);
    final event = {
      'type': type,
      'module': module,
      'detectedAt': DateTime.now().toUtc().toIso8601String(),
      'deviceId': deviceId,
      'metadata': metadata,
    };

    final existingRaw = _preferences.getString(StorageKeys.securityEventQueue);
    final list = <dynamic>[];
    if (existingRaw != null && existingRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(existingRaw);
        if (decoded is List) {
          list.addAll(decoded);
        }
      } on Object {
        // Reset corrupt queue.
      }
    }
    list.add(event);
    final trimmed = list.length > 50 ? list.sublist(list.length - 50) : list;
    await _preferences.setString(
      StorageKeys.securityEventQueue,
      jsonEncode(trimmed),
    );
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    if (body == null) {
      return {};
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return body;
  }
}
