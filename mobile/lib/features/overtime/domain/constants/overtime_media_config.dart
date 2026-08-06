/// System-wide overtime media configuration (voice, photos, uploads).
class OvertimeMediaConfig {
  OvertimeMediaConfig._();

  // Voice duration (stored in seconds on backend; UI shows minutes).
  static const int defaultMaxDurationMinutes = 5;
  static const List<int> durationOptionsMinutes = [2, 5, 10, 15, 20];
  static const int defaultMaxDurationSeconds = defaultMaxDurationMinutes * 60;
  static const List<int> durationOptionsSeconds = [120, 300, 600, 900, 1200];

  // Voice recording quality.
  static const String defaultVoiceQuality = 'medium';
  static const List<String> voiceQualityOptions = ['high', 'medium', 'low'];

  // Maximum photo upload size (MB). Null = original (no compression target).
  static const int defaultMaxPhotoSizeMb = 2;
  static const List<int> maxPhotoSizeOptionsMb = [1, 2, 5];
  static const String maxPhotoSizeOriginal = 'original';

  // Upload policy.
  static const String defaultUploadPolicy = 'immediately';
  static const List<String> uploadPolicyOptions = [
    'immediately',
    'wifi_preferred',
    'wifi_only',
    'manual',
    'ask_every_time',
  ];

  static int secondsFromMinutes(int minutes) {
    if (durationOptionsMinutes.contains(minutes)) {
      return minutes * 60;
    }
    return defaultMaxDurationSeconds;
  }

  static int minutesFromSeconds(int seconds) {
    if (durationOptionsSeconds.contains(seconds)) {
      return seconds ~/ 60;
    }
    return defaultMaxDurationMinutes;
  }

  static int normalizeDurationSeconds(int? seconds) {
    if (seconds != null && durationOptionsSeconds.contains(seconds)) {
      return seconds;
    }
    return defaultMaxDurationSeconds;
  }

  static int normalizeMinutes(int? minutes) {
    if (minutes != null && durationOptionsMinutes.contains(minutes)) {
      return minutes;
    }
    return defaultMaxDurationMinutes;
  }

  static String normalizeVoiceQuality(String? quality) {
    final normalized = quality?.trim().toLowerCase();
    if (normalized != null && voiceQualityOptions.contains(normalized)) {
      return normalized;
    }
    return defaultVoiceQuality;
  }

  /// Returns null when [value] is original (no size limit).
  static Object normalizeMaxPhotoSize(Object? value) {
    if (value == maxPhotoSizeOriginal || value == 'original') {
      return maxPhotoSizeOriginal;
    }
    final n = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (n != null && maxPhotoSizeOptionsMb.contains(n)) {
      return n;
    }
    return defaultMaxPhotoSizeMb;
  }

  static int? maxPhotoSizeMbOrNull(Object value) {
    if (value == maxPhotoSizeOriginal) {
      return null;
    }
    return value is int ? value : int.tryParse(value.toString());
  }

  static String normalizeUploadPolicy(String? policy) {
    final normalized = policy?.trim().toLowerCase();
    if (normalized != null && uploadPolicyOptions.contains(normalized)) {
      return normalized;
    }
    return defaultUploadPolicy;
  }
}
