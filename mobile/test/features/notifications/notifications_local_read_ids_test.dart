import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService preferences;
  late NotificationsLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = PreferencesService(await SharedPreferences.getInstance());
    local = NotificationsLocalDataSource(preferences);
  });

  test('local read IDs are isolated between users', () async {
    await local.bindUser('user-a');
    await local.markAsRead('n1');
    expect(local.getReadIds(), {'n1'});

    await local.clearSession();
    expect(local.getReadIds(), isEmpty);

    await local.bindUser('user-b');
    expect(local.getReadIds(), isEmpty);

    await local.markAsRead('n2');
    expect(local.getReadIds(), {'n2'});

    await local.bindUser('user-a');
    expect(local.getReadIds(), {'n1'});
    expect(local.getReadIds(), isNot(contains('n2')));
  });

  test('unscoped legacy key is migrated then removed', () async {
    await preferences.setString(
      NotificationsLocalDataSource.legacyReadIdsKey,
      '["legacy-1"]',
    );
    await local.bindUser('user-a');
    expect(local.getReadIds(), {'legacy-1'});
    expect(
      preferences.getString(NotificationsLocalDataSource.legacyReadIdsKey),
      isNull,
    );

    await local.clearSession();
    await local.bindUser('user-b');
    expect(local.getReadIds(), isEmpty);
  });
}
