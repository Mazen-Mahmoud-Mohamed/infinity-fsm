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
import 'package:mobile/features/roles/presentation/cubit/roles_cubits.dart';

class RolesDashboardPage extends StatefulWidget {
  const RolesDashboardPage({super.key});

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
      child: const _RolesDashboardView(),
    );
  }
}

class _RolesDashboardView extends StatelessWidget {
  const _RolesDashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;
    final canCreate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canCreateRoles() == true,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rolesTitle)),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final changed = await context.push<bool>(RoutePaths.rolesForm);
                if (changed == true && context.mounted) {
                  await context.read<RolesDashboardCubit>().load();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.rolesCreate),
            )
          : null,
      body: BlocBuilder<RolesDashboardCubit, RolesDashboardState>(
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
          final cols = isPhone ? 2 : 4;

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<RolesDashboardCubit>().load(),
                  child: ListView(
                    padding: AppScrollPadding.resolve(
                      context,
                      base: EdgeInsets.all(
                        isPhone ? AppSpacing.md : AppSpacing.lg,
                      ),
                      chrome: AppBottomChrome.fab,
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
                          l10n.rolesTotal,
                          '${dashboard?.totalRoles ?? 0}',
                          Icons.security_outlined,
                          () => context.push(RoutePaths.rolesList),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.rolesActive,
                          '${dashboard?.activeRoles ?? 0}',
                          Icons.check_circle_outline,
                          () => context.push(
                            RoutePaths.rolesList,
                            extra: {'isActive': true},
                          ),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.rolesSystem,
                          '${dashboard?.systemRoles ?? 0}',
                          Icons.verified_user_outlined,
                          () => context.push(
                            RoutePaths.rolesList,
                            extra: {'isSystem': true},
                          ),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.rolesCustom,
                          '${dashboard?.customRoles ?? 0}',
                          Icons.tune_outlined,
                          () => context.push(
                            RoutePaths.rolesList,
                            extra: {'isSystem': false},
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.tonalIcon(
                  onPressed: () => context.push(RoutePaths.rolesList),
                  icon: const Icon(Icons.list_alt),
                  label: Text(l10n.rolesList),
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
    bool isPhone,
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: width,
      child: DashboardQuickCard(
        title: title,
        subtitle: value,
        icon: icon,
        onTap: onTap,
        compact: isPhone,
      ),
    );
  }
}
