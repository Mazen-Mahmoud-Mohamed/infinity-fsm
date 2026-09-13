import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/push/notification_deep_link_coordinator.dart';
import 'package:mobile/core/push/notification_navigation.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:mobile/features/notifications/presentation/utils/notification_inbox_visibility.dart';
import 'package:mobile/features/notifications/presentation/widgets/notifications_desktop_view.dart';
import 'package:mobile/features/notifications/presentation/widgets/notification_list_tile.dart';
import 'package:mobile/features/notifications/presentation/widgets/notifications_skeleton.dart';
import 'package:mobile/features/settings/presentation/cubit/technician_interface_cubits.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.cubit});

  /// Optional override for tests; production uses the injected singleton.
  final NotificationsCubit? cubit;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsCubit _cubit;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? (getIt<NotificationsCubit>()..load());
    if (widget.cubit != null &&
        widget.cubit!.state.status == NotificationsStatus.initial) {
      _cubit.load();
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final pagePadding = AppBreakpoints.pagePadding(width);
    final isDesktop = AppBreakpoints.isDesktop(width);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: isDesktop
            ? null
            : AppBar(
                key: const Key('notifications-mobile-app-bar'),
                title: Text(l10n.notifications),
                actions: [
                  BlocBuilder<NotificationsUnreadCubit,
                      NotificationsUnreadState>(
                    buildWhen: (previous, current) =>
                        previous.count != current.count,
                    builder: (context, unread) {
                      if (unread.count <= 0) {
                        return const SizedBox.shrink();
                      }
                      return TextButton(
                        onPressed: () => context
                            .read<NotificationsCubit>()
                            .markAllAsRead(),
                        child: Text(l10n.notificationsMarkAllRead),
                      );
                    },
                  ),
                ],
              ),
        body: AppBreakpoints.isDesktopOf(context)
            ? NotificationsDesktopView(
                searchController: _searchController,
                scrollController: _scrollController,
              )
            : BlocBuilder<TechnicianInterfaceCubit, TechnicianInterfaceState>(
                buildWhen: (previous, current) =>
                    previous.config != current.config ||
                    previous.status != current.status,
                builder: (context, interfaceState) {
                  final user = context.watch<AuthCubit>().state.user;
                  final tiConfig = interfaceState.isReady
                      ? interfaceState.config
                      : null;
                  return BlocBuilder<NotificationsCubit, NotificationsState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.items != current.items ||
              previous.category != current.category ||
              previous.searchQuery != current.searchQuery ||
              previous.isRefreshing != current.isRefreshing ||
              previous.isLoadingMore != current.isLoadingMore ||
              previous.hasMore != current.hasMore ||
              previous.message != current.message ||
              previous.showSearchLoadMore != current.showSearchLoadMore,
          builder: (context, state) {
            final Widget body;
            if ((state.status == NotificationsStatus.loading ||
                    state.status == NotificationsStatus.initial) &&
                state.items.isEmpty) {
              body = NotificationsSkeleton(
                key: const ValueKey('notifications-skeleton'),
                semanticsLabel: l10n.notificationsLoading,
              );
            } else if (state.status == NotificationsStatus.failure &&
                state.items.isEmpty) {
              body = Center(
                key: const ValueKey('notifications-error'),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message != null
                            ? localizeAppMessage(l10n, state.message)
                            : l10n.notificationsLoadFailed,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: () =>
                            context.read<NotificationsCubit>().load(),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              final displayItems = state.visibleItems
                  .where(
                    (item) => isVisibleInboxNotification(
                      notification: item,
                      user: user,
                      config: tiConfig,
                    ),
                  )
                  .toList(growable: false);
              final categories = <NotificationCategory>{
                NotificationCategory.all,
                ...displayItems.map((e) => e.category),
              }.toList()
                ..sort((a, b) => a.index.compareTo(b.index));

              body = Column(
                key: const ValueKey('notifications-content'),
                children: [
                  AppRefreshBar(visible: state.isRefreshing),
                  Expanded(
                    child: AppPageFrame(
                      padding: EdgeInsets.symmetric(horizontal: pagePadding),
                      child: RefreshIndicator(
                        onRefresh: () =>
                            context.read<NotificationsCubit>().load(),
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                  top: AppBreakpoints.isPhone(width)
                                      ? AppSpacing.sm
                                      : AppSpacing.md,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: l10n.notificationsSearchHint,
                                        prefixIcon: const Icon(Icons.search),
                                        border: const OutlineInputBorder(),
                                        suffixIcon: state.searchQuery.isEmpty
                                            ? null
                                            : IconButton(
                                                tooltip:
                                                    MaterialLocalizations.of(
                                                  context,
                                                ).deleteButtonTooltip,
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  context
                                                      .read<
                                                          NotificationsCubit>()
                                                      .setSearchQuery('');
                                                },
                                              ),
                                      ),
                                      onChanged: (value) => context
                                          .read<NotificationsCubit>()
                                          .setSearchQuery(value),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          for (final category in categories)
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .only(
                                                end: AppSpacing.sm,
                                              ),
                                              child: FilterChip(
                                                label: Text(
                                                  notificationCategoryLabel(
                                                    l10n,
                                                    category,
                                                  ),
                                                ),
                                                selected:
                                                    state.category == category,
                                                onSelected: (_) => context
                                                    .read<NotificationsCubit>()
                                                    .setCategory(category),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    BlocBuilder<NotificationsUnreadCubit,
                                        NotificationsUnreadState>(
                                      buildWhen: (previous, current) =>
                                          previous.count != current.count,
                                      builder: (context, unread) {
                                        if (unread.count <= 0) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: AppSpacing.sm,
                                          ),
                                          child: Text(
                                            l10n.notificationsUnreadCount(
                                              unread.count,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (state.items.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  l10n.notificationsEmpty,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else if (state.showSearchLoadMore)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: NotificationsSearchLoadMorePanel(
                                isLoadingMore: state.isLoadingMore,
                                onLoadMore: () => context
                                    .read<NotificationsCubit>()
                                    .loadMore(),
                              ),
                            )
                          else if (displayItems.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  l10n.notificationsSearchEmpty,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: AppScrollPadding.resolve(
                                context,
                                base: EdgeInsets.zero,
                                chrome: AppBottomChrome.system,
                              ),
                              sliver: SliverList.separated(
                                itemCount: displayItems.length +
                                    (state.isLoadingMore ? 1 : 0),
                                separatorBuilder: (_, index) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  if (index >= displayItems.length) {
                                    return const NotificationsLoadMoreIndicator();
                                  }
                                  if (index == displayItems.length - 1 &&
                                      state.hasMore &&
                                      !state.isLoadingMore) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted) {
                                        context
                                            .read<NotificationsCubit>()
                                            .loadMore();
                                      }
                                    });
                                  }
                                  final item = displayItems[index];
                                  return NotificationListTile(
                                    notification: item,
                                    onTap: () {
                                      context
                                          .read<NotificationsCubit>()
                                          .markAsRead(item.id);
                                      _openNotificationTarget(context, item);
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: body,
            );
          },
        );
                },
              ),
      ),
    );
  }

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
    final user = context.read<AuthCubit>().state.user;
    final interfaceState = context.read<TechnicianInterfaceCubit>().state;
    final config = interfaceState.isReady ? interfaceState.config : null;
    unawaited(
      getIt<NotificationDeepLinkCoordinator>().open(
        intent: intent.copyWith(userId: user?.id),
        user: user,
        config: config,
        source: 'inbox_tap',
      ),
    );
  }
}
