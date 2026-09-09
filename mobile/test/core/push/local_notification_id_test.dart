import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/push/local_notification_id.dart';

void main() {
  group('localNotificationIdFor', () {
    test('same notificationId always maps to the same id', () {
      const id = '64f1a2b3c4d5e6f7a8b9c0d1';
      expect(
        localNotificationIdFor(notificationId: id),
        localNotificationIdFor(notificationId: id),
      );
    });

    test('different notificationIds normally produce different ids', () {
      final a = localNotificationIdFor(notificationId: 'n-aaa');
      final b = localNotificationIdFor(notificationId: 'n-bbb');
      expect(a, isNot(b));
    });

    test('long UUID-like ids are handled safely', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final id = localNotificationIdFor(notificationId: uuid);
      expect(id, inInclusiveRange(1, kLocalNotificationIdMax));
      expect(
        localNotificationIdFor(notificationId: uuid),
        id,
      );
    });

    test('result stays within signed 31-bit plugin range', () {
      final samples = [
        'short',
        '64f1a2b3c4d5e6f7a8b9c0d1',
        'very-long-notification-id-' * 8,
        r'id with spaces and رمز عربي',
      ];
      for (final sample in samples) {
        final id = localNotificationIdFor(notificationId: sample);
        expect(id, inInclusiveRange(1, kLocalNotificationIdMax));
        expect(id, isNonNegative);
      }
    });

    test('does not depend on current time', () {
      const id = 'stable-id';
      final first = localNotificationIdFor(notificationId: id);
      final second = localNotificationIdFor(notificationId: id);
      expect(first, second);
      expect(first, isNot(DateTime.now().millisecondsSinceEpoch ~/ 1000));
    });

    test('empty id uses deterministic fallback seed', () {
      final a = localNotificationIdFor(
        notificationId: '',
        fallbackSeed: 'title|body',
      );
      final b = localNotificationIdFor(
        notificationId: '   ',
        fallbackSeed: 'title|body',
      );
      expect(a, b);
      expect(a, inInclusiveRange(1, kLocalNotificationIdMax));
    });
  });
}
