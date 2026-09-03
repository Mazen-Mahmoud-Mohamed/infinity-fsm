import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/push/android_notification_channels.dart';

void main() {
  group('AndroidNotificationChannels', () {
    test('startup list creates default and updates channels before FCM', () {
      expect(
        AndroidNotificationChannels.requiredAtStartup.map((c) => c.id),
        [
          AndroidNotificationChannels.defaultId,
          AndroidNotificationChannels.updatesId,
        ],
      );
    });

    test('updates channel matches backend app-update FCM channelId', () {
      expect(AndroidNotificationChannels.updatesId, 'infinity_updates');
      expect(AndroidNotificationChannels.updates.id, 'infinity_updates');
      expect(AndroidNotificationChannels.updates.name, 'INFINITY Updates');
      expect(
        AndroidNotificationChannels.updates.description,
        'Application update availability',
      );
      expect(
        AndroidNotificationChannels.updates.importance,
        Importance.high,
      );
    });

    test('default channel remains infinity_default', () {
      expect(AndroidNotificationChannels.defaultId, 'infinity_default');
      expect(
        AndroidNotificationChannels.defaultChannel.id,
        'infinity_default',
      );
      expect(
        AndroidNotificationChannels.defaultChannel.importance,
        Importance.defaultImportance,
      );
    });
  });
}
