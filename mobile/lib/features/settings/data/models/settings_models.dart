import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';
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
            ? hours['timezone']?.toString() ?? 'Africa/Cairo'
            : 'Africa/Cairo',
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

class OvertimeSettingsModel extends OvertimeSettings {
  const OvertimeSettingsModel({
    required super.voiceMaxDurationSeconds,
    required super.voiceDurationOptionsSeconds,
    required super.voiceRecordingQuality,
    required super.voiceQualityOptions,
    required super.maxPhotoSize,
    required super.maxPhotoSizeOptions,
    required super.uploadPolicy,
    required super.uploadPolicyOptions,
    super.configurationPreset,
  });

  factory OvertimeSettingsModel.fromJson(Map<String, dynamic> json) {
    final durationOptionsRaw = json['voiceDurationOptionsSeconds'];
    final durationOptions = durationOptionsRaw is List
        ? durationOptionsRaw
            .map((e) => (e as num?)?.toInt())
            .whereType<int>()
            .toList()
        : OvertimeMediaConfig.durationOptionsSeconds;

    final qualityOptionsRaw = json['voiceQualityOptions'];
    final qualityOptions = qualityOptionsRaw is List
        ? qualityOptionsRaw.map((e) => e.toString()).toList()
        : OvertimeMediaConfig.voiceQualityOptions;

    final photoOptionsRaw = json['maxPhotoSizeOptions'];
    final photoOptions = photoOptionsRaw is List
        ? photoOptionsRaw.map(_parsePhotoSize).toList()
        : <Object>[
            ...OvertimeMediaConfig.maxPhotoSizeOptionsMb,
            OvertimeMediaConfig.maxPhotoSizeOriginal,
          ];

    final policyOptionsRaw = json['uploadPolicyOptions'];
    final policyOptions = policyOptionsRaw is List
        ? policyOptionsRaw.map((e) => e.toString()).toList()
        : OvertimeMediaConfig.uploadPolicyOptions;

    return OvertimeSettingsModel(
      voiceMaxDurationSeconds: OvertimeMediaConfig.normalizeDurationSeconds(
        (json['voiceMaxDurationSeconds'] as num?)?.toInt(),
      ),
      voiceDurationOptionsSeconds: durationOptions.isEmpty
          ? OvertimeMediaConfig.durationOptionsSeconds
          : durationOptions,
      voiceRecordingQuality: OvertimeMediaConfig.normalizeVoiceQuality(
        json['voiceRecordingQuality']?.toString(),
      ),
      voiceQualityOptions: qualityOptions.isEmpty
          ? OvertimeMediaConfig.voiceQualityOptions
          : qualityOptions,
      maxPhotoSize: _parsePhotoSize(json['maxPhotoSize']),
      maxPhotoSizeOptions: photoOptions.isEmpty
          ? <Object>[
              ...OvertimeMediaConfig.maxPhotoSizeOptionsMb,
              OvertimeMediaConfig.maxPhotoSizeOriginal,
            ]
          : photoOptions,
      uploadPolicy: OvertimeMediaConfig.normalizeUploadPolicy(
        json['uploadPolicy']?.toString(),
      ),
      uploadPolicyOptions: policyOptions.isEmpty
          ? OvertimeMediaConfig.uploadPolicyOptions
          : policyOptions,
      configurationPreset: json['configurationPreset']?.toString(),
    );
  }

  static Object _parsePhotoSize(Object? value) {
    return OvertimeMediaConfig.normalizeMaxPhotoSize(value);
  }
}

class OvertimeMediaConfigModel extends OvertimeMediaConfigEntity {
  const OvertimeMediaConfigModel({
    required super.voiceMaxDurationSeconds,
    required super.voiceRecordingQuality,
    required super.maxPhotoSize,
    required super.uploadPolicy,
  });

  factory OvertimeMediaConfigModel.fromJson(Map<String, dynamic> json) {
    final seconds = (json['voiceMaxDurationSeconds'] as num?)?.toInt();
    final legacyMinutes = (json['voiceMaxDurationMinutes'] as num?)?.toInt();
    return OvertimeMediaConfigModel(
      voiceMaxDurationSeconds: OvertimeMediaConfig.normalizeDurationSeconds(
        seconds ?? (legacyMinutes != null ? legacyMinutes * 60 : null),
      ),
      voiceRecordingQuality: OvertimeMediaConfig.normalizeVoiceQuality(
        json['voiceRecordingQuality']?.toString(),
      ),
      maxPhotoSize: OvertimeSettingsModel._parsePhotoSize(json['maxPhotoSize']),
      uploadPolicy: OvertimeMediaConfig.normalizeUploadPolicy(
        json['uploadPolicy']?.toString(),
      ),
    );
  }
}

@Deprecated('Use OvertimeMediaConfigModel')
typedef OvertimeVoiceDurationConfigModel = OvertimeMediaConfigModel;
