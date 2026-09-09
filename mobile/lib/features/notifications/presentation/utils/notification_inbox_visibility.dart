import 'package:mobile/core/localization/localize_audit_event.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_notification_policy.dart';

/// Shared inbox filter for mobile + desktop notification lists.
bool isVisibleInboxNotification({
  required AppNotification notification,
  required CurrentUser? user,
  required TechnicianInterfaceConfig? config,
}) {
  if (!shouldShowUserNotification(notification)) return false;
  return TechnicianInterfaceNotificationPolicy.isNotificationVisible(
    user: user,
    config: config,
    notification: notification,
  );
}
