import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';

String formatEstimatedSize(AppLocalizations l10n, int kb) {
  if (kb >= 1024) {
    final mb = kb / 1024;
    return l10n.settingsOvertimeEstimateMb(mb.toStringAsFixed(mb >= 10 ? 0 : 1));
  }
  return l10n.settingsOvertimeEstimateKb(kb);
}

String formatBytes(AppLocalizations l10n, int bytes) {
  if (bytes >= 1024 * 1024) {
    return l10n.settingsOvertimeFileSizeMb(
      (bytes / (1024 * 1024)).toStringAsFixed(1),
    );
  }
  if (bytes >= 1024) {
    return l10n.settingsOvertimeFileSizeKb((bytes / 1024).round());
  }
  return l10n.settingsOvertimeFileSizeBytes(bytes);
}

String voiceQualityLabel(AppLocalizations l10n, String quality) {
  switch (OvertimeMediaConfig.normalizeVoiceQuality(quality)) {
    case 'high':
      return l10n.settingsOvertimeVoiceQualityHigh;
    case 'low':
      return l10n.settingsOvertimeVoiceQualityLow;
    default:
      return l10n.settingsOvertimeVoiceQualityMedium;
  }
}

String uploadPolicyLabel(AppLocalizations l10n, String policy) {
  switch (OvertimeMediaConfig.normalizeUploadPolicy(policy)) {
    case 'wifi_preferred':
      return l10n.settingsOvertimeUploadPolicyWifiPreferred;
    case 'wifi_only':
      return l10n.settingsOvertimeUploadPolicyWifiOnly;
    case 'manual':
      return l10n.settingsOvertimeUploadPolicyManual;
    case 'ask_every_time':
      return l10n.settingsOvertimeUploadPolicyAskEveryTime;
    default:
      return l10n.settingsOvertimeUploadPolicyImmediately;
  }
}

String photoSizeLabel(AppLocalizations l10n, Object size) {
  if (size == OvertimeMediaConfig.maxPhotoSizeOriginal) {
    return l10n.settingsOvertimeMaxPhotoSizeOriginal;
  }
  return l10n.settingsOvertimeMaxPhotoSizeMb(size as int);
}

String presetLabel(AppLocalizations l10n, String presetId) {
  switch (presetId) {
    case 'office':
      return l10n.settingsOvertimePresetOffice;
    case 'field_service':
      return l10n.settingsOvertimePresetFieldService;
    case 'heavy_maintenance':
      return l10n.settingsOvertimePresetHeavyMaintenance;
    default:
      return l10n.settingsOvertimePresetCustom;
  }
}
