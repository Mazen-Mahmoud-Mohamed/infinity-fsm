import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';

/// Maps shell branch indexes to technician interface sections and shared
/// orientation-independent shell visibility.
///
/// Navigation visibility and route access use the same rules: orientation may
/// change presentation (bottom bar vs rail vs sidebar) but never authorization.
class TechnicianInterfaceNavigation {
  TechnicianInterfaceNavigation._();

  static const int branchDashboard = 0;
  static const int branchWorkOrders = 1;
  static const int branchOvertime = 2;
  static const int branchProfile = 3;
  static const int branchInventory = 4;
  static const int branchAssets = 5;
  static const int branchPm = 6;
  static const int branchReports = 7;
  static const int branchUsers = 8;
  static const int branchRoles = 9;
  static const int branchSettings = 10;

  /// Technician phone / rail / sidebar order (operational home first).
  static const List<int> technicianPhoneOrder = [
    branchWorkOrders,
    branchOvertime,
    branchProfile,
  ];

  /// Management phone bottom bar: Dashboard → WO → OT → Profile.
  static const List<int> managementPhoneOrder = [
    branchDashboard,
    branchWorkOrders,
    branchOvertime,
    branchProfile,
  ];

  /// Full management rail / desktop sidebar order.
  static const List<int> managementShellOrder = [
    branchDashboard,
    branchWorkOrders,
    branchOvertime,
    branchProfile,
    branchInventory,
    branchAssets,
    branchPm,
    branchReports,
    branchUsers,
    branchRoles,
    branchSettings,
  ];

  static bool isSectionEnabled(
    TechnicianInterfaceConfig config,
    int branchIndex,
  ) {
    return switch (branchIndex) {
      branchWorkOrders => config.workOrders,
      branchOvertime => config.overtime,
      branchProfile => config.profile,
      _ => false,
    };
  }

  static List<int> filteredPhoneBranches(TechnicianInterfaceConfig config) {
    return technicianPhoneOrder
        .where((branch) => isSectionEnabled(config, branch))
        .toList(growable: false);
  }

  /// Phone bottom-nav destinations (orientation-independent auth).
  static List<int> visiblePhoneBranches({
    required bool operational,
    required TechnicianInterfaceConfig config,
  }) {
    if (operational) {
      return filteredPhoneBranches(config);
    }
    return managementPhoneOrder;
  }

  /// Rail / desktop sidebar destinations (same auth as phone for technicians).
  static List<int> visibleRailBranches({
    required bool operational,
    required TechnicianInterfaceConfig config,
  }) {
    if (operational) {
      return filteredPhoneBranches(config);
    }
    return managementShellOrder;
  }

  static int? firstEnabledBranch(TechnicianInterfaceConfig config) {
    final branches = filteredPhoneBranches(config);
    return branches.isEmpty ? null : branches.first;
  }

  static String? routeForBranch(int branchIndex) {
    return switch (branchIndex) {
      branchWorkOrders => RoutePaths.workOrders,
      branchOvertime => RoutePaths.overtime,
      branchProfile => RoutePaths.profile,
      _ => null,
    };
  }

  static String? firstEnabledRoute(TechnicianInterfaceConfig config) {
    final branch = firstEnabledBranch(config);
    if (branch == null) return null;
    return routeForBranch(branch);
  }

  /// Whether an operational (technician) user may access [location].
  ///
  /// Management shell destinations (inventory, assets, PM, users, roles,
  /// reports, dashboard) are denied. Personal settings remain allowed — the
  /// technician Settings control lives in [TechnicianMainAppBar], not the
  /// management shell branch.
  static bool isRouteEnabled(
    TechnicianInterfaceConfig config,
    String location,
  ) {
    if (location == RoutePaths.technicianNoSections) {
      return true;
    }
    if (location.startsWith(RoutePaths.notifications)) {
      return true;
    }
    if (location.startsWith(RoutePaths.settings) ||
        location.startsWith('/settings')) {
      return true;
    }
    if (location.startsWith(RoutePaths.usersChangePassword)) {
      return true;
    }
    if (location.startsWith(RoutePaths.workOrders) ||
        location.startsWith('/work-orders')) {
      return config.workOrders;
    }
    if (location.startsWith(RoutePaths.overtime) ||
        location.startsWith('/overtime')) {
      return config.overtime;
    }
    if (location.startsWith(RoutePaths.profile) ||
        location.startsWith('/profile')) {
      return config.profile;
    }
    return false;
  }
}
