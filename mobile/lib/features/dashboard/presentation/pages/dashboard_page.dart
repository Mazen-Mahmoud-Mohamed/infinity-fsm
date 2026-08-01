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
import 'package:mobile/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/cubit/executive_dashboard_cubit.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_period_selector.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_quick_actions.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_role_sections.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:mobile/core/widgets/offline_banner.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExecutiveDashboardCubit>()..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  int _chartWindowDays = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authUser = context.watch<AuthCubit>().state.user;
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    final pagePadding = isPhone ? AppSpacing.md : AppSpacing.lg;
    final sectionGap = isPhone ? AppSpacing.md : AppSpacing.lg;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () => context.push(RoutePaths.notifications),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: l10n.settings,
            onPressed: () => context.push(RoutePaths.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: BlocBuilder<ExecutiveDashboardCubit, ExecutiveDashboardState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.summary != current.summary ||
            previous.period != current.period ||
            previous.customFrom != current.customFrom ||
            previous.customTo != current.customTo ||
            previous.isRefreshing != current.isRefreshing ||
            previous.message != current.message,
        builder: (context, state) {
          if (state.status == ExecutiveDashboardStatus.loading &&
              !state.hasLoadedOnce &&
              state.summary == null) {
            return AppLoader(message: l10n.dashboardLoading);
          }

          if (state.status == ExecutiveDashboardStatus.failure &&
              state.summary == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message ?? l10n.errorGeneric,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () =>
                          context.read<ExecutiveDashboardCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final summary = state.summary;
          final isTechnician =
              summary?.viewRole == DashboardViewRole.technician;

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<ExecutiveDashboardCubit>().load(),
                  child: ListView(
                    padding: AppScrollPadding.resolve(
                      context,
                      base: EdgeInsets.all(pagePadding),
                      chrome: AppBottomChrome.system,
                    ),
                    children: [
                      Text(
                        l10n.welcomeBack,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        authUser?.fullName ?? l10n.profile,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DashboardPeriodSelector(
                        period: state.period,
                        customFrom: state.customFrom,
                        customTo: state.customTo,
                        rangeFrom: summary != null &&
                                summary.period == state.period
                            ? summary.from
                            : null,
                        rangeTo: summary != null &&
                                summary.period == state.period
                            ? summary.to
                            : null,
                        onPeriodSelected: (period) => context
                            .read<ExecutiveDashboardCubit>()
                            .setPeriod(period),
                        onCustomRangeSelected: (from, to) => context
                            .read<ExecutiveDashboardCubit>()
                            .setCustomRange(from, to),
                      ),
                      if (state.message != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.message!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                        ),
                      ],
                      if (isTechnician) ...[
                        SizedBox(height: sectionGap),
                        const AttendanceSummaryCard(),
                      ],
                      if (summary != null) ...[
                        SizedBox(height: sectionGap),
                        ...buildRoleDashboardSections(
                          context: context,
                          l10n: l10n,
                          summary: summary,
                          sectionGap: sectionGap,
                          chartWindowDays: _chartWindowDays,
                          onChartWindowChanged: (days) {
                            setState(() => _chartWindowDays = days);
                          },
                        ),
                      ],
                      if (DashboardQuickActionsGrid.hasVisibleActions(
                        authUser?.permissionChecker,
                      )) ...[
                        SizedBox(height: sectionGap),
                        DashboardSection(
                          title: l10n.dashboardQuickActions,
                          child: DashboardQuickActionsGrid(
                            permissions: authUser?.permissionChecker,
                          ),
                        ),
                      ],
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
}

/// Bottom navigation shell used by [StatefulShellRoute] in the app router.
class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 400;
    final veryCompact = width < 340;

    return Scaffold(
      body: Column(
        children: [
          BlocBuilder<AppCubit, AppState>(
            buildWhen: (previous, current) =>
                previous.isOnline != current.isOnline,
            builder: (context, state) {
              return OfflineBanner(visible: !state.isOnline);
            },
          ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: compact ? 68 : 80,
        labelBehavior: veryCompact
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: compact ? l10n.navDashboard : l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.access_time_outlined),
            selectedIcon: const Icon(Icons.access_time),
            label: compact ? l10n.navAttendance : l10n.attendance,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: compact ? l10n.navWorkOrders : l10n.workOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_time_outlined),
            selectedIcon: const Icon(Icons.more_time),
            label: compact ? l10n.navOvertime : l10n.overtime,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: compact ? l10n.navProfile : l10n.profile,
          ),
        ],
      ),
    );
  }
}
