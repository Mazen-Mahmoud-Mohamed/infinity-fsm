import 'package:mobile/features/attendance/data/mappers/attendance_json_helpers.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';

class GpsSnapshotModel extends GpsSnapshot {
  const GpsSnapshotModel({
    required super.latitude,
    required super.longitude,
    required super.accuracy,
    required super.recordedAt,
    super.heading,
    super.speed,
    super.altitude,
    super.provider,
    super.fullAddress,
    super.street,
    super.area,
    super.city,
    super.country,
    super.addressResolvedAt,
  });

  factory GpsSnapshotModel.fromJson(Map<String, dynamic> json) {
    return GpsSnapshotModel(
      latitude: readDouble(json, 'latitude'),
      longitude: readDouble(json, 'longitude'),
      accuracy: readDouble(json, 'accuracy'),
      heading: readOptionalDouble(json, 'heading'),
      speed: readOptionalDouble(json, 'speed'),
      altitude: readOptionalDouble(json, 'altitude'),
      provider: optionalString(json, 'provider'),
      recordedAt: requireDateTime(json, 'recordedAt'),
      fullAddress: optionalString(json, 'fullAddress'),
      street: optionalString(json, 'street'),
      area: optionalString(json, 'area'),
      city: optionalString(json, 'city'),
      country: optionalString(json, 'country'),
      addressResolvedAt: parseDateTime(json['addressResolvedAt']),
    );
  }

  factory GpsSnapshotModel.fromEntity(GpsSnapshot entity) {
    return GpsSnapshotModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      heading: entity.heading,
      speed: entity.speed,
      altitude: entity.altitude,
      provider: entity.provider,
      recordedAt: entity.recordedAt,
      fullAddress: entity.fullAddress,
      street: entity.street,
      area: entity.area,
      city: entity.city,
      country: entity.country,
      addressResolvedAt: entity.addressResolvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'heading': heading,
      'speed': speed,
      'altitude': altitude,
      'provider': provider,
      'recordedAt': recordedAt.toIso8601String(),
      'fullAddress': fullAddress,
      'street': street,
      'area': area,
      'city': city,
      'country': country,
      'addressResolvedAt': addressResolvedAt?.toIso8601String(),
    };
  }

  Map<String, String> toFormFields() {
    return {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'accuracy': accuracy.toString(),
      if (heading != null) 'heading': heading.toString(),
      if (speed != null) 'speed': speed.toString(),
      if (altitude != null) 'altitude': altitude.toString(),
      'provider': ?provider,
      'recordedAt': recordedAt.toIso8601String(),
      if (fullAddress != null && fullAddress!.trim().isNotEmpty)
        'fullAddress': fullAddress!,
      if (fullAddress != null && fullAddress!.trim().isNotEmpty)
        'address': fullAddress!,
      if (street != null && street!.trim().isNotEmpty) 'street': street!,
      if (area != null && area!.trim().isNotEmpty) 'area': area!,
      if (city != null && city!.trim().isNotEmpty) 'city': city!,
      if (country != null && country!.trim().isNotEmpty) 'country': country!,
      if (addressResolvedAt != null)
        'addressResolvedAt': addressResolvedAt!.toIso8601String(),
    };
  }
}
