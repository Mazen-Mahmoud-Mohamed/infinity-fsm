import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_navigation.dart';

String resolveTechnicianHomeRoute(TechnicianInterfaceConfig config) {
  if (!config.hasAnyEnabled) {
    return RoutePaths.technicianNoSections;
  }
  return TechnicianInterfaceNavigation.firstEnabledRoute(config) ??
      RoutePaths.workOrders;
}

String? redirectOperationalRoute({
  required String location,
  required TechnicianInterfaceConfig config,
}) {
  if (location == RoutePaths.technicianNoSections) {
    if (config.hasAnyEnabled) {
      return resolveTechnicianHomeRoute(config);
    }
    return null;
  }

  if (!config.hasAnyEnabled) {
    return RoutePaths.technicianNoSections;
  }

  if (!TechnicianInterfaceNavigation.isRouteEnabled(config, location)) {
    return resolveTechnicianHomeRoute(config);
  }

  return null;
}
