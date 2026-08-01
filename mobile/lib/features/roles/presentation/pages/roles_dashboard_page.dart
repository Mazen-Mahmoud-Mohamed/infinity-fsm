import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_action_card.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_stat_grid.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_quick_card.dart';
import 'package:mobile/features/roles/presentation/cubit/roles_cubits.dart';

class RolesDashboardPage extends StatefulWidget {
  const RolesDashboardPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<RolesDashboardPage> createState() => _RolesDashboardPageState();
}

class _RolesDashboardPageState extends State<RolesDashboardPage> {
  late final RolesDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<RolesDashboardCubit>()..load();
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
      child: _RolesDashboardView(embedded: widget.embedded),
    );
  }
}

class _RolesDashboardView extends StatelessWidget {
  const _RolesDashboardView({this.embedded = false});

  final bool embedded;

  Future<void> _openCreate(BuildContext context) async {
    final changed = await context.push<bool>(RoutePaths.rolesForm);
    if (changed == true && context.mounted) {
      await context.read<RolesDashboardCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = AppBreakpoints.isPhone(width);
    final isDesktop = AppBreakpoints.isDesktop(width);
    final canCreate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canCreateRoles() == true,
    );

    final body = BlocBuilder<RolesDashboardCubit, RolesDashboardState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.dashboard != c.dashboard ||
          p.message != c.message ||
          p.isRefreshing != c.isRefreshing,
      builder: (context, state) {
        if ((state.status == RolesDashboardStatus.loading ||
                state.status == RolesDashboardStatus.initial) &&
            state.dashboard == null) {
          return AppLoader(message: l10n.rolesLoading);
        }
        if (state.status == RolesDashboardStatus.failure &&
            state.dashboard == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message ?? l10n.rolesLoadFailed),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () =>
                        context.read<RolesDashboardCubit>().load(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final dashboard = state.dashboard;

        return Column(
          children: [
            AppRefreshBar(visible: state.isRefreshing),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<RolesDashboardCubit>().load(),
                child: AppPageFrame(
                  maxWidth: AppBreakpoints.contentWideMax,
                  child: ListView(
                    padding: AppScrollPadding.resolve(
                      context,
                      base: EdgeInsets.all(
                        isPhone ? AppSpacing.md : AppSpacing.lg,
                      ),
                      chrome: AppBottomChrome.fab,
                    ),
                    children: [
                      if (embedded) ...[
                        Text(
                          l10n.rolesTitle,
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
                            title: l10n.rolesTotal,
                            subtitle: '${dashboard?.totalRoles ?? 0}',
                            icon: Icons.security_outlined,
                            compact: true,
                            onTap: () => context.push(RoutePaths.rolesList),
                          ),
                          DashboardQuickCard(
                            title: l10n.rolesActive,
                            subtitle: '${dashboard?.activeRoles ?? 0}',
                            icon: Icons.check_circle_outline,
                            compact: true,
                            onTap: () => context.push(
                              RoutePaths.rolesList,
                              extra: {'isActive': true},
                            ),
                          ),
                          DashboardQuickCard(
                            title: l10n.rolesSystem,
                            subtitle: '${dashboard?.systemRoles ?? 0}',
                            icon: Icons.verified_user_outlined,
                            compact: true,
                            onTap: () => context.push(
                              RoutePaths.rolesList,
                              extra: {'isSystem': true},
                            ),
                          ),
                          DashboardQuickCard(
                            title: l10n.rolesCustom,
                            subtitle: '${dashboard?.customRoles ?? 0}',
                            icon: Icons.tune_outlined,
                            compact: true,
                            onTap: () => context.push(
                              RoutePaths.rolesList,
                              extra: {'isSystem': false},
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
                              title: l10n.rolesList,
                              icon: Icons.list_alt,
                              onTap: () =>
                                  context.push(RoutePaths.rolesList),
                            ),
                            if (canCreate)
                              AppDesktopActionCard(
                                title: l10n.rolesCreate,
                                icon: Icons.add,
                                onTap: () => _openCreate(context),
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
                                  context.push(RoutePaths.rolesList),
                              icon: const Icon(Icons.list_alt),
                              label: Text(l10n.rolesList),
                            ),
                            if (embedded && canCreate)
                              FilledButton.icon(
                                onPressed: () => _openCreate(context),
                                icon: const Icon(Icons.add),
                                label: Text(l10n.rolesCreate),
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
      },
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rolesTitle)),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openCreate(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.rolesCreate),
            )
          : null,
      body: body,
    );
  }
}
