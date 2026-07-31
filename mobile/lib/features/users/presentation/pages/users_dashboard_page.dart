import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_quick_card.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/presentation/cubit/users_cubits.dart';

class UsersDashboardPage extends StatefulWidget {
  const UsersDashboardPage({super.key});

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
      child: const _UsersDashboardView(),
    );
  }
}

class _UsersDashboardView extends StatelessWidget {
  const _UsersDashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;
    final canCreate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canCreateUsers() == true,
    );

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
      body: BlocBuilder<UsersDashboardCubit, UsersDashboardState>(
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
                    Text(state.message ?? l10n.usersLoadFailed),
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
          final cols = isPhone ? 2 : 4;

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<UsersDashboardCubit>().load(),
                  child: ListView(
                    padding: AppScrollPadding.resolve(
                      context,
                      base: EdgeInsets.all(
                        isPhone ? AppSpacing.md : AppSpacing.lg,
                      ),
                      chrome: AppBottomChrome.system,
                    ),
                    children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth =
                        (constraints.maxWidth - (AppSpacing.md * (cols - 1))) /
                            cols;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.usersTotal,
                          '${dashboard?.totalUsers ?? 0}',
                          Icons.people_outline,
                          () => context.push(RoutePaths.usersList),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.usersStatusActive,
                          '${dashboard?.activeUsers ?? 0}',
                          Icons.check_circle_outline,
                          () => context.push(
                            RoutePaths.usersList,
                            extra: ManagedUserStatus.active.apiValue,
                          ),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.usersStatusDisabled,
                          '${dashboard?.disabledUsers ?? 0}',
                          Icons.block_outlined,
                          () => context.push(
                            RoutePaths.usersList,
                            extra: ManagedUserStatus.disabled.apiValue,
                          ),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.usersStatusLocked,
                          '${dashboard?.lockedUsers ?? 0}',
                          Icons.lock_outline,
                          () => context.push(
                            RoutePaths.usersList,
                            extra: ManagedUserStatus.locked.apiValue,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.usersList),
                      icon: const Icon(Icons.list_alt),
                      label: Text(l10n.usersList),
                    ),
                    if (canCreate)
                      FilledButton.icon(
                        onPressed: () => context.push(RoutePaths.usersForm),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: Text(l10n.usersCreate),
                      ),
                  ],
                ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(
    double width,
    bool compact,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: width,
      child: DashboardQuickCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        compact: compact,
        onTap: onTap,
      ),
    );
  }
}
