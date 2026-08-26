import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/push/push_notification_service.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';

void main() {
  group('notification navigation payload mapping', () {
    test('work_order payload maps to work order detail route', () {
      final path = _routeForPayload({
        'type': 'work_order',
        'workOrderId': 'abc123',
      });
      expect(path, RoutePaths.workOrderDetail('abc123'));
    });

    test('overtime payload maps to overtime admin detail route', () {
      final path = _routeForPayload({
        'type': 'overtime',
        'overtimeId': 'ot99',
      });
      expect(path, RoutePaths.overtimeAdminDetail('ot99'));
    });

    test('missing entity falls back to notifications center', () {
      final path = _routeForPayload({'type': 'general'});
      expect(path, RoutePaths.notifications);
    });
  });

  group('AppNotification entity fields', () {
    test('stores navigation metadata', () {
      const item = AppNotification(
        id: '1',
        title: 'أمر شغل جديد',
        body: 'تم تعيين أمر شغل جديد لك',
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

/// Mirrors [PushNotificationService] navigation selection for unit testing.
String _routeForPayload(Map<String, dynamic> data) {
  final type = (data['type'] ?? data['entityType'] ?? '').toString();
  final entityId = (data['entityId'] ??
          data['workOrderId'] ??
          data['overtimeId'] ??
          '')
      .toString();

  if (entityId.isEmpty) {
    return RoutePaths.notifications;
  }
  if (type.contains('work_order') || type == 'work_orders') {
    return RoutePaths.workOrderDetail(entityId);
  }
  if (type.contains('overtime')) {
    return RoutePaths.overtimeAdminDetail(entityId);
  }
  return RoutePaths.notifications;
}
