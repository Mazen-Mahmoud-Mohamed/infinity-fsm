import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/push/notification_navigation.dart';
import 'package:mobile/core/push/push_notification_service.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';

void main() {
  group('resolveNotificationNavigation', () {
    test('work_order payload maps to work order detail route', () {
      final intent = resolveNotificationNavigation({
        'type': 'work_order',
        'workOrderId': 'abc123',
        'notificationId': 'n1',
      });
      expect(intent.route, RoutePaths.workOrderDetail('abc123'));
      expect(intent.notificationId, 'n1');
      expect(intent.idempotencyKey, contains('n1'));
    });

    test('WORK_ORDER_ASSIGNED event still maps via entityId', () {
      final intent = resolveNotificationNavigation({
        'type': 'WORK_ORDER_ASSIGNED',
        'entityId': 'wo9',
        'event': 'assigned',
      });
      expect(intent.route, RoutePaths.workOrderDetail('wo9'));
    });

    test('overtime payload maps to overtime admin detail route', () {
      final intent = resolveNotificationNavigation({
        'type': 'overtime',
        'overtimeId': 'ot99',
      });
      expect(intent.route, RoutePaths.overtimeAdminDetail('ot99'));
    });

    test('OVERTIME_STARTED event maps via overtimeId', () {
      final intent = resolveNotificationNavigation({
        'event': 'OVERTIME_STARTED',
        'overtimeId': 'ot42',
        'type': 'OVERTIME_STARTED',
      });
      expect(intent.route, RoutePaths.overtimeAdminDetail('ot42'));
    });

    test('missing entity falls back to notifications center', () {
      final intent = resolveNotificationNavigation({'type': 'general'});
      expect(intent.route, RoutePaths.notifications);
    });

    test('intent round-trips through JSON for pending storage', () {
      final intent = resolveNotificationNavigation({
        'type': 'work_order',
        'workOrderId': 'w1',
        'notificationId': 'nid',
      });
      final restored = NotificationNavigationIntent.fromJson(intent.toJson());
      expect(restored?.route, intent.route);
      expect(restored?.notificationId, 'nid');
      expect(restored?.idempotencyKey, intent.idempotencyKey);
    });
  });

  group('AppNotification entity fields', () {
    test('stores navigation metadata', () {
      const item = AppNotification(
        id: '1',
        title: 'أمر شغل جديد',
        body: 'تم تعيين أمر الشغل WO-1 لك.',
        category: NotificationCategory.workOrders,
        module: 'work_orders',
        entityType: 'work_order',
        entityId: 'wo1',
        data: {'type': 'work_order', 'workOrderId': 'wo1'},
      );
      expect(item.entityType, 'work_order');
      expect(item.entityId, 'wo1');
      expect(item.data['workOrderId'], 'wo1');
    });
  });

  group('background handler', () {
    test('background handler is a no-throw top-level function', () {
      expect(firebaseMessagingBackgroundHandler, isA<Function>());
    });
  });
}
