import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/services/technician_home_navigation.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_navigation.dart';

void main() {
  group('TechnicianInterfaceNavigation', () {
    test('all enabled keeps four phone branches in order', () {
      const config = TechnicianInterfaceConfig.defaults;
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config),
        [
          TechnicianInterfaceNavigation.branchWorkOrders,
          TechnicianInterfaceNavigation.branchAttendance,
          TechnicianInterfaceNavigation.branchOvertime,
          TechnicianInterfaceNavigation.branchProfile,
        ],
      );
    });

    test('only overtime enabled', () {
      const config = TechnicianInterfaceConfig(
        overtime: true,
        workOrders: false,
        attendance: false,
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
        attendance: false,
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

    test('only attendance enabled', () {
      const config = TechnicianInterfaceConfig(
        overtime: false,
        workOrders: false,
        attendance: true,
        profile: false,
      );
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config),
        [TechnicianInterfaceNavigation.branchAttendance],
      );
      expect(
        resolveTechnicianHomeRoute(config),
        RoutePaths.attendance,
      );
    });

    test('only profile enabled', () {
      const config = TechnicianInterfaceConfig(
        overtime: false,
        workOrders: false,
        attendance: false,
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
        attendance: false,
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

    test('attendance + profile enabled preserves order', () {
      const config = TechnicianInterfaceConfig(
        overtime: false,
        workOrders: false,
        attendance: true,
        profile: true,
      );
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config),
        [
          TechnicianInterfaceNavigation.branchAttendance,
          TechnicianInterfaceNavigation.branchProfile,
        ],
      );
    });

    test('three enabled / one disabled', () {
      const config = TechnicianInterfaceConfig(
        overtime: true,
        workOrders: true,
        attendance: true,
        profile: false,
      );
      expect(
        TechnicianInterfaceNavigation.filteredPhoneBranches(config).length,
        3,
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
        attendance: false,
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
        attendance: false,
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
        attendance: false,
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
        attendance: false,
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
}
