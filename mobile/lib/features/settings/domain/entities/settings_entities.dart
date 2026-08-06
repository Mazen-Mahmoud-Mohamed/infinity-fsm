import 'package:equatable/equatable.dart';

class WorkingHoursSettings extends Equatable {
  const WorkingHoursSettings({
    required this.start,
    required this.end,
    required this.timezone,
  });

  final String start;
  final String end;
  final String timezone;

  @override
  List<Object?> get props => [start, end, timezone];
}

class CompanyAddressSettings extends Equatable {
  const CompanyAddressSettings({
    this.line1,
    this.line2,
    this.city,
    this.governorate,
    this.country,
    this.postalCode,
  });

  final String? line1;
  final String? line2;
  final String? city;
  final String? governorate;
  final String? country;
  final String? postalCode;

  @override
  List<Object?> get props =>
      [line1, line2, city, governorate, country, postalCode];
}

class OrganizationSettings extends Equatable {
  const OrganizationSettings({
    required this.id,
    required this.name,
    required this.slug,
    required this.workingHours,
    required this.address,
    this.logoUrl,
    this.contactEmail,
    this.contactPhone,
    this.timezone,
    this.isActive = true,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? contactEmail;
  final String? contactPhone;
  final CompanyAddressSettings address;
  final String? timezone;
  final WorkingHoursSettings workingHours;
  final bool isActive;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        logoUrl,
        contactEmail,
        contactPhone,
        address,
        timezone,
        workingHours,
        isActive,
        updatedAt,
      ];
}

class OrganizationSettingsUpsert extends Equatable {
  const OrganizationSettingsUpsert({
    this.name,
    this.contactEmail,
    this.contactPhone,
    this.timezone,
    this.address,
    this.workingHoursStart,
    this.workingHoursEnd,
    this.workingHoursTimezone,
  });

  final String? name;
  final String? contactEmail;
  final String? contactPhone;
  final String? timezone;
  final CompanyAddressSettings? address;
  final String? workingHoursStart;
  final String? workingHoursEnd;
  final String? workingHoursTimezone;

  @override
  List<Object?> get props => [
        name,
        contactEmail,
        contactPhone,
        timezone,
        address,
        workingHoursStart,
        workingHoursEnd,
        workingHoursTimezone,
      ];
}

class StorageUsageInfo extends Equatable {
  const StorageUsageInfo({
    required this.provider,
    this.usedBytes,
    this.usedMb,
    this.note,
  });

  final String provider;
  final int? usedBytes;
  final double? usedMb;
  final String? note;

  @override
  List<Object?> get props => [provider, usedBytes, usedMb, note];
}

class SystemInfo extends Equatable {
  const SystemInfo({
    required this.apiStatus,
    required this.databaseStatus,
    required this.storageUsage,
    required this.apiVersion,
    required this.backendVersion,
    required this.environment,
    required this.uptimeSeconds,
    this.timestamp,
  });

  final String apiStatus;
  final String databaseStatus;
  final StorageUsageInfo storageUsage;
  final String apiVersion;
  final String backendVersion;
  final String environment;
  final int uptimeSeconds;
  final DateTime? timestamp;

  @override
  List<Object?> get props => [
        apiStatus,
        databaseStatus,
        storageUsage,
        apiVersion,
        backendVersion,
        environment,
        uptimeSeconds,
        timestamp,
      ];
}

class OvertimeSettings extends Equatable {
  const OvertimeSettings({
    required this.voiceMaxDurationSeconds,
    required this.voiceDurationOptionsSeconds,
    required this.voiceRecordingQuality,
    required this.voiceQualityOptions,
    required this.maxPhotoSize,
    required this.maxPhotoSizeOptions,
    required this.uploadPolicy,
    required this.uploadPolicyOptions,
    this.configurationPreset,
  });

  final int voiceMaxDurationSeconds;
  final List<int> voiceDurationOptionsSeconds;
  final String voiceRecordingQuality;
  final List<String> voiceQualityOptions;

  /// Integer MB or the string [OvertimeMediaConfig.maxPhotoSizeOriginal].
  final Object maxPhotoSize;
  final List<Object> maxPhotoSizeOptions;
  final String uploadPolicy;
  final List<String> uploadPolicyOptions;
  final String? configurationPreset;

  @override
  List<Object?> get props => [
        voiceMaxDurationSeconds,
        voiceDurationOptionsSeconds,
        voiceRecordingQuality,
        voiceQualityOptions,
        maxPhotoSize,
        maxPhotoSizeOptions,
        uploadPolicy,
        uploadPolicyOptions,
        configurationPreset,
      ];
}

class OvertimeSettingsUpdate extends Equatable {
  const OvertimeSettingsUpdate({
    this.voiceMaxDurationSeconds,
    this.voiceRecordingQuality,
    this.maxPhotoSize,
    this.uploadPolicy,
    this.configurationPreset,
    this.restoreDefaults = false,
  });

  final int? voiceMaxDurationSeconds;
  final String? voiceRecordingQuality;
  final Object? maxPhotoSize;
  final String? uploadPolicy;
  final String? configurationPreset;
  final bool restoreDefaults;

  @override
  List<Object?> get props => [
        voiceMaxDurationSeconds,
        voiceRecordingQuality,
        maxPhotoSize,
        uploadPolicy,
        configurationPreset,
        restoreDefaults,
      ];
}

class OvertimeMediaConfigEntity extends Equatable {
  const OvertimeMediaConfigEntity({
    required this.voiceMaxDurationSeconds,
    required this.voiceRecordingQuality,
    required this.maxPhotoSize,
    required this.uploadPolicy,
  });

  final int voiceMaxDurationSeconds;
  final String voiceRecordingQuality;
  final Object maxPhotoSize;
  final String uploadPolicy;

  factory OvertimeMediaConfigEntity.defaults() {
    return const OvertimeMediaConfigEntity(
      voiceMaxDurationSeconds: 300,
      voiceRecordingQuality: 'medium',
      maxPhotoSize: 2,
      uploadPolicy: 'immediately',
    );
  }

  @override
  List<Object?> get props => [
        voiceMaxDurationSeconds,
        voiceRecordingQuality,
        maxPhotoSize,
        uploadPolicy,
      ];
}

@Deprecated('Use OvertimeMediaConfigEntity')
typedef OvertimeVoiceDurationConfig = OvertimeMediaConfigEntity;
