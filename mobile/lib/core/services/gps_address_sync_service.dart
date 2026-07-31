import 'dart:convert';

import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';

/// Queues GPS points that still need reverse-geocoded address after sync.
class GpsAddressSyncService {
  GpsAddressSyncService({
    required DioClient dioClient,
    required PreferencesService preferences,
    required ConnectivityService connectivity,
    required AddressResolverService addressResolver,
  })  : _dio = dioClient,
        _preferences = preferences,
        _connectivity = connectivity,
        _addressResolver = addressResolver;

  final DioClient _dio;
  final PreferencesService _preferences;
  final ConnectivityService _connectivity;
  final AddressResolverService _addressResolver;

  Future<void> enqueueAttendance({
    required String clientEventId,
    required GpsSnapshot gps,
  }) async {
    if (!gps.needsAddressResolution) {
      return;
    }
    await _enqueue({
      'kind': 'attendance',
      'clientEventId': clientEventId,
      'latitude': gps.latitude,
      'longitude': gps.longitude,
      'accuracy': gps.accuracy,
      'recordedAt': gps.recordedAt.toIso8601String(),
      'heading': gps.heading,
      'speed': gps.speed,
      'provider': gps.provider,
      'retryCount': 0,
    });
  }

  Future<void> enqueueOvertime({
    required String sessionId,
    required String point,
    required GpsSnapshot gps,
  }) async {
    if (!gps.needsAddressResolution || sessionId.startsWith('local-')) {
      return;
    }
    await _enqueue({
      'kind': 'overtime',
      'sessionId': sessionId,
      'point': point,
      'latitude': gps.latitude,
      'longitude': gps.longitude,
      'accuracy': gps.accuracy,
      'recordedAt': gps.recordedAt.toIso8601String(),
      'heading': gps.heading,
      'speed': gps.speed,
      'provider': gps.provider,
      'retryCount': 0,
    });
  }

  Future<void> processQueue() async {
    if (!await _connectivity.isConnected) {
      return;
    }

    final queue = _readQueue();
    if (queue.isEmpty) {
      return;
    }

    final remaining = <Map<String, dynamic>>[];

    for (final item in queue) {
      try {
        final gps = GpsSnapshot(
          latitude: (item['latitude'] as num).toDouble(),
          longitude: (item['longitude'] as num).toDouble(),
          accuracy: (item['accuracy'] as num?)?.toDouble() ?? 0,
          recordedAt: DateTime.tryParse(item['recordedAt']?.toString() ?? '') ??
              DateTime.now().toUtc(),
          heading: (item['heading'] as num?)?.toDouble(),
          speed: (item['speed'] as num?)?.toDouble(),
          provider: item['provider']?.toString(),
        );

        final resolved = await _addressResolver.resolveStructured(gps);
        if (!resolved.isResolved) {
          final retries = (item['retryCount'] as int? ?? 0) + 1;
          if (retries < 8) {
            remaining.add({...item, 'retryCount': retries});
          }
          continue;
        }

        final enriched = _addressResolver.apply(gps, resolved);
        final kind = item['kind']?.toString();

        if (kind == 'attendance') {
          await _dio.post<Map<String, dynamic>>(
            ApiConstants.attendanceGpsAddress,
            data: {
              'clientEventId': item['clientEventId'],
              'fullAddress': enriched.fullAddress,
              'street': enriched.street,
              'area': enriched.area,
              'city': enriched.city,
              'country': enriched.country,
              'addressResolvedAt':
                  enriched.addressResolvedAt?.toIso8601String(),
            },
          );
        } else if (kind == 'overtime') {
          final sessionId = item['sessionId']?.toString();
          if (sessionId == null || sessionId.isEmpty) {
            continue;
          }
          await _dio.patch<Map<String, dynamic>>(
            ApiConstants.overtimeGpsAddress(sessionId),
            data: {
              'point': item['point'] ?? 'start',
              'fullAddress': enriched.fullAddress,
              'street': enriched.street,
              'area': enriched.area,
              'city': enriched.city,
              'country': enriched.country,
              'addressResolvedAt':
                  enriched.addressResolvedAt?.toIso8601String(),
            },
          );
        }
      } on Object {
        final retries = (item['retryCount'] as int? ?? 0) + 1;
        if (retries < 8) {
          remaining.add({...item, 'retryCount': retries});
        }
      }
    }

    await _writeQueue(remaining);
  }

  Future<void> _enqueue(Map<String, dynamic> item) async {
    final queue = _readQueue();
    final key = item['kind'] == 'attendance'
        ? 'attendance:${item['clientEventId']}'
        : 'overtime:${item['sessionId']}:${item['point']}';

    queue.removeWhere((existing) {
      final existingKey = existing['kind'] == 'attendance'
          ? 'attendance:${existing['clientEventId']}'
          : 'overtime:${existing['sessionId']}:${existing['point']}';
      return existingKey == key;
    });
    queue.add(item);
    await _writeQueue(queue);
  }

  List<Map<String, dynamic>> _readQueue() {
    final raw = _preferences.getString(StorageKeys.pendingGpsAddressQueue);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> queue) async {
    if (queue.isEmpty) {
      await _preferences.remove(StorageKeys.pendingGpsAddressQueue);
      return;
    }
    await _preferences.setString(
      StorageKeys.pendingGpsAddressQueue,
      jsonEncode(queue),
    );
  }
}
