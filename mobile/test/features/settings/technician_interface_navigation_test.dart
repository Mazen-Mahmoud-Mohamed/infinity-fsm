import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/services/technician_home_navigation.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_navigation.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_notification_policy.dart';

void main() {
  group('TechnicianInterfaceNavigation', () {
    test('all enabled keeps three phone branches in order', () {
      const config = TechnicianInterfaceConfig.defaults;
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config),
        [
          TechnicianInterfaceNavigation.branchWorkOrders,
          TechnicianInterfaceNavigation.branchOvertime,
          TechnicianInterfaceNavigation.branchProfile,
        ],
      );
    });

    test('only overtime enabled', () {
      const config = TechnicianInterfaceConfig(
        overtime: true,
        workOrders: false,
        profile: false,
      );
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config),
        [TechnicianInterfaceNavigation.branchOvertime],
      );
      expect(
        resolveTechnicianHomeRoute(config),
        RoutePaths.overtime,
      );
    });

    test('only work orders enabled', () {
      const config = TechnicianInterfaceConfig(
        overtime: false,
        workOrders: true,
        profile: false,
      );
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config),
        [TechnicianInterfaceNavigation.branchWorkOrders],
      );
      expect(
        resolveTechnicianHomeRoute(config),
        RoutePaths.workOrders,
      );
    });

    test('only profile enabled', () {
      const config = TechnicianInterfaceConfig(
        overtime: false,
        workOrders: false,
        profile: true,
      );
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config),
        [TechnicianInterfaceNavigation.branchProfile],
      );
      expect(
        resolveTechnicianHomeRoute(config),
        RoutePaths.profile,
      );
    });

    test('overtime + work orders enabled preserves order', () {
      const config = TechnicianInterfaceConfig(
        overtime: true,
        workOrders: true,
        profile: false,
      );
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config),
        [
          TechnicianInterfaceNavigation.branchWorkOrders,
          TechnicianInterfaceNavigation.branchOvertime,
        ],
      );
    });

    test('overtime + profile enabled preserves order', () {
      const config = TechnicianInterfaceConfig(
        overtime: true,
        workOrders: false,
        profile: true,
      );
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config),
        [
          TechnicianInterfaceNavigation.branchOvertime,
          TechnicianInterfaceNavigation.branchProfile,
        ],
      );
    });

    test('two enabled / one disabled', () {
      const config = TechnicianInterfaceConfig(
        overtime: true,
        workOrders: true,
        profile: false,
      );
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config).length,
        2,
      );
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config),
        isNot(contains(TechnicianInterfaceNavigation.branchProfile)),
      );
    });

    test('all disabled routes to no-sections screen', () {
      const config = TechnicianInterfaceConfig(
        overtime: false,
        workOrders: false,
        profile: false,
      );
      expect(config.hasAnyEnabled, isFalse);
      expect(
        resolveTechnicianHomeRoute(config),
        RoutePaths.technicianNoSections,
      );
    });

    test('redirect blocks disabled direct routes', () {
      const config = TechnicianInterfaceConfig(
        overtime: false,
        workOrders: true,
        profile: false,
      );

      expect(
        redirectOperationalRoute(
          location: RoutePaths.overtime,
          config: config,
        ),
        RoutePaths.workOrders,
      );
      expect(
        redirectOperationalRoute(
          location: RoutePaths.workOrders,
          config: config,
        ),
        isNull,
      );
    });

    test('redirect sends all-disabled users to no-sections page', () {
      const config = TechnicianInterfaceConfig(
        overtime: false,
        workOrders: false,
        profile: false,
      );

      expect(
        redirectOperationalRoute(
          location: RoutePaths.workOrders,
          config: config,
        ),
        RoutePaths.technicianNoSections,
      );
    });

    test('sub-routes inherit section access rules', () {
      const config = TechnicianInterfaceConfig(
        overtime: false,
        workOrders: true,
        profile: false,
      );

      expect(
        TechnicianInterfaceNavigation.isRouteEnabled(
          config,
          RoutePaths.overtimeHistory,
        ),
        isFalse,
      );
      expect(
        TechnicianInterfaceNavigation.isRouteEnabled(
          config,
          '${RoutePaths.workOrders}/abc',
        ),
        isTrue,
      );
    });
  });

  group('orientation-independent shell authorization', () {
    const config = TechnicianInterfaceConfig.defaults;

    test('technician phone and rail expose the same destinations', () {
      final phone = TechnicianInterfaceNavigation.visiblePhoneBranches(
        operational: true,
        config: config,
      );
      final rail = TechnicianInterfaceNavigation.visibleRailBranches(
        operational: true,
        config: config,
      );
      expect(phone, rail);
      expect(
        phone,
        isNot(contains(TechnicianInterfaceNavigation.branchInventory)),
      );
      expect(
        phone,
        isNot(contains(TechnicianInterfaceNavigation.branchAssets)),
      );
      expect(phone, isNot(contains(TechnicianInterfaceNavigation.branchPm)));
      expect(phone, isNot(contains(TechnicianInterfaceNavigation.branchUsers)));
      expect(phone, isNot(contains(TechnicianInterfaceNavigation.branchRoles)));
      expect(
        phone,
        isNot(contains(TechnicianInterfaceNavigation.branchSettings)),
      );
      expect(
        phone,
        isNot(contains(TechnicianInterfaceNavigation.branchReports)),
      );
      expect(
        phone,
        isNot(contains(TechnicianInterfaceNavigation.branchDashboard)),
      );
    });

    test('technician TI filter still applies on rail', () {
      const limited = TechnicianInterfaceConfig(
        workOrders: true,
        overtime: false,
        profile: true,
      );
      expect(
        TechnicianInterfaceNavigation.visibleRailBranches(
          operational: true,
          config: limited,
        ),
        [
          TechnicianInterfaceNavigation.branchWorkOrders,
          TechnicianInterfaceNavigation.branchProfile,
        ],
      );
      expect(
        TechnicianInterfaceNavigation.visiblePhoneBranches(
          operational: true,
          config: limited,
        ),
        TechnicianInterfaceNavigation.visibleRailBranches(
          operational: true,
          config: limited,
        ),
      );
    });

    test('management rail keeps inventory/assets/pm and admin destinations', () {
      final rail = TechnicianInterfaceNavigation.visibleRailBranches(
        operational: false,
        config: config,
      );
      expect(rail, contains(TechnicianInterfaceNavigation.branchInventory));
      expect(rail, contains(TechnicianInterfaceNavigation.branchAssets));
      expect(rail, contains(TechnicianInterfaceNavigation.branchPm));
      expect(rail, contains(TechnicianInterfaceNavigation.branchUsers));
      expect(rail, contains(TechnicianInterfaceNavigation.branchRoles));
      expect(rail, contains(TechnicianInterfaceNavigation.branchSettings));
      expect(rail, contains(TechnicianInterfaceNavigation.branchReports));
    });

    test('management phone stays compact without management modules', () {
      final phone = TechnicianInterfaceNavigation.visiblePhoneBranches(
        operational: false,
        config: config,
      );
      expect(phone, TechnicianInterfaceNavigation.managementPhoneOrder);
      expect(phone, isNot(contains(TechnicianInterfaceNavigation.branchInventory)));
    });

    test('direct management routes are blocked for technicians', () {
      expect(
        redirectOperationalRoute(
          location: RoutePaths.inventory,
          config: config,
        ),
        RoutePaths.workOrders,
      );
      expect(
        redirectOperationalRoute(
          location: RoutePaths.assets,
          config: config,
        ),
        RoutePaths.workOrders,
      );
      expect(
        redirectOperationalRoute(
          location: RoutePaths.pm,
          config: config,
        ),
        RoutePaths.workOrders,
      );
      expect(
        redirectOperationalRoute(
          location: RoutePaths.users,
          config: config,
        ),
        RoutePaths.workOrders,
      );
      expect(
        redirectOperationalRoute(
          location: RoutePaths.roles,
          config: config,
        ),
        RoutePaths.workOrders,
      );
      expect(
        redirectOperationalRoute(
          location: RoutePaths.settings,
          config: config,
        ),
        RoutePaths.workOrders,
      );
      expect(
        redirectOperationalRoute(
          location: RoutePaths.reports,
          config: config,
        ),
        RoutePaths.workOrders,
      );
    });

    test('personal allowlist remains reachable for technicians', () {
      expect(
        TechnicianInterfaceNavigation.isRouteEnabled(
          config,
          RoutePaths.notifications,
        ),
        isTrue,
      );
      expect(
        TechnicianInterfaceNavigation.isRouteEnabled(
          config,
          RoutePaths.settingsUpdates,
        ),
        isTrue,
      );
      expect(
        TechnicianInterfaceNavigation.isRouteEnabled(
          config,
          RoutePaths.usersChangePassword,
        ),
        isTrue,
      );
      expect(
        redirectOperationalRoute(
          location: RoutePaths.notifications,
          config: config,
        ),
        isNull,
      );
      expect(
        redirectOperationalRoute(
          location: RoutePaths.settingsUpdates,
          config: config,
        ),
        isNull,
      );
    });

    test('notification deep links cannot open inventory for technicians', () {
      const technician = CurrentUser(
        id: 't1',
        companyId: 'c1',
        email: 't@x.com',
        firstName: 'T',
        lastName: 'Ech',
        fullName: 'T Ech',
        roles: ['TECHNICIAN'],
        permissions: ['overtime:view_own', 'work_orders:view_own'],
      );
      expect(
        TechnicianInterfaceNotificationPolicy.canNavigateToResolvedRoute(
          user: technician,
          config: config,
          route: RoutePaths.inventory,
        ),
        isFalse,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.canNavigateToResolvedRoute(
          user: technician,
          config: config,
          route: RoutePaths.assets,
        ),
        isFalse,
      );
      expect(
        TechnicianInterfaceNotificationPolicy.canNavigateToResolvedRoute(
          user: technician,
          config: config,
          route: RoutePaths.settingsUpdates,
        ),
        isTrue,
      );
    });
  });
}
