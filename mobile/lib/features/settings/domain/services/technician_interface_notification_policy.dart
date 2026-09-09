import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_navigation.dart';

/// Which Technician Interface section a notification belongs to, if any.
enum TechnicianInterfaceNotificationSection {
  workOrders,
  overtime,
  /// Not gated by Technician Interface (app updates, general, etc.).
  none,
}

/// Central mapping from notification signals → Technician Interface flags.
///
/// Apply only for [CurrentUser.usesOperationalHome]. Management users are
/// never gated. Prefer fail-open when [config] is null (settings not loaded).
class TechnicianInterfaceNotificationPolicy {
  TechnicianInterfaceNotificationPolicy._();

  /// Resolves the TI section for structured payload fields (FCM / Socket / data).
  static TechnicianInterfaceNotificationSection sectionForPayload(
    Map<String, dynamic> data,
  ) {
    final type = _combinedType(data);
    if (_isAppUpdateType(type)) {
      return TechnicianInterfaceNotificationSection.none;
    }
    if (_isWorkOrderType(type)) {
      return TechnicianInterfaceNotificationSection.workOrders;
    }
    if (_isOvertimeType(type)) {
      return TechnicianInterfaceNotificationSection.overtime;
    }
    final route = (data['route'] ?? '').toString();
    return sectionForRoute(route);
  }

  /// Resolves the TI section for an inbox [AppNotification].
  static TechnicianInterfaceNotificationSection sectionForNotification(
    AppNotification notification,
  ) {
    final type = [
      notification.entityType,
      notification.module,
      notification.category.name,
      notification.data['type'],
      notification.data['entityType'],
      notification.data['module'],
      notification.data['event'],
    ].whereType<Object>().map((e) => e.toString().toLowerCase()).join(' ');

    if (_isAppUpdateType(type) ||
        notification.module.toLowerCase().contains('app_update') ||
        notification.entityType?.toLowerCase() == 'app_update') {
      return TechnicianInterfaceNotificationSection.none;
    }
    if (notification.category == NotificationCategory.workOrders ||
        _isWorkOrderType(type)) {
      return TechnicianInterfaceNotificationSection.workOrders;
    }
    if (notification.category == NotificationCategory.overtime ||
        _isOvertimeType(type)) {
      return TechnicianInterfaceNotificationSection.overtime;
    }
    return TechnicianInterfaceNotificationSection.none;
  }

  /// Maps a deep-link route to a TI section (reuse nav path prefixes).
  static TechnicianInterfaceNotificationSection sectionForRoute(String route) {
    if (route.startsWith(RoutePaths.workOrders) ||
        route.startsWith('/work-orders')) {
      return TechnicianInterfaceNotificationSection.workOrders;
    }
    if (route.startsWith(RoutePaths.overtime) || route.startsWith('/overtime')) {
      return TechnicianInterfaceNotificationSection.overtime;
    }
    return TechnicianInterfaceNotificationSection.none;
  }

  /// Whether the section is allowed for [config]. Null config → fail-open.
  static bool isSectionEnabled(
    TechnicianInterfaceConfig? config,
    TechnicianInterfaceNotificationSection section,
  ) {
    if (config == null) return true;
    return switch (section) {
      TechnicianInterfaceNotificationSection.workOrders => config.workOrders,
      TechnicianInterfaceNotificationSection.overtime => config.overtime,
      TechnicianInterfaceNotificationSection.none => true,
    };
  }

  /// Inbox / toast visibility for a user + config.
  ///
  /// Non-operational users always see notifications. Null config fails open.
  static bool isNotificationVisible({
    required CurrentUser? user,
    required TechnicianInterfaceConfig? config,
    required AppNotification notification,
  }) {
    if (user == null || !user.usesOperationalHome) return true;
    return isSectionEnabled(config, sectionForNotification(notification));
  }

  /// Payload toast / deep-link visibility for a user + config.
  static bool isPayloadVisible({
    required CurrentUser? user,
    required TechnicianInterfaceConfig? config,
    required Map<String, dynamic> data,
  }) {
    if (user == null || !user.usesOperationalHome) return true;
    return isSectionEnabled(config, sectionForPayload(data));
  }

  /// Whether navigating to [route] is allowed for a technician.
  ///
  /// Null [config] fails open. Non-operational users are never gated.
  static bool isRouteAllowed({
    required CurrentUser? user,
    required TechnicianInterfaceConfig? config,
    required String route,
  }) {
    if (user == null || !user.usesOperationalHome) return true;
    if (config == null) return true;
    return TechnicianInterfaceNavigation.isRouteEnabled(config, route);
  }

  /// Deep-link guard for resolved navigation routes (presentation / push layer).
  ///
  /// Keeps [resolveNotificationNavigation] pure; call this before `push`.
  static bool canNavigateToResolvedRoute({
    required CurrentUser? user,
    required TechnicianInterfaceConfig? config,
    required String route,
  }) {
    return isRouteAllowed(user: user, config: config, route: route);
  }

  static String _combinedType(Map<String, dynamic> data) {
    return [
      data['type'],
      data['entityType'],
      data['module'],
      data['category'],
      data['event'],
    ].whereType<Object>().map((e) => e.toString().toLowerCase()).join(' ');
  }

  static bool _isWorkOrderType(String type) {
    return type.contains('work_order') ||
        type.contains('work-order') ||
        type.contains('workorders') ||
        RegExp(r'\bwork_orders\b').hasMatch(type);
  }

  static bool _isOvertimeType(String type) {
    return type.contains('overtime');
  }

  static bool _isAppUpdateType(String type) {
    return type.contains('app_update') ||
        type.contains('app-update') ||
        type.trim() == 'update';
  }
}
