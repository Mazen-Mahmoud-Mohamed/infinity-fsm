import 'package:mobile/features/notifications/domain/entities/app_notification.dart';

/// Builds an [AppNotification] from a Socket.IO `notification:new` payload.
///
/// Returns null when the payload is missing an id or both title and body, so
/// callers can keep the existing unread-refresh path instead of inventing data.
AppNotification? appNotificationFromRealtime(
  Map<String, dynamic> raw, {
  required String localeCode,
}) {
  final id = (raw['id'] ?? raw['notificationId'] ?? '').toString().trim();
  if (id.isEmpty) return null;

  final preferEn = localeCode.toLowerCase().startsWith('en');
  final title = (preferEn
              ? (raw['titleEn'] ?? raw['title'])
              : (raw['titleAr'] ?? raw['title']))
          ?.toString()
          .trim() ??
      '';
  final body = (preferEn
              ? (raw['bodyEn'] ?? raw['body'])
              : (raw['bodyAr'] ?? raw['body']))
          ?.toString()
          .trim() ??
      '';
  if (title.isEmpty && body.isEmpty) return null;

  final nested = raw['data'] is Map
      ? Map<String, dynamic>.from(raw['data'] as Map)
      : <String, dynamic>{};
  final module = (raw['module'] ?? nested['module'] ?? 'general').toString();
  final entityType =
      raw['entityType']?.toString() ?? nested['type']?.toString();
  final entityId = raw['entityId']?.toString() ??
      nested['entityId']?.toString() ??
      nested['workOrderId']?.toString() ??
      nested['overtimeId']?.toString();

  return AppNotification(
    id: id,
    title: title.isEmpty ? body : title,
    body: body,
    category: AppNotification.categoryFromModule(module),
    module: module,
    actorName: raw['actorName'] as String?,
    createdAt: raw['createdAt'] != null
        ? DateTime.tryParse(raw['createdAt'].toString())
        : DateTime.now(),
    isRead: raw['isRead'] == true,
    entityType: entityType,
    entityId: entityId,
    data: nested,
  );
}

String? realtimeRecipientUserId(Map<String, dynamic> raw) {
  final top = raw['recipientUserId']?.toString().trim() ?? '';
  if (top.isNotEmpty) return top;
  return null;
}

List<AppNotification> mergeNotificationsById({
  required List<AppNotification> primary,
  required List<AppNotification> secondary,
}) {
  final seen = <String>{};
  final merged = <AppNotification>[];
  for (final item in [...primary, ...secondary]) {
    if (item.id.isEmpty || seen.contains(item.id)) continue;
    seen.add(item.id);
    merged.add(item);
  }
  return merged;
}
