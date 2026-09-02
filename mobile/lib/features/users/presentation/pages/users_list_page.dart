import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/localization/localize_rbac.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_empty_state.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_page_layout.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_toolbar.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/presentation/cubit/users_cubits.dart';
import 'package:mobile/features/users/presentation/widgets/user_status_badge.dart';
import 'package:mobile/features/users/presentation/widgets/users_desktop_table.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key, this.initialStatus});

  final ManagedUserStatus? initialStatus;

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  late final UsersListCubit _cubit;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<UsersListCubit>()
      ..loadFirstPage(status: widget.initialStatus);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _cubit.close();
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
    final isDesktop = AppBreakpoints.isDesktopOf(context);
    final canCreate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canCreateUsers() == true,
    );

    Future<void> openCreate() async {
      final changed = await context.push<bool>(RoutePaths.usersForm);
      if (changed == true && mounted) {
        await _cubit.loadFirstPage();
      }
    }

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: isDesktop ? null : AppBar(title: Text(l10n.usersList)),
        floatingActionButton: !isDesktop && canCreate
            ? FloatingActionButton.extended(
                onPressed: openCreate,
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(l10n.usersCreate),
              )
            : null,
        body: Column(
          children: [
            if (isDesktop)
              AppDesktopListPageHeader(
                title: l10n.usersList,
                trailing: canCreate
                    ? FilledButton.icon(
                        onPressed: openCreate,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: Text(l10n.usersCreate),
                      )
                    : null,
                toolbar: AppDesktopToolbar(
                  search: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.usersSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _cubit.search,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.usersSearchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _cubit.search,
                ),
              ),
            BlocBuilder<UsersListCubit, UsersListState>(
              buildWhen: (p, c) => p.filterStatus != c.filterStatus,
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(l10n.usersFilterAll),
                        selected: state.filterStatus == null,
                        onSelected: (_) => _cubit.setFilter(null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...ManagedUserStatus.values.map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text(switch (status) {
                              ManagedUserStatus.active =>
                                l10n.usersStatusActive,
                              ManagedUserStatus.disabled =>
                                l10n.usersStatusDisabled,
                              ManagedUserStatus.locked =>
                                l10n.usersStatusLocked,
                            }),
                            selected: state.filterStatus == status,
                            onSelected: (_) => _cubit.setFilter(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            BlocSelector<UsersListCubit, UsersListState, bool>(
              selector: (state) => state.isRefreshing,
              builder: (context, refreshing) =>
                  AppRefreshBar(visible: refreshing),
            ),
            Expanded(
              child: BlocBuilder<UsersListCubit, UsersListState>(
                builder: (context, state) {
                  if ((state.status == UsersListStatus.loading ||
                          state.status == UsersListStatus.initial) &&
                      state.items.isEmpty) {
                    return AppLoader(message: l10n.usersLoading);
                  }
                  if (state.status == UsersListStatus.failure &&
                      state.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.usersLoadFailed,
                        ),
                          FilledButton(
                            onPressed: () => _cubit.loadFirstPage(),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state.items.isEmpty) {
                    return isDesktop
                        ? AppDesktopEmptyState(
                            icon: Icons.people_outline,
                            title: l10n.usersEmpty,
                          )
                        : Center(child: Text(l10n.usersEmpty));
                  }
                  if (isDesktop) {
                    return RefreshIndicator(
                      onRefresh: () => _cubit.loadFirstPage(),
                      child: UsersDesktopTable(
                        users: state.items,
                        scrollController: _scrollController,
                        loadingMore: state.hasMore,
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => _cubit.loadFirstPage(),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: AppScrollPadding.resolve(
                        context,
                        base: const EdgeInsets.all(AppSpacing.md),
                        chrome: AppBottomChrome.fab,
                      ),
                      itemCount:
                          state.items.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final user = state.items[index];
                        return Card(
                          child: ListTile(
                            leading: AppNetworkAvatar(
                              imageUrl: user.avatarUrl,
                              radius: 20,
                              fallbackLabel: user.fullName,
                            ),
                            title: Text(user.fullName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email),
                                Text(
                                  [
                                    if (user.username != null) user.username!,
                                    if (user.primaryRole != null)
                                      localizeRoleLabel(
                                        l10n,
                                        user.primaryRole,
                                      ),
                                    if (user.jobTitle != null) user.jobTitle!,
                                  ].join(' · '),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                UserStatusBadge(status: user.status),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () async {
                              final changed = await context.push<bool>(
                                RoutePaths.userDetail(user.id),
                              );
                              if (changed == true && mounted) {
                                await _cubit.loadFirstPage();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
