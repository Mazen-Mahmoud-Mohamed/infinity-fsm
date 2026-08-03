import 'package:equatable/equatable.dart';

class GpsSnapshot extends Equatable {
  const GpsSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.recordedAt,
    this.heading,
    this.speed,
    this.altitude,
    this.provider,
    this.fullAddress,
    this.street,
    this.area,
    this.city,
    this.country,
    this.addressResolvedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final double? heading;
  final double? speed;
  final double? altitude;
  final String? provider;
  final DateTime recordedAt;

  /// Reverse-geocoded address fields (optional until resolved).
  final String? fullAddress;
  final String? street;
  final String? area;
  final String? city;
  final String? country;
  final DateTime? addressResolvedAt;

  /// True only when reverse geocoding produced structured place fields.
  bool get hasResolvedAddress =>
      addressResolvedAt != null &&
      ((street ?? '').trim().isNotEmpty ||
          (area ?? '').trim().isNotEmpty ||
          (city ?? '').trim().isNotEmpty ||
          (country ?? '').trim().isNotEmpty ||
          _isMeaningfulFullAddress(fullAddress));

  bool get needsAddressResolution => !hasResolvedAddress;

  static bool _isMeaningfulFullAddress(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return false;
    }
    // Coordinate fallbacks look like "12.34567, 98.76543"
    final coordPattern = RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$');
    return !coordPattern.hasMatch(text);
  }

  GpsSnapshot copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? heading,
    double? speed,
    double? altitude,
    String? provider,
    DateTime? recordedAt,
    String? fullAddress,
    String? street,
    String? area,
    String? city,
    String? country,
    DateTime? addressResolvedAt,
    bool clearAddress = false,
  }) {
    return GpsSnapshot(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      altitude: altitude ?? this.altitude,
      provider: provider ?? this.provider,
      recordedAt: recordedAt ?? this.recordedAt,
      fullAddress: clearAddress ? null : (fullAddress ?? this.fullAddress),
      street: clearAddress ? null : (street ?? this.street),
      area: clearAddress ? null : (area ?? this.area),
      city: clearAddress ? null : (city ?? this.city),
      country: clearAddress ? null : (country ?? this.country),
      addressResolvedAt:
          clearAddress ? null : (addressResolvedAt ?? this.addressResolvedAt),
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        accuracy,
        heading,
        speed,
        altitude,
        provider,
        recordedAt,
        fullAddress,
        street,
        area,
        city,
        country,
        addressResolvedAt,
      ];
}
