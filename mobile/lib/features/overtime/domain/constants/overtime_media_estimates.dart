import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';

/// Static estimates for admin configuration previews (not actual file sizes).
class OvertimeMediaEstimates {
  OvertimeMediaEstimates._();

  /// Approximate KB per minute of AAC voice recording by quality tier.
  static int kbPerMinute(String quality) {
    switch (OvertimeMediaConfig.normalizeVoiceQuality(quality)) {
      case 'high':
        return 900;
      case 'low':
        return 220;
      case 'medium':
      default:
        return 450;
    }
  }

  /// Estimated maximum voice file size in KB for duration + quality.
  static int estimatedMaxVoiceKb(int durationMinutes, String quality) {
    final minutes = OvertimeMediaConfig.normalizeMinutes(durationMinutes);
    return kbPerMinute(quality) * minutes;
  }

  /// Estimated maximum voice file size in bytes.
  static int estimatedMaxVoiceBytes(int durationMinutes, String quality) {
    return estimatedMaxVoiceKb(durationMinutes, quality) * 1024;
  }

  /// Typical average photo size cap in MB for upload estimates.
  static int estimatedPhotoMb(Object maxPhotoSize) {
    final mb = OvertimeMediaConfig.maxPhotoSizeMbOrNull(maxPhotoSize);
    if (mb != null) {
      return mb;
    }
    return 5;
  }

  /// Combined voice + photo upload estimate in MB (rounded).
  static double estimatedTotalUploadMb({
    required int durationMinutes,
    required String quality,
    required Object maxPhotoSize,
  }) {
    final voiceMb = estimatedMaxVoiceKb(durationMinutes, quality) / 1024;
    return voiceMb + estimatedPhotoMb(maxPhotoSize);
  }

  /// True when configuration may produce large uploads (20 min + high).
  static bool shouldWarnLargeRecording({
    required int durationMinutes,
    required String quality,
  }) {
    return durationMinutes >= 20 &&
        OvertimeMediaConfig.normalizeVoiceQuality(quality) == 'high';
  }
}
