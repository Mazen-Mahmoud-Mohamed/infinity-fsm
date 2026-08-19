import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/sync_configuration_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService preferences;
  late SyncConfigurationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = PreferencesService(await SharedPreferences.getInstance());
    service = SyncConfigurationService(preferences);
    await service.load();
  });

  tearDown(() {
    service.dispose();
  });

  test('defaults to 5 minute interval', () {
    expect(service.current.intervalMinutes, 5);
  });

  test('update persists and emits new interval', () async {
    final values = <SyncConfiguration>[];
    final sub = service.onChanged.listen(values.add);

    await service.update(intervalMinutes: 15);
    await Future<void>.delayed(Duration.zero);

    expect(service.current.intervalMinutes, 15);
    expect(values.any((c) => c.intervalMinutes == 15), isTrue);
    expect(preferences.getInt('pref_sync_interval_min'), 15);

    await sub.cancel();
  });

  test('invalid interval normalizes to default', () async {
    await service.update(intervalMinutes: 99);
    expect(service.current.intervalMinutes, 5);
  });
}
