import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/push/notification_idempotency_gate.dart';
import 'package:mobile/core/push/notification_navigation.dart';
import 'package:mobile/core/push/pending_notification_store.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService preferences;
  late PendingNotificationStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = PreferencesService(await SharedPreferences.getInstance());
    store = PendingNotificationStore(preferences);
  });

  NotificationNavigationIntent intentFor(String userId) {
    return NotificationNavigationIntent(
      route: RoutePaths.workOrderDetail('wo-a'),
      notificationId: 'n-a',
      idempotencyKey: 'n-a|${RoutePaths.workOrderDetail('wo-a')}|wo-a',
      userId: userId,
    );
  }

  test('User B cannot consume User A pending navigation after logout isolation',
      () async {
    await store.persist(intentFor('user-a'));
    await store.clear();
    expect(await store.takeForUser('user-b'), isNull);
    expect(store.read(), isNull);
  });

  test('User A pending navigation is not opened for User B', () async {
    await store.persist(intentFor('user-a'));
    final forB = await store.takeForUser('user-b');
    expect(forB, isNull);
    expect(store.read(), isNull);
  });

  test('User A pending navigation survives restart only for User A', () async {
    await store.persist(intentFor('user-a'));

    final restoredPrefs = PreferencesService(await SharedPreferences.getInstance());
    final restored = PendingNotificationStore(restoredPrefs);
    expect(restored.read()?.userId, 'user-a');
    expect(restored.read()?.route, RoutePaths.workOrderDetail('wo-a'));

    final stolen = await restored.takeForUser('user-b');
    expect(stolen, isNull);

    await store.persist(intentFor('user-a'));
    final owned = await PendingNotificationStore(
      PreferencesService(await SharedPreferences.getInstance()),
    ).takeForUser('user-a');
    expect(owned?.route, RoutePaths.workOrderDetail('wo-a'));
    expect(owned?.userId, 'user-a');
  });

  test('legacy pending JSON without userId is discarded', () async {
    await preferences.setString(
      StorageKeys.pendingNotificationNav,
      '{"route":"/work-orders/wo-a","notificationId":"n-a"}',
    );
    expect(await store.takeForUser('user-a'), isNull);
    expect(store.read(), isNull);
  });

  test('intent JSON round-trip includes userId', () {
    final intent = intentFor('user-a');
    final restored = NotificationNavigationIntent.fromJson(intent.toJson());
    expect(restored?.userId, 'user-a');
    expect(restored?.route, intent.route);
  });

  group('NotificationIdempotencyGate', () {
    test('same key is skipped for the same user', () {
      final gate = NotificationIdempotencyGate();
      expect(gate.shouldSkip('k1', userId: 'a'), isFalse);
      expect(gate.shouldSkip('k1', userId: 'a'), isTrue);
    });

    test('same key is not skipped after switching users', () {
      final gate = NotificationIdempotencyGate();
      expect(gate.shouldSkip('k1', userId: 'a'), isFalse);
      expect(gate.shouldSkip('k1', userId: 'b'), isFalse);
      expect(gate.shouldSkip('k1', userId: 'b'), isTrue);
    });

    test('clear isolates logout', () {
      final gate = NotificationIdempotencyGate();
      expect(gate.shouldSkip('k1', userId: 'a'), isFalse);
      gate.clear();
      expect(gate.shouldSkip('k1', userId: 'b'), isFalse);
    });
  });
}
