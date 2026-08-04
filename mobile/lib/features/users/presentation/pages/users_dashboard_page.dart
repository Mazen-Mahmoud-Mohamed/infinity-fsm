import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_action_card.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_stat_grid.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_quick_card.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/presentation/cubit/users_cubits.dart';

class UsersDashboardPage extends StatefulWidget {
  const UsersDashboardPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<UsersDashboardPage> createState() => _UsersDashboardPageState();
}

class _UsersDashboardPageState extends State<UsersDashboardPage> {
  late final UsersDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<UsersDashboardCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: _UsersDashboardView(embedded: widget.embedded),
    );
  }
}

class _UsersDashboardView extends StatelessWidget {
  const _UsersDashboardView({this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = AppBreakpoints.isPhone(width);
    final isDesktop = AppBreakpoints.isDesktop(width);
    final canCreate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canCreateUsers() == true,
    );

    final body = BlocBuilder<UsersDashboardCubit, UsersDashboardState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.dashboard != c.dashboard ||
          p.message != c.message ||
          p.isRefreshing != c.isRefreshing,
      builder: (context, state) {
        if ((state.status == UsersDashboardStatus.loading ||
                state.status == UsersDashboardStatus.initial) &&
            state.dashboard == null) {
          return AppLoader(message: l10n.usersLoading);
        }
        if (state.status == UsersDashboardStatus.failure &&
            state.dashboard == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.usersLoadFailed,
                        ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () =>
                        context.read<UsersDashboardCubit>().load(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final dashboard = state.dashboard;

        final content = Column(
          children: [
            AppRefreshBar(visible: state.isRefreshing),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<UsersDashboardCubit>().load(),
                child: AppPageFrame(
                  maxWidth: AppBreakpoints.contentWideMax,
                  child: ListView(
                    padding: AppScrollPadding.resolve(
                      context,
                      base: EdgeInsets.all(
                        isPhone ? AppSpacing.md : AppSpacing.lg,
                      ),
                      chrome: AppBottomChrome.system,
                    ),
                    children: [
                      if (embedded) ...[
                        Text(
                          l10n.usersTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      AppDesktopStatGrid(
                        phoneColumns: 2,
                        tabletColumns: 2,
                        desktopColumns: 4,
                        children: [
                          DashboardQuickCard(
                            title: l10n.usersTotal,
                            subtitle: '${dashboard?.totalUsers ?? 0}',
                            icon: Icons.people_outline,
                            compact: true,
                            onTap: () => context.push(RoutePaths.usersList),
                          ),
                          DashboardQuickCard(
                            title: l10n.usersStatusActive,
                            subtitle: '${dashboard?.activeUsers ?? 0}',
                            icon: Icons.check_circle_outline,
                            compact: true,
                            onTap: () => context.push(
                              RoutePaths.usersList,
                              extra: ManagedUserStatus.active,
                            ),
                          ),
                          DashboardQuickCard(
                            title: l10n.usersStatusDisabled,
                            subtitle: '${dashboard?.disabledUsers ?? 0}',
                            icon: Icons.block_outlined,
                            compact: true,
                            onTap: () => context.push(
                              RoutePaths.usersList,
                              extra: ManagedUserStatus.disabled,
                            ),
                          ),
                          DashboardQuickCard(
                            title: l10n.usersStatusLocked,
                            subtitle: '${dashboard?.lockedUsers ?? 0}',
                            icon: Icons.lock_outline,
                            compact: true,
                            onTap: () => context.push(
                              RoutePaths.usersList,
                              extra: ManagedUserStatus.locked,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (isDesktop || embedded)
                        AppDesktopStatGrid(
                          phoneColumns: 1,
                          tabletColumns: 2,
                          desktopColumns: 2,
                          children: [
                            AppDesktopActionCard(
                              title: l10n.usersList,
                              icon: Icons.list_alt,
                              onTap: () =>
                                  context.push(RoutePaths.usersList),
                            ),
                            if (canCreate)
                              AppDesktopActionCard(
                                title: l10n.usersCreate,
                                icon: Icons.person_add_alt_1,
                                onTap: () =>
                                    context.push(RoutePaths.usersForm),
                              ),
                            AppDesktopActionCard(
                              title: l10n.usersChangePassword,
                              icon: Icons.lock_outline,
                              onTap: () => context
                                  .push(RoutePaths.usersChangePassword),
                            ),
                          ],
                        )
                      else
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  context.push(RoutePaths.usersList),
                              icon: const Icon(Icons.list_alt),
                              label: Text(l10n.usersList),
                            ),
                            if (canCreate)
                              FilledButton.icon(
                                onPressed: () =>
                                    context.push(RoutePaths.usersForm),
                                icon: const Icon(Icons.person_add_alt_1),
                                label: Text(l10n.usersCreate),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

        return content;
      },
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.usersTitle),
        actions: [
          IconButton(
            tooltip: l10n.usersChangePassword,
            icon: const Icon(Icons.lock_outline),
            onPressed: () => context.push(RoutePaths.usersChangePassword),
          ),
        ],
      ),
      body: body,
    );
  }
}
