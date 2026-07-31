import 'package:mobile/features/settings/domain/entities/settings_entities.dart';

class OrganizationSettingsModel extends OrganizationSettings {
  const OrganizationSettingsModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.workingHours,
    required super.address,
    super.logoUrl,
    super.contactEmail,
    super.contactPhone,
    super.timezone,
    super.isActive,
    super.updatedAt,
  });

  factory OrganizationSettingsModel.fromJson(Map<String, dynamic> json) {
    final address = json['address'];
    final hours = json['workingHours'];
    return OrganizationSettingsModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
      contactEmail: json['contactEmail']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      timezone: json['timezone']?.toString(),
      address: CompanyAddressSettings(
        line1: address is Map ? address['line1']?.toString() : null,
        line2: address is Map ? address['line2']?.toString() : null,
        city: address is Map ? address['city']?.toString() : null,
        governorate: address is Map ? address['governorate']?.toString() : null,
        country: address is Map ? address['country']?.toString() : null,
        postalCode: address is Map ? address['postalCode']?.toString() : null,
      ),
      workingHours: WorkingHoursSettings(
        start: hours is Map ? hours['start']?.toString() ?? '09:00' : '09:00',
        end: hours is Map ? hours['end']?.toString() ?? '17:00' : '17:00',
        timezone: hours is Map
            ? hours['timezone']?.toString() ?? 'Asia/Baghdad'
            : 'Asia/Baghdad',
      ),
      isActive: json['isActive'] != false,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class SystemInfoModel extends SystemInfo {
  const SystemInfoModel({
    required super.apiStatus,
    required super.databaseStatus,
    required super.storageUsage,
    required super.apiVersion,
    required super.backendVersion,
    required super.environment,
    required super.uptimeSeconds,
    super.timestamp,
  });

  factory SystemInfoModel.fromJson(Map<String, dynamic> json) {
    final storage = json['storageUsage'];
    return SystemInfoModel(
      apiStatus: json['apiStatus']?.toString() ?? 'unknown',
      databaseStatus: json['databaseStatus']?.toString() ?? 'unknown',
      storageUsage: StorageUsageInfo(
        provider: storage is Map
            ? storage['provider']?.toString() ?? 'unavailable'
            : 'unavailable',
        usedBytes: storage is Map ? (storage['usedBytes'] as num?)?.toInt() : null,
        usedMb: storage is Map ? (storage['usedMb'] as num?)?.toDouble() : null,
        note: storage is Map ? storage['note']?.toString() : null,
      ),
      apiVersion: json['apiVersion']?.toString() ?? '',
      backendVersion: json['backendVersion']?.toString() ?? '',
      environment: json['environment']?.toString() ?? '',
      uptimeSeconds: (json['uptimeSeconds'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
    );
  }
}
