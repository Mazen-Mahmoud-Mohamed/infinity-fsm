import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';

export 'overtime_media_config.dart';

/// Backward-compatible alias — prefer [OvertimeMediaConfig].
class OvertimeVoiceConfig {
  OvertimeVoiceConfig._();

  static const int defaultMaxDurationMinutes =
      OvertimeMediaConfig.defaultMaxDurationMinutes;
  static const List<int> durationOptionsMinutes =
      OvertimeMediaConfig.durationOptionsMinutes;
  static const int defaultMaxDurationSeconds =
      OvertimeMediaConfig.defaultMaxDurationSeconds;
  static const String defaultVoiceQuality =
      OvertimeMediaConfig.defaultVoiceQuality;

  static int secondsFromMinutes(int minutes) =>
      OvertimeMediaConfig.secondsFromMinutes(minutes);

  static int normalizeMinutes(int? minutes) =>
      OvertimeMediaConfig.normalizeMinutes(minutes);
}
