import 'package:record/record.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';

/// Maps company voice quality setting to [RecordConfig] options.
class OvertimeVoiceRecordConfig {
  OvertimeVoiceRecordConfig._();

  static RecordConfig resolve(String? quality) {
    switch (OvertimeMediaConfig.normalizeVoiceQuality(quality)) {
      case 'high':
        return const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        );
      case 'low':
        return const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 32000,
          sampleRate: 22050,
          numChannels: 1,
        );
      case 'medium':
      default:
        return const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
        );
    }
  }
}
