import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/push/notification_deep_link_coordinator.dart';
import 'package:mobile/core/push/notification_navigation.dart';
import 'package:mobile/core/push/pending_notification_store.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/services/window_focus_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeWindowFocus extends WindowFocusService {
  @override
  Future<void> focusApp() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GoRouter router;
  late PendingNotificationStore pending;
  late NotificationDeepLinkCoordinator coordinator;

  Future<void> pumpRouter(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    pending = PendingNotificationStore(PreferencesService(prefs));
    router = GoRouter(
      initialLocation: RoutePaths.dashboard,
      routes: [
        GoRoute(
          path: RoutePaths.dashboard,
          builder: (_, __) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: RoutePaths.workOrders,
          builder: (_, __) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => Text('wo:${state.pathParameters['id']}'),
            ),
          ],
        ),
        GoRoute(
          path: '/overtime/admin',
          builder: (_, __) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => Text('ot:${state.pathParameters['id']}'),
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.settingsUpdates,
          builder: (_, __) => const Text('updates'),
        ),
        GoRoute(
          path: RoutePaths.notifications,
          builder: (_, __) => const Text('inbox'),
        ),
      ],
    );
    coordinator = NotificationDeepLinkCoordinator(
      router: router,
      pending: pending,
      windowFocus: _FakeWindowFocus(),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  group('shellBranchForRoute', () {
    test('maps work order detail to work-orders branch', () {
      expect(
        NotificationDeepLinkCoordinator.shellBranchForRoute(
          RoutePaths.workOrderDetail('abc123'),
        ),
        TechnicianInterfaceNavigation.branchWorkOrders,
      );
    });

    test('maps overtime admin detail to overtime branch', () {
      expect(
        NotificationDeepLinkCoordinator.shellBranchForRoute(
          RoutePaths.overtimeAdminDetail('ot1'),
        ),
        TechnicianInterfaceNavigation.branchOvertime,
      );
    });

    test('maps settings updates to settings branch', () {
      expect(
        NotificationDeepLinkCoordinator.shellBranchForRoute(
          RoutePaths.settingsUpdates,
        ),
        TechnicianInterfaceNavigation.branchSettings,
      );
    });
  });

  group('NotificationDeepLinkCoordinator.open', () {
    testWidgets('queues until shell ready then goes to work order detail',
        (tester) async {
      await pumpRouter(tester);

      const intent = NotificationNavigationIntent(
        route: '/work-orders/wo-42',
        notificationId: 'n1',
        idempotencyKey: 'n1|/work-orders/wo-42|wo-42',
        userId: 'user-1',
      );

      await coordinator.open(
        intent: intent,
        user: null,
        config: null,
        source: 'test',
      );
      expect(coordinator.isShellReady, isFalse);
      expect(find.text('wo:wo-42'), findsNothing);

      coordinator.notifyShellReady();
      await tester.pumpAndSettle();

      expect(find.text('wo:wo-42'), findsOneWidget);
      expect(router.state.uri.path, '/work-orders/wo-42');
    });

    testWidgets('skips inbox fallback route (missing entity id)', (tester) async {
      await pumpRouter(tester);
      coordinator.notifyShellReady();
      await coordinator.open(
        intent: const NotificationNavigationIntent(
          route: RoutePaths.notifications,
          userId: 'user-1',
        ),
        user: null,
        config: null,
        source: 'test',
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, RoutePaths.dashboard);
    });

    testWidgets('repeated open with same idempotency key does not re-go',
        (tester) async {
      await pumpRouter(tester);
      coordinator.notifyShellReady();
      const intent = NotificationNavigationIntent(
        route: '/work-orders/wo-7',
        notificationId: 'n7',
        idempotencyKey: 'n7|/work-orders/wo-7|wo-7',
        userId: 'user-1',
      );

      await coordinator.open(
        intent: intent,
        user: null,
        config: null,
        source: 'first',
      );
      await tester.pumpAndSettle();
      expect(find.text('wo:wo-7'), findsOneWidget);

      router.go(RoutePaths.dashboard);
      await tester.pumpAndSettle();
      await coordinator.open(
        intent: intent,
        user: null,
        config: null,
        source: 'second',
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, RoutePaths.dashboard);
      expect(find.text('wo:wo-7'), findsNothing);
    });

    testWidgets('opens overtime and settings destinations', (tester) async {
      await pumpRouter(tester);
      coordinator.notifyShellReady();

      await coordinator.open(
        intent: const NotificationNavigationIntent(
          route: '/overtime/admin/ot-9',
          notificationId: 'n-ot',
          idempotencyKey: 'n-ot|/overtime/admin/ot-9|ot-9',
          userId: 'user-1',
        ),
        user: null,
        config: null,
        source: 'ot',
      );
      await tester.pumpAndSettle();
      expect(find.text('ot:ot-9'), findsOneWidget);

      await coordinator.open(
        intent: const NotificationNavigationIntent(
          route: RoutePaths.settingsUpdates,
          notificationId: 'n-up',
          idempotencyKey: 'n-up|/settings/updates',
          userId: 'user-1',
        ),
        user: null,
        config: null,
        source: 'update',
      );
      await tester.pumpAndSettle();
      expect(find.text('updates'), findsOneWidget);
    });
  });

  group('cold start', () {
    testWidgets('consumeColdStartRoute returns pending work order route',
        (tester) async {
      await pumpRouter(tester);
      await pending.persist(
        const NotificationNavigationIntent(
          route: '/work-orders/cold-1',
          notificationId: 'nc',
          idempotencyKey: 'nc|/work-orders/cold-1|cold-1',
          userId: 'user-1',
        ),
      );

      final route = await coordinator.consumeColdStartRoute(
        userId: 'user-1',
        user: null,
        config: null,
      );
      expect(route, '/work-orders/cold-1');
      expect(pending.read(), isNull);
    });

    testWidgets('flushAfterAuthentication waits for bootstrap then shell',
        (tester) async {
      await pumpRouter(tester);
      await pending.persist(
        const NotificationNavigationIntent(
          route: '/work-orders/after-auth',
          notificationId: 'na',
          idempotencyKey: 'na|/work-orders/after-auth|after-auth',
          userId: 'user-1',
        ),
      );

      final flushFuture = coordinator.flushAfterAuthentication(
        userId: 'user-1',
        user: null,
        config: null,
      );

      await tester.pump(const Duration(milliseconds: 10));
      expect(find.text('wo:after-auth'), findsNothing);

      coordinator.markBootstrapNavigationSettled();
      coordinator.notifyShellReady();
      await flushFuture;
      await tester.pumpAndSettle();

      expect(find.text('wo:after-auth'), findsOneWidget);
    });
  });

  group('resolveNotificationNavigation + coordinator branch', () {
    test('work order payload resolves to detail with preserved id', () {
      final intent = resolveNotificationNavigation({
        'type': 'work_order',
        'workOrderId': '64f0aaaaaaaaaaaaaaaaaaaa',
        'entityId': '64f0aaaaaaaaaaaaaaaaaaaa',
        'event': 'assigned',
        'notificationId': 'n1',
      });
      expect(intent.route, '/work-orders/64f0aaaaaaaaaaaaaaaaaaaa');
      expect(
        NotificationDeepLinkCoordinator.shellBranchForRoute(intent.route),
        TechnicianInterfaceNavigation.branchWorkOrders,
      );
    });
  });
}
