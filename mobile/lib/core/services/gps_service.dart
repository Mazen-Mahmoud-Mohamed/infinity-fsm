import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/constants/attendance_constants.dart';

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationException implements Exception {
  LocationException(this.reason, this.message);

  final LocationFailureReason reason;
  final String message;

  @override
  String toString() => message;
}

class GpsReading {
  const GpsReading({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.recordedAt,
    this.heading,
    this.speed,
    this.provider,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final double? heading;
  final double? speed;
  final String? provider;
  final DateTime recordedAt;

  bool get isAccurateEnough =>
      accuracy <= AttendanceConstants.gpsAccuracyThresholdMeters;
}

class GpsService {
  Future<GpsReading> getCurrentReading() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        LocationFailureReason.serviceDisabled,
        'locationServicesDisabled',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          LocationFailureReason.permissionDenied,
          'locationPermissionRequired',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        LocationFailureReason.permissionDeniedForever,
        'locationPermissionDeniedForever',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: AttendanceConstants.gpsTimeout,
        ),
      );

      return GpsReading(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        heading: position.heading.isNaN ? null : position.heading,
        speed: position.speed.isNaN ? null : position.speed,
        provider: 'fused',
        recordedAt: position.timestamp,
      );
    } on TimeoutException {
      throw LocationException(
        LocationFailureReason.timeout,
        'locationTimeout',
      );
    } on LocationServiceDisabledException {
      throw LocationException(
        LocationFailureReason.serviceDisabled,
        'locationServicesDisabled',
      );
    }
  }
}
