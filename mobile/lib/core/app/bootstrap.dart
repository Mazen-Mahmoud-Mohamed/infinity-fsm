import 'package:flutter/widgets.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/device_id_generator.dart';
import 'package:timezone/data/latest.dart' as tzdata;

Future<void> bootstrap(Future<void> Function() runApp) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Company business calendar (Africa/Cairo) for overtime / working-day logic.
  tzdata.initializeTimeZones();
  await configureDependencies();
  await _ensureDeviceId();
  await runApp();
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
