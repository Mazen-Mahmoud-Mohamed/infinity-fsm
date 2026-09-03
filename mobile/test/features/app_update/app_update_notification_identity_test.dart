import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_notification_identity.dart';

void main() {
  group('appUpdateNotificationDedupeKey', () {
    test('builds deterministic version+build key', () {
      expect(
        appUpdateNotificationDedupeKey(version: '1.0.3', build: 4),
        'app-update:v1.0.3:4',
      );
    });

    test('isSameAppUpdateNotification accepts key and legacy version', () {
      expect(
        isSameAppUpdateNotification(
          storedKey: 'app-update:v1.0.3:4',
          version: '1.0.3',
          build: 4,
        ),
        isTrue,
      );
      expect(
        isSameAppUpdateNotification(
          storedKey: '1.0.3',
          version: '1.0.3',
          build: 4,
        ),
        isTrue,
      );
      expect(
        isSameAppUpdateNotification(
          storedKey: 'app-update:v1.0.2:3',
          version: '1.0.3',
          build: 4,
        ),
        isFalse,
      );
    });
  });
}
