import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/push/push_notification_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/device_id_generator.dart';

Future<void> bootstrap(Future<void> Function() runApp) async {
  WidgetsFlutterBinding.ensureInitialized();
  _ensureJustAudioWindowsBackend();
  // Timezone data loads lazily on first OvertimeCalculator use (see
  // ensureTimeZonesInitialized) — keep it off the critical startup path.
  await configureDependencies();
  await _ensureDeviceId();
  // Local notification plugin + optional Firebase (Android) — no auth required.
  await getIt<PushNotificationService>().initialize();
  await runApp();
}

/// Registers media_kit as the just_audio Windows backend.
/// Android / iOS / macOS keep the native just_audio plugins (unchanged).
void _ensureJustAudioWindowsBackend() {
  if (kIsWeb) return;
  if (!Platform.isWindows) return;
  JustAudioMediaKit.ensureInitialized(
    windows: true,
    linux: false,
    android: false,
    iOS: false,
    macOS: false,
  );
  if (kDebugMode) {
    debugPrint(
      '[OvertimeVoice] just_audio Windows backend initialized (media_kit)',
    );
  }
}

Future<void> _ensureDeviceId() async {
  final preferencesService = getIt<PreferencesService>();
  final deviceId = preferencesService.getString(StorageKeys.deviceId);

  if (deviceId == null || deviceId.isEmpty) {
    await preferencesService.setString(
      StorageKeys.deviceId,
      DeviceIdGenerator.generate(),
    );
  }
}
