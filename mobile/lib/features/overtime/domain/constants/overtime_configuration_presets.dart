import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';

/// Enterprise configuration presets for overtime voice / media settings.
class OvertimeConfigurationPreset {
  const OvertimeConfigurationPreset({
    required this.id,
    required this.durationMinutes,
    required this.quality,
    required this.maxPhotoSize,
    required this.uploadPolicy,
  });

  final String id;
  final int durationMinutes;
  final String quality;
  final Object maxPhotoSize;
  final String uploadPolicy;

  OvertimeSettingsUpdate toUpdate() {
    return OvertimeSettingsUpdate(
      voiceMaxDurationSeconds:
          OvertimeMediaConfig.secondsFromMinutes(durationMinutes),
      voiceRecordingQuality: quality,
      maxPhotoSize: maxPhotoSize,
      uploadPolicy: uploadPolicy,
      configurationPreset: id,
    );
  }

  bool matches(OvertimeSettings settings) {
    return OvertimeMediaConfig.minutesFromSeconds(
              settings.voiceMaxDurationSeconds,
            ) ==
            durationMinutes &&
        settings.voiceRecordingQuality == quality &&
        settings.maxPhotoSize == maxPhotoSize &&
        settings.uploadPolicy == uploadPolicy;
  }

  static const String customId = 'custom';
  static const String officeId = 'office';
  static const String fieldServiceId = 'field_service';
  static const String heavyMaintenanceId = 'heavy_maintenance';

  static const office = OvertimeConfigurationPreset(
    id: officeId,
    durationMinutes: 2,
    quality: 'low',
    maxPhotoSize: 1,
    uploadPolicy: 'immediately',
  );

  static const fieldService = OvertimeConfigurationPreset(
    id: fieldServiceId,
    durationMinutes: 5,
    quality: 'medium',
    maxPhotoSize: 2,
    uploadPolicy: 'wifi_preferred',
  );

  static const heavyMaintenance = OvertimeConfigurationPreset(
    id: heavyMaintenanceId,
    durationMinutes: 20,
    quality: 'high',
    maxPhotoSize: OvertimeMediaConfig.maxPhotoSizeOriginal,
    uploadPolicy: 'manual',
  );

  static const List<OvertimeConfigurationPreset> selectable = [
    office,
    fieldService,
    heavyMaintenance,
  ];

  static OvertimeSettingsUpdate defaultSettingsUpdate() {
    return OvertimeSettingsUpdate(
      voiceMaxDurationSeconds: OvertimeMediaConfig.defaultMaxDurationSeconds,
      voiceRecordingQuality: OvertimeMediaConfig.defaultVoiceQuality,
      maxPhotoSize: OvertimeMediaConfig.defaultMaxPhotoSizeMb,
      uploadPolicy: OvertimeMediaConfig.defaultUploadPolicy,
      configurationPreset: customId,
      restoreDefaults: true,
    );
  }

  static String detectPresetId(OvertimeSettings? settings) {
    if (settings == null) {
      return customId;
    }
    if (settings.configurationPreset != null &&
        settings.configurationPreset != customId) {
      for (final preset in selectable) {
        if (preset.id == settings.configurationPreset && preset.matches(settings)) {
          return preset.id;
        }
      }
    }
    for (final preset in selectable) {
      if (preset.matches(settings)) {
        return preset.id;
      }
    }
    return customId;
  }
}
