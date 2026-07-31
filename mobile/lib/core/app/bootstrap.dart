import 'package:flutter/widgets.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/device_id_generator.dart';

Future<void> bootstrap(Future<void> Function() runApp) async {
  WidgetsFlutterBinding.ensureInitialized();
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
