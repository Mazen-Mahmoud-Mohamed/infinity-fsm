import 'package:mobile/core/router/route_paths.dart';

/// Normalized navigation intent extracted from FCM / Socket / local payloads.
class NotificationNavigationIntent {
  const NotificationNavigationIntent({
    required this.route,
    this.notificationId,
    this.idempotencyKey,
  });

  final String route;
  final String? notificationId;
  final String? idempotencyKey;

  Map<String, dynamic> toJson() => {
        'route': route,
        if (notificationId != null && notificationId!.isNotEmpty)
          'notificationId': notificationId,
        if (idempotencyKey != null && idempotencyKey!.isNotEmpty)
          'idempotencyKey': idempotencyKey,
      };

  static NotificationNavigationIntent? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final route = json['route']?.toString() ?? '';
    if (route.isEmpty) return null;
    return NotificationNavigationIntent(
      route: route,
      notificationId: json['notificationId']?.toString(),
      idempotencyKey: json['idempotencyKey']?.toString(),
    );
  }
}

/// Resolves a deep-link route from notification data payload fields.
///
/// Visible title/body are ignored — only structured `data` is used.
NotificationNavigationIntent resolveNotificationNavigation(
  Map<String, dynamic> data,
) {
  final type = (data['type'] ??
          data['entityType'] ??
          data['module'] ??
          data['event'] ??
          '')
      .toString()
      .toLowerCase();

  final workOrderId = (data['workOrderId'] ?? '').toString().trim();
  final overtimeId = (data['overtimeId'] ?? '').toString().trim();
  final entityId = (data['entityId'] ?? '').toString().trim();

  final notificationId = (data['notificationId'] ?? data['id'] ?? '')
      .toString()
      .trim();

  String? targetId;
  String route;

  if (_isWorkOrderType(type)) {
    targetId = workOrderId.isNotEmpty
        ? workOrderId
        : (entityId.isNotEmpty ? entityId : null);
    route = targetId == null || targetId.isEmpty
        ? RoutePaths.notifications
        : RoutePaths.workOrderDetail(targetId);
  } else if (_isOvertimeType(type)) {
    targetId =
        overtimeId.isNotEmpty ? overtimeId : (entityId.isNotEmpty ? entityId : null);
    route = targetId == null || targetId.isEmpty
        ? RoutePaths.notifications
        : RoutePaths.overtimeAdminDetail(targetId);
  } else if (_isAppUpdateType(type)) {
    route = RoutePaths.settingsUpdates;
    targetId = null;
  } else if (entityId.isNotEmpty && type.contains('work')) {
    route = RoutePaths.workOrderDetail(entityId);
    targetId = entityId;
  } else {
    route = RoutePaths.notifications;
    targetId = null;
  }

  final idempotencyKey = [
    if (notificationId.isNotEmpty) notificationId,
    route,
    if (targetId != null && targetId.isNotEmpty) targetId,
  ].join('|');

  return NotificationNavigationIntent(
    route: route,
    notificationId: notificationId.isEmpty ? null : notificationId,
    idempotencyKey: idempotencyKey.isEmpty ? null : idempotencyKey,
  );
}

bool _isWorkOrderType(String type) {
  return type.contains('work_order') ||
      type == 'work_orders' ||
      type.contains('work-order');
}

bool _isOvertimeType(String type) {
  return type.contains('overtime');
}

bool _isAppUpdateType(String type) {
  return type.contains('app_update') || type == 'update';
}
