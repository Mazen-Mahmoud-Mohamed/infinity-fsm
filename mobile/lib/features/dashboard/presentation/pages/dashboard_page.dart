import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
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
    debugPrint(
      'DashboardPage.build width=${MediaQuery.sizeOf(context).width}',
    );
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
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = AppBreakpoints.isPhone(width);
    final pagePadding = AppBreakpoints.pagePadding(width);
    final sectionGap = isPhone ? AppSpacing.md : AppSpacing.lg;

    debugPrint(
      '_DashboardView.build width=$width isPhone=$isPhone',
    );

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
            onPressed: () => context.go(RoutePaths.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: BlocConsumer<ExecutiveDashboardCubit, ExecutiveDashboardState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.message != current.message ||
            previous.summary != current.summary,
        listener: (context, state) {
          debugPrint(
            'DashboardCubit state → status=${state.status} '
            'hasSummary=${state.summary != null} '
            'hasLoadedOnce=${state.hasLoadedOnce} '
            'refreshing=${state.isRefreshing} '
            'message=${state.message}',
          );
        },
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.summary != current.summary ||
            previous.period != current.period ||
            previous.customFrom != current.customFrom ||
            previous.customTo != current.customTo ||
            previous.isRefreshing != current.isRefreshing ||
            previous.message != current.message,
        builder: (context, state) {
          debugPrint(
            'Dashboard body builder status=${state.status} '
            'summary=${state.summary != null}',
          );

          if (state.status == ExecutiveDashboardStatus.initial ||
              (state.status == ExecutiveDashboardStatus.loading &&
                  state.summary == null)) {
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
                    Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
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

          // Content always visible once we have a non-failure state.
          // Width-capped via Align/ConstrainedBox (not AppPageFrame height lock).
          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<ExecutiveDashboardCubit>().load(),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppBreakpoints.contentWideMax,
                      ),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: AppScrollPadding.resolve(
                          context,
                          base: EdgeInsets.all(pagePadding),
                          chrome: AppBottomChrome.system,
                        ),
                        children: [
                          Text(
                            l10n.welcomeBack,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.error,
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
                          ] else ...[
                            SizedBox(height: sectionGap),
                            AppLoader(message: l10n.dashboardLoading),
                          ],
                          // Quick Actions stay on phone only — desktop uses
                          // NavigationRail destinations instead.
                          if (isPhone &&
                              DashboardQuickActionsGrid.hasVisibleActions(
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Primary navigation shell used by [StatefulShellRoute] in the app router.
///
/// Phones use a bottom [NavigationBar] (first five branches).
/// Tablet/desktop use a [NavigationRail] for all primary modules.
class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Phone bottom bar only exposes the first five shell branches.
  static const int _phoneDestinationCount = 5;

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
    final isPhone = AppBreakpoints.isPhone(width);
    final compact = width < 400;
    final veryCompact = width < 340;
    final extendedRail = width >= 1100;

    final shellBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
    );

    if (!isPhone) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavigationRail(
              extended: extendedRail,
              minExtendedWidth: 220,
              useIndicator: true,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: extendedRail
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  extendedRail ? AppSpacing.md : AppSpacing.sm,
                ),
                child: extendedRail
                    ? Text(
                        l10n.dashboard,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      )
                    : Icon(
                        Icons.apps_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: Text(l10n.dashboard),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.access_time_outlined),
                  selectedIcon: const Icon(Icons.access_time),
                  label: Text(l10n.attendance),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.assignment_outlined),
                  selectedIcon: const Icon(Icons.assignment),
                  label: Text(l10n.workOrders),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.more_time_outlined),
                  selectedIcon: const Icon(Icons.more_time),
                  label: Text(l10n.overtime),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: Text(l10n.profile),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: const Icon(Icons.inventory_2),
                  label: Text(l10n.inventory),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.precision_manufacturing_outlined),
                  selectedIcon: const Icon(Icons.precision_manufacturing),
                  label: Text(l10n.assets),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.build_circle_outlined),
                  selectedIcon: const Icon(Icons.build_circle),
                  // Short desktop rail label ("Maintenance" / "صيانة").
                  label: Text(l10n.assetsStatusMaintenance),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.description_outlined),
                  selectedIcon: const Icon(Icons.description),
                  label: Text(l10n.reportsTitle),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.manage_accounts_outlined),
                  selectedIcon: const Icon(Icons.manage_accounts),
                  label: Text(l10n.usersTitle),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  selectedIcon: const Icon(Icons.admin_panel_settings),
                  label: Text(l10n.rolesTitle),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: Text(l10n.settings),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: shellBody),
          ],
        ),
      );
    }

    final phoneIndex = navigationShell.currentIndex;
    final showPhoneNav = phoneIndex < _phoneDestinationCount;

    return Scaffold(
      body: shellBody,
      bottomNavigationBar: showPhoneNav
          ? NavigationBar(
              height: compact ? 68 : 80,
              labelBehavior: veryCompact
                  ? NavigationDestinationLabelBehavior.onlyShowSelected
                  : NavigationDestinationLabelBehavior.alwaysShow,
              selectedIndex: phoneIndex,
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
            )
          : Material(
              elevation: 3,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _onDestinationSelected(0),
                      icon: const Icon(Icons.home_outlined),
                      label: Text(l10n.dashboard),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
