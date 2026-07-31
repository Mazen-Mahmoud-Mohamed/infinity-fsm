import 'package:geocoding/geocoding.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';

/// Structured reverse-geocoded address.
class ResolvedAddress {
  const ResolvedAddress({
    this.fullAddress,
    this.street,
    this.area,
    this.city,
    this.country,
    this.resolvedAt,
    this.isPlaceholder = false,
  });

  final String? fullAddress;
  final String? street;
  final String? area;
  final String? city;
  final String? country;
  final DateTime? resolvedAt;
  final bool isPlaceholder;

  bool get isResolved =>
      !isPlaceholder &&
      ((fullAddress ?? '').trim().isNotEmpty ||
          (street ?? '').trim().isNotEmpty ||
          (city ?? '').trim().isNotEmpty ||
          (country ?? '').trim().isNotEmpty);
}

/// Resolves human-readable address fields from GPS using platform geocoding.
///
/// Never throws for attendance/overtime — coordinates are always preserved.
class AddressResolverService {
  /// Backward-compatible string resolve used by work orders and overtime UI.
  Future<String> resolve(GpsSnapshot gps) async {
    final resolved = await resolveStructured(gps);
    if (resolved.isResolved) {
      return resolved.fullAddress ?? _coordinateFallback(gps);
    }
    return _coordinateFallback(gps);
  }

  Future<ResolvedAddress> resolveStructured(GpsSnapshot gps) async {
    try {
      final places = await placemarkFromCoordinates(
        gps.latitude,
        gps.longitude,
      );
      if (places.isEmpty) {
        return const ResolvedAddress(isPlaceholder: true);
      }

      final place = places.first;
      final street = _trim(place.street);
      final area = _trim(place.subLocality) ?? _trim(place.subAdministrativeArea);
      final city = _trim(place.locality) ?? _trim(place.administrativeArea);
      final country = _trim(place.country);

      final parts = <String>[
        if (street != null) street,
        if (area != null) area,
        if (city != null) city,
        if (_trim(place.administrativeArea) != null &&
            _trim(place.administrativeArea) != city)
          _trim(place.administrativeArea)!,
        if (country != null) country,
      ];

      if (parts.isEmpty) {
        return const ResolvedAddress(isPlaceholder: true);
      }

      return ResolvedAddress(
        fullAddress: parts.join(', '),
        street: street,
        area: area,
        city: city,
        country: country,
        resolvedAt: DateTime.now().toUtc(),
      );
    } on Object {
      return const ResolvedAddress(isPlaceholder: true);
    }
  }

  /// Applies structured address onto a GPS snapshot without losing coordinates.
  /// Placeholder / failed lookups leave address fields empty for later retry.
  GpsSnapshot apply(GpsSnapshot gps, ResolvedAddress address) {
    if (!address.isResolved) {
      return gps.copyWith(clearAddress: true);
    }
    return gps.copyWith(
      fullAddress: address.fullAddress,
      street: address.street,
      area: address.area,
      city: address.city,
      country: address.country,
      addressResolvedAt: address.resolvedAt ?? DateTime.now().toUtc(),
    );
  }

  String? _trim(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _coordinateFallback(GpsSnapshot gps) {
    return '${gps.latitude.toStringAsFixed(5)}, ${gps.longitude.toStringAsFixed(5)}';
  }
}
