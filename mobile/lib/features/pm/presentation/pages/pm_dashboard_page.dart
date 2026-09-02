import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_empty_state.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_nav_tile.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_page_layout.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_stat_grid.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_quick_card.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_dashboard_cubit.dart';
import 'package:mobile/features/pm/presentation/widgets/pm_schedule_tile.dart';

class PmDashboardPage extends StatefulWidget {
  const PmDashboardPage({super.key});

  @override
  State<PmDashboardPage> createState() => _PmDashboardPageState();
}

class _PmDashboardPageState extends State<PmDashboardPage> {
  late final PmDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<PmDashboardCubit>()..load();
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
      child: const _PmDashboardView(),
    );
  }
}

class _PmDashboardView extends StatelessWidget {
  const _PmDashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = AppBreakpoints.isPhone(width);
    final isDesktop = AppBreakpoints.isDesktop(width);
    final canCreate = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canCreatePm() == true,
    );

    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: Text(l10n.pmTitle)),
      body: BlocBuilder<PmDashboardCubit, PmDashboardState>(
        buildWhen: (p, c) =>
            p.status != c.status ||
            p.dashboard != c.dashboard ||
            p.message != c.message ||
            p.isRefreshing != c.isRefreshing,
        builder: (context, state) {
          if ((state.status == PmDashboardStatus.loading ||
                  state.status == PmDashboardStatus.initial) &&
              state.dashboard == null) {
            return AppLoader(message: l10n.pmLoading);
          }
          if (state.status == PmDashboardStatus.failure &&
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
                          : l10n.pmLoadFailed,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () =>
                          context.read<PmDashboardCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final dashboard = state.dashboard;
          final recent = dashboard?.recentSchedules ?? const [];

          final statCards = [
            DashboardQuickCard(
              title: l10n.pmUpcoming,
              subtitle: '${dashboard?.upcoming ?? 0}',
              icon: Icons.upcoming_outlined,
              compact: true,
              onTap: () => context.push(
                RoutePaths.pmSchedules,
                extra: PmScheduleStatus.scheduled.apiValue,
              ),
            ),
            DashboardQuickCard(
              title: l10n.pmOverdue,
              subtitle: '${dashboard?.overdue ?? 0}',
              icon: Icons.warning_amber_outlined,
              compact: true,
              onTap: () => context.push(
                RoutePaths.pmSchedules,
                extra: PmScheduleStatus.overdue.apiValue,
              ),
            ),
            DashboardQuickCard(
              title: l10n.pmCompleted,
              subtitle: '${dashboard?.completed ?? 0}',
              icon: Icons.check_circle_outline,
              compact: true,
              onTap: () => context.push(RoutePaths.pmHistory),
            ),
            DashboardQuickCard(
              title: l10n.pmCancelled,
              subtitle: '${dashboard?.cancelled ?? 0}',
              icon: Icons.cancel_outlined,
              compact: true,
              onTap: () => context.push(
                RoutePaths.pmSchedules,
                extra: PmScheduleStatus.cancelled.apiValue,
              ),
            ),
          ];

          if (isDesktop) {
            return AppDesktopPageLayout(
              title: l10n.pmTitle,
              isRefreshing: state.isRefreshing,
              headerTrailing: canCreate
                  ? FilledButton.icon(
                      onPressed: () => context.push(RoutePaths.pmPlanForm),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.pmCreatePlan),
                    )
                  : null,
              body: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  AppDesktopStatGrid(
                    phoneColumns: 2,
                    tabletColumns: 4,
                    desktopColumns: 4,
                    children: statCards,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.dashboardOverview,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 2.6,
                    children: [
                      AppDesktopNavTile(
                        title: l10n.pmPlans,
                        subtitle: l10n.pmActivePlans,
                        icon: Icons.checklist_outlined,
                        onTap: () => context.push(RoutePaths.pmPlans),
                      ),
                      AppDesktopNavTile(
                        title: l10n.pmSchedules,
                        subtitle: l10n.pmRecentSchedules,
                        icon: Icons.calendar_month_outlined,
                        onTap: () => context.push(RoutePaths.pmSchedules),
                      ),
                      AppDesktopNavTile(
                        title: l10n.pmHistory,
                        subtitle: l10n.pmCompleted,
                        icon: Icons.history,
                        onTap: () => context.push(RoutePaths.pmHistory),
                      ),
                      if (canCreate)
                        AppDesktopNavTile(
                          title: l10n.pmCreatePlan,
                          subtitle: l10n.pmPlans,
                          icon: Icons.add_circle_outline,
                          onTap: () => context.push(RoutePaths.pmPlanForm),
                        ),
                    ],
                  ),
                  if (recent.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.pmRecentSchedules,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...recent.map(
                      (schedule) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: PmScheduleTile(
                          schedule: schedule,
                          onTap: () => context.push(RoutePaths.pmSchedules),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppDesktopEmptyState(
                      icon: Icons.event_available_outlined,
                      title: l10n.pmRecentSchedules,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${l10n.pmActivePlans}: ${dashboard?.activePlans ?? 0}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final cols = isPhone ? 2 : 4;

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<PmDashboardCubit>().load(),
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
                          l10n.pmUpcoming,
                          '${dashboard?.upcoming ?? 0}',
                          Icons.upcoming_outlined,
                          () => context.push(
                            RoutePaths.pmSchedules,
                            extra: PmScheduleStatus.scheduled.apiValue,
                          ),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.pmOverdue,
                          '${dashboard?.overdue ?? 0}',
                          Icons.warning_amber_outlined,
                          () => context.push(
                            RoutePaths.pmSchedules,
                            extra: PmScheduleStatus.overdue.apiValue,
                          ),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.pmCompleted,
                          '${dashboard?.completed ?? 0}',
                          Icons.check_circle_outline,
                          () => context.push(RoutePaths.pmHistory),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.pmCancelled,
                          '${dashboard?.cancelled ?? 0}',
                          Icons.cancel_outlined,
                          () => context.push(
                            RoutePaths.pmSchedules,
                            extra: PmScheduleStatus.cancelled.apiValue,
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
                      onPressed: () => context.push(RoutePaths.pmPlans),
                      icon: const Icon(Icons.checklist_outlined),
                      label: Text(l10n.pmPlans),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.pmSchedules),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(l10n.pmSchedules),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(RoutePaths.pmHistory),
                      icon: const Icon(Icons.history),
                      label: Text(l10n.pmHistory),
                    ),
                    if (canCreate)
                      FilledButton.icon(
                        onPressed: () => context.push(RoutePaths.pmPlanForm),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.pmCreatePlan),
                      ),
                  ],
                ),
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.pmRecentSchedules,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...recent.map(
                    (schedule) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: PmScheduleTile(
                        schedule: schedule,
                        onTap: () => context.push(RoutePaths.pmSchedules),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${l10n.pmActivePlans}: ${dashboard?.activePlans ?? 0}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (dashboard != null)
                  Text(
                    AppFormatters.mediumDateTimeSpaced(context).format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall,
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
