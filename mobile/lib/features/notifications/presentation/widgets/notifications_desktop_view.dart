import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_audit_event.dart';
import 'package:mobile/core/push/notification_navigation.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_page_header.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_surface.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_toolbar.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:mobile/features/notifications/presentation/widgets/notification_list_tile.dart';

/// Desktop notification center with list + detail preview panel.
class NotificationsDesktopView extends StatefulWidget {
  const NotificationsDesktopView({
    super.key,
    required this.searchController,
  });

  final TextEditingController searchController;

  @override
  State<NotificationsDesktopView> createState() =>
      _NotificationsDesktopViewState();
}

class _NotificationsDesktopViewState extends State<NotificationsDesktopView> {
  String? _selectedId;

  void _openNotificationTarget(BuildContext context, AppNotification item) {
    final intent = resolveNotificationNavigation({
      'type': item.entityType ?? item.module,
      'entityId': item.entityId,
      'workOrderId': item.data['workOrderId'],
      'overtimeId': item.data['overtimeId'],
      'notificationId': item.id,
      ...item.data,
    });
    if (intent.route == RoutePaths.notifications) {
      return;
    }
    context.push(intent.route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        if (state.status == NotificationsStatus.loading &&
            state.items.isEmpty) {
          return AppLoader(message: l10n.notificationsLoading);
        }

        final displayItems = state.visibleItems
            .where(shouldShowUserNotification)
            .toList(growable: false);
        final categories = <NotificationCategory>{
          NotificationCategory.all,
          ...displayItems.map((e) => e.category),
        }.toList()
          ..sort((a, b) => a.index.compareTo(b.index));

        AppNotification? selected;
        if (_selectedId != null) {
          for (final item in displayItems) {
            if (item.id == _selectedId) {
              selected = item;
              break;
            }
          }
        }
        selected ??= displayItems.isEmpty ? null : displayItems.first;
        if (selected != null && _selectedId == null) {
          _selectedId = selected.id;
        }

        return Column(
          children: [
            AppRefreshBar(visible: state.isRefreshing),
            AppDesktopWorkspacePadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDesktopPageHeader(
                    title: l10n.notifications,
                    trailing: state.hasUnread
                        ? TextButton(
                            onPressed: () => context
                                .read<NotificationsCubit>()
                                .markAllAsRead(),
                            child: Text(l10n.notificationsMarkAllRead),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDesktopToolbar(
                    search: TextField(
                      controller: widget.searchController,
                      decoration: InputDecoration(
                        hintText: l10n.notificationsSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        suffixIcon: state.searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  widget.searchController.clear();
                                  context
                                      .read<NotificationsCubit>()
                                      .setSearchQuery('');
                                },
                              ),
                      ),
                      onChanged: (value) => context
                          .read<NotificationsCubit>()
                          .setSearchQuery(value),
                    ),
                    filters: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final category in categories)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: AppSpacing.sm,
                              ),
                              child: FilterChip(
                                label: Text(
                                  notificationCategoryLabel(l10n, category),
                                ),
                                selected: state.category == category,
                                onSelected: (_) => context
                                    .read<NotificationsCubit>()
                                    .setCategory(category),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AppPageFrame(
                maxWidth: AppBreakpoints.contentWideMax,
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<NotificationsCubit>().load(),
                  child: displayItems.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.4,
                              child: Center(
                                child: Text(
                                  state.items.isEmpty
                                      ? l10n.notificationsEmpty
                                      : l10n.notificationsSearchEmpty,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 2,
                                child: AppDesktopSurface(
                                  child: ListView.separated(
                                    itemCount: displayItems.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withValues(alpha: 0.4),
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = displayItems[index];
                                      final isSelected =
                                          item.id == selected?.id;
                                      return Material(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primaryContainer
                                                .withValues(alpha: 0.35)
                                            : Colors.transparent,
                                        child: NotificationListTile(
                                          notification: item,
                                          onTap: () {
                                            setState(
                                              () => _selectedId = item.id,
                                            );
                                            context
                                                .read<NotificationsCubit>()
                                                .markAsRead(item.id);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                flex: 3,
                                child: _NotificationDetailPanel(
                                  notification: selected,
                                  onOpen: selected == null
                                      ? null
                                      : () =>
                                          _openNotificationTarget(
                                            context,
                                            selected!,
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationDetailPanel extends StatelessWidget {
  const _NotificationDetailPanel({
    required this.notification,
    this.onOpen,
  });

  final AppNotification? notification;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final item = notification;

    if (item == null) {
      return AppDesktopSurface(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            l10n.notificationsEmpty,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final dateFormat = AppFormatters.mediumDateTime(context);

    return AppDesktopSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                notificationCategoryIcon(item.category),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  notificationCategoryLabel(l10n, item.category),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (!item.isRead)
                Chip(
                  label: Text(l10n.notificationsUnreadCount(1)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.createdAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              dateFormat.format(item.createdAt!.toLocal()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (item.actorName != null && item.actorName!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.actorName!,
              style: theme.textTheme.titleSmall,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                item.body,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          if (onOpen != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.overtimeExportOpen),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
