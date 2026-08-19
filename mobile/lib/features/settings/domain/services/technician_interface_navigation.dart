import 'package:mobile/features/settings/domain/entities/settings_entities.dart';

/// Maps shell branch indexes to technician interface sections.
class TechnicianInterfaceNavigation {
  TechnicianInterfaceNavigation._();

  static const int branchAttendance = 1;
  static const int branchWorkOrders = 2;
  static const int branchOvertime = 3;
  static const int branchProfile = 4;

  /// Technician phone bottom bar order (operational home first).
  static const List<int> technicianPhoneOrder = [
    branchWorkOrders,
    branchAttendance,
    branchOvertime,
    branchProfile,
  ];

  static bool isSectionEnabled(
    TechnicianInterfaceConfig config,
    int branchIndex,
  ) {
    return switch (branchIndex) {
      branchWorkOrders => config.workOrders,
      branchAttendance => config.attendance,
      branchOvertime => config.overtime,
      branchProfile => config.profile,
      _ => true,
    };
  }

  static List<int> filteredPhoneBranches(TechnicianInterfaceConfig config) {
    return technicianPhoneOrder
        .where((branch) => isSectionEnabled(config, branch))
        .toList(growable: false);
  }

  static int? firstEnabledBranch(TechnicianInterfaceConfig config) {
    final branches = filteredPhoneBranches(config);
    return branches.isEmpty ? null : branches.first;
  }

  static String? routeForBranch(int branchIndex) {
    return switch (branchIndex) {
      branchWorkOrders => '/work-orders',
      branchAttendance => '/attendance',
      branchOvertime => '/overtime',
      branchProfile => '/profile',
      _ => null,
    };
  }

  static String? firstEnabledRoute(TechnicianInterfaceConfig config) {
    final branch = firstEnabledBranch(config);
    if (branch == null) return null;
    return routeForBranch(branch);
  }

  static bool isRouteEnabled(
    TechnicianInterfaceConfig config,
    String location,
  ) {
    if (location.startsWith('/work-orders')) {
      return config.workOrders;
    }
    if (location.startsWith('/attendance')) {
      return config.attendance;
    }
    if (location.startsWith('/overtime')) {
      return config.overtime;
    }
    if (location.startsWith('/profile')) {
      return config.profile;
    }
    return true;
  }
}
