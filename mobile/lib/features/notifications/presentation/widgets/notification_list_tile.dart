import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_audit_event.dart';
import 'package:mobile/core/localization/localize_rbac.dart';
import 'package:mobile/core/widgets/app_list_card.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';

String notificationCategoryLabel(
  AppLocalizations l10n,
  NotificationCategory category,
) {
  switch (category) {
    case NotificationCategory.all:
      return l10n.notificationsFilterAll;
    case NotificationCategory.attendance:
      return l10n.attendance;
    case NotificationCategory.overtime:
      return l10n.overtime;
    case NotificationCategory.workOrders:
      return l10n.workOrders;
    case NotificationCategory.inventory:
      return l10n.inventory;
    case NotificationCategory.assets:
      return l10n.assets;
    case NotificationCategory.maintenance:
      return l10n.permGroupMaintenance;
    case NotificationCategory.reports:
      return l10n.permGroupServiceReports;
    case NotificationCategory.users:
      return l10n.permGroupUsers;
    case NotificationCategory.roles:
      return l10n.permGroupRoles;
    case NotificationCategory.settings:
      return l10n.settings;
    case NotificationCategory.general:
      return l10n.notificationsCategoryGeneral;
  }
}

IconData notificationCategoryIcon(NotificationCategory category) {
  switch (category) {
    case NotificationCategory.all:
      return Icons.notifications_outlined;
    case NotificationCategory.attendance:
      return Icons.fingerprint_outlined;
    case NotificationCategory.overtime:
      return Icons.more_time_outlined;
    case NotificationCategory.workOrders:
      return Icons.assignment_outlined;
    case NotificationCategory.inventory:
      return Icons.inventory_2_outlined;
    case NotificationCategory.assets:
      return Icons.devices_other_outlined;
    case NotificationCategory.maintenance:
      return Icons.build_outlined;
    case NotificationCategory.reports:
      return Icons.description_outlined;
    case NotificationCategory.users:
      return Icons.people_outline;
    case NotificationCategory.roles:
      return Icons.admin_panel_settings_outlined;
    case NotificationCategory.settings:
      return Icons.settings_outlined;
    case NotificationCategory.general:
      return Icons.info_outline;
  }
}

class NotificationListTile extends StatelessWidget {
  const NotificationListTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unread = !notification.isRead;
    final createdAt = notification.createdAt;
    // API notifications already carry localized title/body; audit feed keys
    // still pass through localize helpers (unknown keys return unchanged).
    final title = notification.entityType != null
        ? notification.title
        : localizeAuditEvent(l10n, notification.title);
    final body = notification.entityType != null
        ? notification.body
        : localizeNotificationBody(l10n, notification.body);

    return AppListCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: unread
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            foregroundColor:
                unread ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            child: Icon(
              notificationCategoryIcon(notification.category),
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        localizePermissionGroup(l10n, notification.module),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(
                      unread
                          ? l10n.notificationsUnread
                          : l10n.notificationsRead,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        AppFormatters.mediumDateTime(context).format(createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
