import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:mobile/features/notifications/presentation/widgets/notification_list_tile.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsCubit _cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<NotificationsCubit>()..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final pagePadding = AppBreakpoints.pagePadding(width);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.notifications),
          actions: [
            BlocBuilder<NotificationsCubit, NotificationsState>(
              buildWhen: (previous, current) =>
                  previous.unreadCount != current.unreadCount,
              builder: (context, state) {
                if (!state.hasUnread) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () =>
                      context.read<NotificationsCubit>().markAllAsRead(),
                  child: Text(l10n.notificationsMarkAllRead),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state.status == NotificationsStatus.loading &&
                state.items.isEmpty) {
              return AppLoader(message: l10n.notificationsLoading);
            }

            if (state.status == NotificationsStatus.failure &&
                state.items.isEmpty) {
              return Center(
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
            }

            final visible = state.visibleItems;
            final categories = <NotificationCategory>{
              NotificationCategory.all,
              ...state.items.map((e) => e.category),
            }.toList()
              ..sort((a, b) => a.index.compareTo(b.index));

            return Column(
              children: [
                AppRefreshBar(visible: state.isRefreshing),
                Expanded(
                  child: AppPageFrame(
                    padding: EdgeInsets.symmetric(horizontal: pagePadding),
                    child: RefreshIndicator(
                      onRefresh: () =>
                          context.read<NotificationsCubit>().load(),
                      child: CustomScrollView(
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                              tooltip: MaterialLocalizations.of(
                                                context,
                                              ).deleteButtonTooltip,
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                _searchController.clear();
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
                                  const SizedBox(height: AppSpacing.md),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        for (final category in categories)
                                          Padding(
                                            padding:
                                                const EdgeInsetsDirectional.only(
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
                                  if (state.unreadCount > 0) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      l10n.notificationsUnreadCount(
                                        state.unreadCount,
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
                                  ],
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
                          else if (visible.isEmpty)
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
                                itemCount: visible.length,
                                separatorBuilder: (_, index) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final item = visible[index];
                                  return NotificationListTile(
                                    notification: item,
                                    onTap: () => context
                                        .read<NotificationsCubit>()
                                        .markAsRead(item.id),
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
          },
        ),
      ),
    );
  }
}
