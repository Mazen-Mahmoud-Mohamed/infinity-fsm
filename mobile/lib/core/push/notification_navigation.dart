import 'package:mobile/core/router/route_paths.dart';

/// Normalized navigation intent extracted from FCM / Socket / local payloads.
class NotificationNavigationIntent {
  const NotificationNavigationIntent({
    required this.route,
    this.notificationId,
    this.idempotencyKey,
    this.userId,
  });

  final String route;
  final String? notificationId;
  final String? idempotencyKey;

  /// Authenticated user (or FCM `recipientUserId`) this deep link belongs to.
  final String? userId;

  NotificationNavigationIntent copyWith({String? userId}) {
    return NotificationNavigationIntent(
      route: route,
      notificationId: notificationId,
      idempotencyKey: idempotencyKey,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() => {
        'route': route,
        if (notificationId != null && notificationId!.isNotEmpty)
          'notificationId': notificationId,
        if (idempotencyKey != null && idempotencyKey!.isNotEmpty)
          'idempotencyKey': idempotencyKey,
        if (userId != null && userId!.isNotEmpty) 'userId': userId,
      };

  static NotificationNavigationIntent? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final route = json['route']?.toString() ?? '';
    if (route.isEmpty) return null;
    final userId = json['userId']?.toString().trim() ?? '';
    return NotificationNavigationIntent(
      route: route,
      notificationId: json['notificationId']?.toString(),
      idempotencyKey: json['idempotencyKey']?.toString(),
      userId: userId.isEmpty ? null : userId,
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
          data['category'] ??
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

/// Maps a Socket.IO `notification:new` payload into the navigation map used
/// for local toasts and pending-intent ownership.
///
/// `recipientUserId` is taken only from the top-level server field. Nested
/// `data.recipientUserId` is ignored so it cannot hijack pending navigation.
Map<String, dynamic> socketPayloadForNavigation(Map<String, dynamic> data) {
  final nested = data['data'] is Map
      ? Map<String, dynamic>.from(data['data'] as Map)
      : <String, dynamic>{};
  nested.remove('recipientUserId');
  final recipient = data['recipientUserId']?.toString().trim() ?? '';
  return <String, dynamic>{
    'notificationId': data['id']?.toString() ?? '',
    'type': data['entityType'] ?? data['type'] ?? data['module'] ?? '',
    'entityId': data['entityId']?.toString() ?? '',
    'workOrderId': nested['workOrderId']?.toString() ??
        data['workOrderId']?.toString() ??
        '',
    'overtimeId': nested['overtimeId']?.toString() ??
        data['overtimeId']?.toString() ??
        '',
    'event': nested['event']?.toString() ?? data['type']?.toString() ?? '',
    'version': nested['version']?.toString() ?? data['version']?.toString() ?? '',
    'build': nested['build']?.toString() ?? data['build']?.toString() ?? '',
    'channel':
        nested['channel']?.toString() ?? data['channel']?.toString() ?? '',
    'route': nested['route']?.toString() ?? data['route']?.toString() ?? '',
    ...nested,
    if (recipient.isNotEmpty) 'recipientUserId': recipient,
  };
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
