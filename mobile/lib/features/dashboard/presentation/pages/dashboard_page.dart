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
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/cubit/executive_dashboard_cubit.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_period_selector.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_role_sections.dart';
import 'package:mobile/core/widgets/offline_banner.dart';
import 'package:mobile/features/notifications/presentation/widgets/notifications_bell_action.dart';
import 'package:mobile/features/global_search/presentation/widgets/global_search_dialog.dart';
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
          const GlobalSearchAction(),
          const NotificationsBellAction(),
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
                      state.message != null
                          ? localizeAppMessage(l10n, state.message)
                          : l10n.errorGeneric,
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
                              permissions: authUser?.permissionChecker,
                              showQuickActions: isPhone,
                            ),
                          ] else ...[
                            SizedBox(height: sectionGap),
                            AppLoader(message: l10n.dashboardLoading),
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
/// Phones use a bottom [NavigationBar] (first five branches for management,
/// four operational branches for technicians).
/// Tablet/desktop use a [NavigationRail] for primary modules.
class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Shell branch indexes (must match [createAppRouter] branch order).
  static const int _branchDashboard = 0;
  static const int _branchAttendance = 1;
  static const int _branchWorkOrders = 2;
  static const int _branchOvertime = 3;
  static const int _branchProfile = 4;
  static const int _branchInventory = 5;
  static const int _branchAssets = 6;
  static const int _branchPm = 7;
  static const int _branchReports = 8;
  static const int _branchUsers = 9;
  static const int _branchRoles = 10;
  static const int _branchSettings = 11;

  /// Management phone bottom bar: Dashboard → Attendance → WO → OT → Profile.
  static const List<int> _managementPhoneBranches = [
    _branchDashboard,
    _branchAttendance,
    _branchWorkOrders,
    _branchOvertime,
    _branchProfile,
  ];

  /// Technician phone bottom bar (operational home first): WO → Attendance → OT → Profile.
  static const List<int> _technicianPhoneBranches = [
    _branchWorkOrders,
    _branchAttendance,
    _branchOvertime,
    _branchProfile,
  ];

  /// Technician tablet/desktop rail — no executive Dashboard / analytics hub.
  static const List<int> _technicianRailBranches = [
    _branchAttendance,
    _branchWorkOrders,
    _branchOvertime,
    _branchProfile,
    _branchInventory,
    _branchAssets,
    _branchPm,
    _branchUsers,
    _branchRoles,
    _branchSettings,
  ];

  /// Desktop extended rail width (+28 vs previous 220). Tablet [minWidth] unchanged.
  static const double _desktopExtendedRailWidth = 248;

  void _goBranch(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  /// Builds a rail destination. Extra horizontal padding / icon–label gap
  /// apply only when the rail is extended (large desktop).
  static NavigationRailDestination _railDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool extended,
  }) {
    return NavigationRailDestination(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      // Material default horizontal padding is 8; give desktop tiles more air.
      padding: extended
          ? const EdgeInsets.symmetric(horizontal: 12)
          : null,
      label: Padding(
        // Adds ~4px to Material's icon↔label gap on desktop only.
        padding: extended
            ? const EdgeInsetsDirectional.only(start: 4)
            : EdgeInsets.zero,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  NavigationRailDestination _destinationForBranch({
    required int branchIndex,
    required AppLocalizations l10n,
    required bool extended,
  }) {
    return switch (branchIndex) {
      _branchDashboard => _railDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: l10n.dashboard,
          extended: extended,
        ),
      _branchAttendance => _railDestination(
          icon: Icons.access_time_outlined,
          selectedIcon: Icons.access_time,
          label: l10n.attendance,
          extended: extended,
        ),
      _branchWorkOrders => _railDestination(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: l10n.workOrders,
          extended: extended,
        ),
      _branchOvertime => _railDestination(
          icon: Icons.more_time_outlined,
          selectedIcon: Icons.more_time,
          label: l10n.overtime,
          extended: extended,
        ),
      _branchProfile => _railDestination(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: l10n.profile,
          extended: extended,
        ),
      _branchInventory => _railDestination(
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          label: l10n.inventory,
          extended: extended,
        ),
      _branchAssets => _railDestination(
          icon: Icons.precision_manufacturing_outlined,
          selectedIcon: Icons.precision_manufacturing,
          label: l10n.assets,
          extended: extended,
        ),
      _branchPm => _railDestination(
          icon: Icons.build_circle_outlined,
          selectedIcon: Icons.build_circle,
          label: l10n.assetsStatusMaintenance,
          extended: extended,
        ),
      _branchReports => _railDestination(
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics,
          label: l10n.reportsCenter,
          extended: extended,
        ),
      _branchUsers => _railDestination(
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts,
          label: l10n.usersTitle,
          extended: extended,
        ),
      _branchRoles => _railDestination(
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          label: l10n.rolesTitle,
          extended: extended,
        ),
      _branchSettings => _railDestination(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: l10n.settings,
          extended: extended,
        ),
      _ => _railDestination(
          icon: Icons.circle_outlined,
          selectedIcon: Icons.circle,
          label: '',
          extended: extended,
        ),
    };
  }

  NavigationDestination _phoneDestinationForBranch({
    required int branchIndex,
    required AppLocalizations l10n,
    required bool compact,
  }) {
    return switch (branchIndex) {
      _branchDashboard => NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: compact ? l10n.navDashboard : l10n.dashboard,
        ),
      _branchAttendance => NavigationDestination(
          icon: const Icon(Icons.access_time_outlined),
          selectedIcon: const Icon(Icons.access_time),
          label: compact ? l10n.navAttendance : l10n.attendance,
        ),
      _branchWorkOrders => NavigationDestination(
          icon: const Icon(Icons.assignment_outlined),
          selectedIcon: const Icon(Icons.assignment),
          label: compact ? l10n.navWorkOrders : l10n.workOrders,
        ),
      _branchOvertime => NavigationDestination(
          icon: const Icon(Icons.more_time_outlined),
          selectedIcon: const Icon(Icons.more_time),
          label: compact ? l10n.navOvertime : l10n.overtime,
        ),
      _branchProfile => NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: compact ? l10n.navProfile : l10n.profile,
        ),
      _ => const NavigationDestination(
          icon: Icon(Icons.circle_outlined),
          selectedIcon: Icon(Icons.circle),
          label: '',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = AppBreakpoints.isPhone(width);
    final compact = width < 400;
    final veryCompact = width < 340;
    final extendedRail = width >= 1100;
    final user = context.watch<AuthCubit>().state.user;
    final operational = user?.usesOperationalHome ?? false;
    final phoneBranches =
        operational ? _technicianPhoneBranches : _managementPhoneBranches;
    final railBranches = operational
        ? _technicianRailBranches
        : const [
            _branchDashboard,
            _branchAttendance,
            _branchWorkOrders,
            _branchOvertime,
            _branchProfile,
            _branchInventory,
            _branchAssets,
            _branchPm,
            _branchReports,
            _branchUsers,
            _branchRoles,
            _branchSettings,
          ];
    final homeBranch =
        operational ? _branchWorkOrders : _branchDashboard;
    final currentBranch = navigationShell.currentIndex;

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
      final railSelected = railBranches.indexOf(currentBranch);
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavigationRail(
              extended: extendedRail,
              minExtendedWidth: _desktopExtendedRailWidth,
              useIndicator: true,
              selectedIndex: railSelected < 0 ? 0 : railSelected,
              onDestinationSelected: (uiIndex) {
                if (uiIndex >= 0 && uiIndex < railBranches.length) {
                  _goBranch(railBranches[uiIndex]);
                }
              },
              labelType: extendedRail
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: EdgeInsets.fromLTRB(
                  extendedRail ? 20 : AppSpacing.md,
                  AppSpacing.lg,
                  extendedRail ? 20 : AppSpacing.md,
                  extendedRail ? AppSpacing.md : AppSpacing.sm,
                ),
                child: extendedRail
                    ? Text(
                        operational ? l10n.workOrders : l10n.dashboard,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      )
                    : Icon(
                        operational
                            ? Icons.assignment_outlined
                            : Icons.apps_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
              destinations: [
                for (final branch in railBranches)
                  _destinationForBranch(
                    branchIndex: branch,
                    l10n: l10n,
                    extended: extendedRail,
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: shellBody),
          ],
        ),
      );
    }

    final phoneSelected = phoneBranches.indexOf(currentBranch);
    final showPhoneNav = phoneSelected >= 0;

    return Scaffold(
      body: shellBody,
      bottomNavigationBar: showPhoneNav
          ? NavigationBar(
              height: compact ? 68 : 80,
              labelBehavior: veryCompact
                  ? NavigationDestinationLabelBehavior.onlyShowSelected
                  : NavigationDestinationLabelBehavior.alwaysShow,
              selectedIndex: phoneSelected,
              onDestinationSelected: (uiIndex) {
                if (uiIndex >= 0 && uiIndex < phoneBranches.length) {
                  _goBranch(phoneBranches[uiIndex]);
                }
              },
              destinations: [
                for (final branch in phoneBranches)
                  _phoneDestinationForBranch(
                    branchIndex: branch,
                    l10n: l10n,
                    compact: compact,
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
                      onPressed: () => _goBranch(homeBranch),
                      icon: Icon(
                        operational
                            ? Icons.assignment_outlined
                            : Icons.home_outlined,
                      ),
                      label: Text(
                        operational ? l10n.workOrders : l10n.dashboard,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
