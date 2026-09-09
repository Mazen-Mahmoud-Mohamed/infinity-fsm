import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/presentation/utils/notification_inbox_visibility.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_notification_policy.dart';

const _technician = CurrentUser(
  id: 'tech-1',
  companyId: 'c1',
  email: 'tech@example.com',
  firstName: 'Field',
  lastName: 'Tech',
  fullName: 'Field Tech',
  roles: ['TECHNICIAN'],
  permissions: [],
);

const _admin = CurrentUser(
  id: 'admin-1',
  companyId: 'c1',
  email: 'admin@example.com',
  firstName: 'Admin',
  lastName: 'User',
  fullName: 'Admin User',
  roles: ['ADMIN'],
  permissions: [],
);

const _manager = CurrentUser(
  id: 'mgr-1',
  companyId: 'c1',
  email: 'mgr@example.com',
  firstName: 'Manager',
  lastName: 'User',
  fullName: 'Manager User',
  roles: ['SUPERVISOR'],
  permissions: [],
);

AppNotification _woNotification() => const AppNotification(
      id: 'n-wo',
      title: 'Assigned',
      body: 'WO body',
      category: NotificationCategory.workOrders,
      module: 'work_orders',
      entityType: 'work_order',
      entityId: 'wo1',
      data: {'type': 'work_order', 'workOrderId': 'wo1'},
    );

AppNotification _otNotification() => const AppNotification(
      id: 'n-ot',
      title: 'Overtime',
      body: 'OT body',
      category: NotificationCategory.overtime,
      module: 'overtime',
      entityType: 'overtime',
      entityId: 'ot1',
      data: {'type': 'overtime', 'overtimeId': 'ot1'},
    );

AppNotification _appUpdateNotification() => const AppNotification(
      id: 'n-upd',
      title: 'Update available',
      body: 'v1.0.22',
      category: NotificationCategory.settings,
      module: 'app_update',
      entityType: 'app_update',
      data: {'type': 'app_update', 'version': '1.0.22'},
    );

AppNotification _generalNotification() => const AppNotification(
      id: 'n-gen',
      title: 'Hello',
      body: 'General',
      category: NotificationCategory.general,
      module: 'general',
    );

void main() {
  group('TechnicianInterfaceNotificationPolicy mapping', () {
    test('maps work order signals to workOrders section', () {
      expect(
        TechnicianInterfaceNotificationPolicy.sectionForNotification(
          _woNotification(),
        ),
        TechnicianInterfaceNotificationSection.workOrders,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.sectionForPayload({
          'type': 'WORK_ORDER_ASSIGNED',
          'workOrderId': 'wo1',
        }),
        TechnicianInterfaceNotificationSection.workOrders,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.sectionForRoute(
          RoutePaths.workOrderDetail('wo1'),
        ),
        TechnicianInterfaceNotificationSection.workOrders,
      );
    });

    test('maps overtime signals to overtime section', () {
      expect(
        TechnicianInterfaceNotificationPolicy.sectionForNotification(
          _otNotification(),
        ),
        TechnicianInterfaceNotificationSection.overtime,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.sectionForPayload({
          'type': 'OVERTIME_STARTED',
          'overtimeId': 'ot1',
        }),
        TechnicianInterfaceNotificationSection.overtime,
      );
    });

    test('app_update is never gated by profile or other toggles', () {
      expect(
        TechnicianInterfaceNotificationPolicy.sectionForNotification(
          _appUpdateNotification(),
        ),
        TechnicianInterfaceNotificationSection.none,
      );
      const allOff = TechnicianInterfaceConfig(
        workOrders: false,
        overtime: false,
        profile: false,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isNotificationVisible(
          user: _technician,
          config: allOff,
          notification: _appUpdateNotification(),
        ),
        isTrue,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isPayloadVisible(
          user: _technician,
          config: allOff,
          data: {'type': 'app_update', 'version': '1.0.22'},
        ),
        isTrue,
      );
    });

    test('unknown/general notifications remain allowed', () {
      const allOff = TechnicianInterfaceConfig(
        workOrders: false,
        overtime: false,
        profile: false,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isNotificationVisible(
          user: _technician,
          config: allOff,
          notification: _generalNotification(),
        ),
        isTrue,
      );
    });

    test('inventory/assets/pm are not gated by Technician Interface', () {
      const allOff = TechnicianInterfaceConfig(
        workOrders: false,
        overtime: false,
        profile: false,
      );
      for (final module in ['inventory', 'assets', 'pm', 'maintenance']) {
        final item = AppNotification(
          id: 'n-$module',
          title: module,
          body: module,
          category: AppNotification.categoryFromModule(module),
          module: module,
        );
        expect(
          TechnicianInterfaceNotificationPolicy.isNotificationVisible(
            user: _technician,
            config: allOff,
            notification: item,
          ),
          isTrue,
          reason: module,
        );
      }
    });
  });

  group('TechnicianInterfaceNotificationPolicy visibility', () {
    test('technician + workOrders=false hides work order notification', () {
      const config = TechnicianInterfaceConfig(
        workOrders: false,
        overtime: true,
        profile: true,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isNotificationVisible(
          user: _technician,
          config: config,
          notification: _woNotification(),
        ),
        isFalse,
      );
      expect(
        isVisibleInboxNotification(
          notification: _woNotification(),
          user: _technician,
          config: config,
        ),
        isFalse,
      );
    });

    test('technician + workOrders=true shows work order notification', () {
      const config = TechnicianInterfaceConfig(
        workOrders: true,
        overtime: false,
        profile: false,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isNotificationVisible(
          user: _technician,
          config: config,
          notification: _woNotification(),
        ),
        isTrue,
      );
    });

    test('admin/manager ignore workOrders=false', () {
      const config = TechnicianInterfaceConfig(
        workOrders: false,
        overtime: false,
        profile: false,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isNotificationVisible(
          user: _admin,
          config: config,
          notification: _woNotification(),
        ),
        isTrue,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isNotificationVisible(
          user: _manager,
          config: config,
          notification: _woNotification(),
        ),
        isTrue,
      );
    });

    test('technician + overtime=false hides overtime notification', () {
      const config = TechnicianInterfaceConfig(
        workOrders: true,
        overtime: false,
        profile: true,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isNotificationVisible(
          user: _technician,
          config: config,
          notification: _otNotification(),
        ),
        isFalse,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isPayloadVisible(
          user: _technician,
          config: config,
          data: {'type': 'overtime', 'overtimeId': 'ot1'},
        ),
        isFalse,
      );
    });

    test('null config fails open for technicians', () {
      expect(
        TechnicianInterfaceNotificationPolicy.isNotificationVisible(
          user: _technician,
          config: null,
          notification: _woNotification(),
        ),
        isTrue,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isPayloadVisible(
          user: _technician,
          config: null,
          data: {'type': 'work_order', 'workOrderId': 'wo1'},
        ),
        isTrue,
      );
    });

    test('cached disabled config hides until re-enabled', () {
      const disabled = TechnicianInterfaceConfig(
        workOrders: false,
        overtime: true,
        profile: true,
      );
      const enabled = TechnicianInterfaceConfig(
        workOrders: true,
        overtime: true,
        profile: true,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isNotificationVisible(
          user: _technician,
          config: disabled,
          notification: _woNotification(),
        ),
        isFalse,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isNotificationVisible(
          user: _technician,
          config: enabled,
          notification: _woNotification(),
        ),
        isTrue,
      );
    });

    test('disabled work order payload suppresses foreground toast policy', () {
      const config = TechnicianInterfaceConfig(
        workOrders: false,
        overtime: true,
        profile: true,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.isPayloadVisible(
          user: _technician,
          config: config,
          data: {'type': 'work_order', 'workOrderId': 'wo1'},
        ),
        isFalse,
      );
    });
  });

  group('TechnicianInterfaceNotificationPolicy deep-link guard', () {
    test('blocks work order route when workOrders disabled for technician', () {
      const config = TechnicianInterfaceConfig(
        workOrders: false,
        overtime: true,
        profile: true,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.canNavigateToResolvedRoute(
          user: _technician,
          config: config,
          route: RoutePaths.workOrderDetail('wo1'),
        ),
        isFalse,
      );
    });

    test('allows work order route for admin even when TI disables it', () {
      const config = TechnicianInterfaceConfig(
        workOrders: false,
        overtime: false,
        profile: false,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.canNavigateToResolvedRoute(
          user: _admin,
          config: config,
          route: RoutePaths.workOrderDetail('wo1'),
        ),
        isTrue,
      );
    });

    test('blocks overtime route when overtime disabled for technician', () {
      const config = TechnicianInterfaceConfig(
        workOrders: true,
        overtime: false,
        profile: true,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.canNavigateToResolvedRoute(
          user: _technician,
          config: config,
          route: RoutePaths.overtimeAdminDetail('ot1'),
        ),
        isFalse,
      );
    });

    test('null config fails open for deep links', () {
      expect(
        TechnicianInterfaceNotificationPolicy.canNavigateToResolvedRoute(
          user: _technician,
          config: null,
          route: RoutePaths.workOrderDetail('wo1'),
        ),
        isTrue,
      );
    });
  });
}
