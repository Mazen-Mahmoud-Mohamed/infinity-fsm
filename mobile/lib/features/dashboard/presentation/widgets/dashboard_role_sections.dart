import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_audit_event.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_executive_layout.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_metric_group_card.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_mini_chart.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_overtime_section.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_quick_actions.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_dense_widgets.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_section_grid.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_typography.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';

String formatDashboardNum(num value, [BuildContext? context]) {
  if (context != null) {
    return AppFormatters.formatDecimalOrInt(context, value);
  }
  if (value is int || value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}

String formatDashboardHours(num value, AppLocalizations l10n,
        [BuildContext? context]) =>
    DurationFormatter.fromHours(value, l10n);

String formatDashboardPercent(num value, AppLocalizations l10n,
        [BuildContext? context]) =>
    l10n.dashboardPercentValue(formatDashboardNum(value, context));

List<Widget> buildRoleDashboardSections({
  required BuildContext context,
  required AppLocalizations l10n,
  required RoleDashboardSummary summary,
  required double sectionGap,
  required int chartWindowDays,
  required ValueChanged<int> onChartWindowChanged,
  PermissionChecker? permissions,
  bool showQuickActions = false,
}) {
  switch (summary.viewRole) {
    case DashboardViewRole.admin:
      return _admin(
        context: context,
        l10n: l10n,
        summary: summary,
        sectionGap: sectionGap,
        chartWindowDays: chartWindowDays,
        onChartWindowChanged: onChartWindowChanged,
        permissions: permissions,
        showQuickActions: showQuickActions,
      );
    case DashboardViewRole.supervisor:
      return _supervisor(
        context: context,
        l10n: l10n,
        summary: summary,
        sectionGap: sectionGap,
        chartWindowDays: chartWindowDays,
        onChartWindowChanged: onChartWindowChanged,
        permissions: permissions,
        showQuickActions: showQuickActions,
      );
    case DashboardViewRole.technician:
      return _technician(
        context: context,
        l10n: l10n,
        summary: summary,
        sectionGap: sectionGap,
        chartWindowDays: chartWindowDays,
        onChartWindowChanged: onChartWindowChanged,
        permissions: permissions,
        showQuickActions: showQuickActions,
      );
  }
}

List<Widget> _admin({
  required BuildContext context,
  required AppLocalizations l10n,
  required RoleDashboardSummary summary,
  required double sectionGap,
  required int chartWindowDays,
  required ValueChanged<int> onChartWindowChanged,
  PermissionChecker? permissions,
  bool showQuickActions = false,
}) {
  final kpis = summary.kpis;
  final attendance = summary.attendance;
  final overtime = summary.overtime;
  final workOrders = summary.workOrders;
  final pm = summary.preventiveMaintenance;
  final inventory = summary.inventory;
  final assets = summary.assets;
  final scheme = Theme.of(context).colorScheme;

  final kpiStrip = DashboardKpiStrip(
    items: [
      if (kpis != null)
        DashboardKpiItemData(
          label: l10n.dashboardKpiTotalEmployees,
          value: '${kpis.totalEmployees}',
          icon: Icons.groups_outlined,
        ),
      if (kpis != null)
        DashboardKpiItemData(
          label: l10n.dashboardKpiCurrentlyWorking,
          value: '${kpis.employeesCurrentlyWorking}',
          icon: Icons.work_outline,
          onTap: () => context.go(RoutePaths.attendance),
        ),
      if (attendance != null)
        DashboardKpiItemData(
          label: l10n.dashboardKpiTotalWorkingHours,
          value: formatDashboardHours(
            attendance.totalWorkingHours,
            l10n,
            context,
          ),
          icon: Icons.schedule_outlined,
          onTap: () => context.go(RoutePaths.attendance),
        ),
      if (overtime != null)
        DashboardKpiItemData(
          label: l10n.dashboardKpiTotalApprovedHours,
          value: formatDashboardHours(
            overtime.approvedOvertimeHours,
            l10n,
            context,
          ),
          icon: Icons.more_time_outlined,
          onTap: () => context.go(RoutePaths.overtime),
        ),
      if (overtime != null)
        DashboardKpiItemData(
          label: l10n.dashboardKpiTotalOvertimeHours,
          value: formatDashboardHours(
            overtime.totalOvertimeHours,
            l10n,
            context,
          ),
          icon: Icons.more_time_outlined,
          onTap: () => context.go(RoutePaths.overtime),
        ),
      if (attendance != null)
        DashboardKpiItemData(
          label: l10n.dashboardKpiAttendanceRate,
          value: formatDashboardPercent(
            attendance.attendanceRate,
            l10n,
            context,
          ),
          icon: Icons.percent_outlined,
          onTap: () => context.go(RoutePaths.attendance),
        ),
    ],
  );

  final mainColumn = <Widget>[
    if (kpis != null || attendance != null)
      DashboardWorkforceOverview(
        totalEmployees: kpis?.totalEmployees ?? 0,
        activeEmployees: kpis?.activeEmployees ?? 0,
        currentlyWorking: kpis?.employeesCurrentlyWorking ?? 0,
        averageWorkingHoursLabel: attendance == null
            ? '—'
            : formatDashboardHours(
                attendance.averageWorkingHours,
                l10n,
                context,
              ),
        onTap: () => context.go(RoutePaths.attendance),
      ),
    if (overtime != null)
      ...buildDashboardOvertimeItems(
        context: context,
        overtime: overtime,
        hoursOverTime: summary.charts.overtime,
        sectionGap: sectionGap,
      ),
    ..._trendChartsSection(
      context: context,
      l10n: l10n,
      summary: summary,
      sectionGap: sectionGap,
      chartWindowDays: chartWindowDays,
      onChartWindowChanged: onChartWindowChanged,
      asStandaloneSection: true,
    ),
  ];

  final sideColumn = <Widget>[
    if (workOrders != null || pm != null)
      DashboardPanel(
        title: l10n.dashboardOperations,
        trailing: workOrders == null
            ? null
            : IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => context.go(RoutePaths.workOrders),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
              ),
        child: DashboardStatusList(
          items: [
            if (workOrders != null) ...[
              DashboardStatusItem(
                label: l10n.dashboardKpiWoTotal,
                value: '${workOrders.total}',
                onTap: () => context.go(RoutePaths.workOrders),
              ),
              DashboardStatusItem(
                label: l10n.dashboardKpiWoPending,
                value: '${workOrders.pending}',
                color: scheme.tertiary,
              ),
              DashboardStatusItem(
                label: l10n.dashboardKpiWoAssigned,
                value: '${workOrders.assigned}',
                color: scheme.primary,
              ),
              DashboardStatusItem(
                label: l10n.dashboardKpiWoCompleted,
                value: '${workOrders.completed}',
                color: Colors.greenAccent.shade400,
              ),
              DashboardStatusItem(
                label: l10n.dashboardKpiWoCancelled,
                value: '${workOrders.cancelled}',
                color: scheme.outline,
              ),
            ],
            if (pm != null) ...[
              DashboardStatusItem(
                label: l10n.dashboardKpiPmDue,
                value: '${pm.due}',
                color: scheme.secondary,
              ),
              DashboardStatusItem(
                label: l10n.dashboardKpiPmOverdue,
                value: '${pm.overdue}',
                color: scheme.error,
              ),
            ],
          ],
        ),
      ),
    if (inventory != null || assets != null)
      DashboardPanel(
        title: l10n.dashboardResources,
        child: DashboardStatusList(
          items: [
            if (inventory != null) ...[
              DashboardStatusItem(
                label: l10n.dashboardLowStock,
                value: '${inventory.lowStock}',
                color: scheme.error,
                onTap: () => context.go(RoutePaths.inventory),
              ),
              DashboardStatusItem(
                label: l10n.dashboardKpiOutOfStock,
                value: '${inventory.outOfStock}',
                color: scheme.error,
              ),
            ],
            if (assets != null) ...[
              DashboardStatusItem(
                label: l10n.dashboardKpiAssetsTotal,
                value: '${assets.totalAssets}',
              ),
              DashboardStatusItem(
                label: l10n.dashboardKpiAssetsActive,
                value: '${assets.active}',
                color: Colors.greenAccent.shade400,
              ),
              DashboardStatusItem(
                label: l10n.dashboardKpiAssetsMaintenance,
                value: '${assets.underMaintenance}',
                color: scheme.tertiary,
              ),
              DashboardStatusItem(
                label: l10n.dashboardKpiAssetsRetired,
                value: '${assets.retired}',
              ),
            ],
          ],
        ),
      ),
    _notificationsPanel(context: context, l10n: l10n, summary: summary),
  ];

  return [
    kpiStrip,
    SizedBox(height: sectionGap),
    DashboardTwoColumnBody(
      gap: sectionGap,
      main: mainColumn,
      side: sideColumn,
    ),
    ..._quickActionsSection(
      l10n: l10n,
      sectionGap: sectionGap,
      permissions: permissions,
      showQuickActions: showQuickActions,
    ),
  ];
}

List<Widget> _supervisor({
  required BuildContext context,
  required AppLocalizations l10n,
  required RoleDashboardSummary summary,
  required double sectionGap,
  required int chartWindowDays,
  required ValueChanged<int> onChartWindowChanged,
  PermissionChecker? permissions,
  bool showQuickActions = false,
}) {
  final attendance = summary.teamAttendance;
  final overtime = summary.teamOvertime;
  final workOrders = summary.teamWorkOrders;
  final pm = summary.teamPm;
  final inventory = summary.teamInventoryAlerts;
  final performance = summary.teamPerformance;
  final cards = <Widget>[];

  final hero = DashboardHeroMetrics(
      metrics: [
        if (attendance != null)
          DashboardMetric(
            label: l10n.dashboardKpiCurrentlyWorking,
            value: '${attendance.currentlyWorking}',
            icon: Icons.work_outline,
            onTap: () => context.go(RoutePaths.attendance),
          ),
        if (workOrders != null)
          DashboardMetric(
            label: l10n.dashboardKpiWoInProgress,
            value: '${workOrders.inProgress}',
            icon: Icons.play_circle_outline,
            onTap: () => context.go(RoutePaths.workOrders),
          ),
        if (performance != null)
          DashboardMetric(
            label: l10n.dashboardSectionTeamPerformance,
            value: formatDashboardPercent(performance.completionRate, l10n, context),
            icon: Icons.insights_outlined,
          ),
        if (overtime != null)
          DashboardMetric(
            label: l10n.dashboardKpiTotalApprovedHours,
            value: formatDashboardHours(overtime.approvedOvertimeHours, l10n, context),
            icon: Icons.more_time_outlined,
          ),
        if (overtime != null)
          DashboardMetric(
            label: l10n.dashboardKpiTotalOvertimeHours,
            value: formatDashboardHours(overtime.totalOvertimeHours, l10n, context),
            icon: Icons.more_time_outlined,
          ),
      ],
    );

  cards.add(
    DashboardMetricGroupCard(
      title: l10n.dashboardSectionTeamAttendance,
      metrics: [
        if (attendance != null) ...[
          DashboardMetric(
            label: l10n.dashboardKpiTotalWorkingHours,
            value: formatDashboardHours(attendance.totalWorkingHours, l10n, context),
            icon: Icons.schedule_outlined,
            onTap: () => context.go(RoutePaths.attendance),
          ),
          DashboardMetric(
            label: l10n.dashboardKpiCurrentlyWorking,
            value: '${attendance.currentlyWorking}',
            icon: Icons.badge_outlined,
            onTap: () => context.go(RoutePaths.attendance),
          ),
          DashboardMetric(
            label: l10n.dashboardKpiActiveEmployees,
            value: '${attendance.membersPresent}',
            icon: Icons.groups_outlined,
            onTap: () => context.go(RoutePaths.attendance),
          ),
        ],
        if (overtime != null)
          DashboardMetric(
            label: l10n.dashboardKpiTotalApprovedHours,
            value: formatDashboardHours(overtime.approvedOvertimeHours, l10n, context),
            icon: Icons.more_time_outlined,
          ),
        if (overtime != null)
          DashboardMetric(
            label: l10n.dashboardKpiTotalOvertimeHours,
            value: formatDashboardHours(overtime.totalOvertimeHours, l10n, context),
            icon: Icons.more_time_outlined,
          ),
        if (performance != null)
          DashboardMetric(
            label: l10n.dashboardKpiAverageWorkingHours,
            value: formatDashboardHours(performance.averageWorkingHours, l10n, context),
            icon: Icons.av_timer_outlined,
            onTap: () => context.go(RoutePaths.attendance),
          ),
      ],
    ),
  );

  if (workOrders != null || pm != null || inventory != null) {
    cards.add(
      DashboardMetricGroupCard(
        title: l10n.dashboardOperations,
        metrics: [
          if (workOrders != null) ...[
            DashboardMetric(
              label: l10n.dashboardKpiWoTotal,
              value: '${workOrders.total}',
              icon: Icons.assignment_outlined,
              onTap: () => context.go(RoutePaths.workOrders),
            ),
            DashboardMetric(
              label: l10n.dashboardKpiWoPending,
              value: '${workOrders.pending}',
              icon: Icons.hourglass_empty,
            ),
            DashboardMetric(
              label: l10n.dashboardKpiWoAssigned,
              value: '${workOrders.assigned}',
              icon: Icons.person_add_alt_1_outlined,
            ),
            DashboardMetric(
              label: l10n.dashboardKpiWoCompleted,
              value: '${workOrders.completed}',
              icon: Icons.check_circle_outline,
            ),
          ],
          if (pm != null) ...[
            DashboardMetric(
              label: l10n.dashboardKpiPmDue,
              value: '${pm.due}',
              icon: Icons.event_available_outlined,
            ),
            DashboardMetric(
              label: l10n.dashboardKpiPmOverdue,
              value: '${pm.overdue}',
              icon: Icons.event_busy_outlined,
            ),
          ],
          if (inventory != null)
            DashboardMetric(
              label: l10n.dashboardLowStock,
              value: '${inventory.lowStock}',
              icon: Icons.warning_amber_outlined,
              onTap: () => context.go(RoutePaths.inventory),
            ),
        ],
      ),
    );
  }

  return [
    hero,
    SizedBox(height: sectionGap),
    DashboardSectionGrid(gap: sectionGap, children: cards),
    SizedBox(height: sectionGap),
    ..._trendChartsSection(
      context: context,
      l10n: l10n,
      summary: summary,
      sectionGap: sectionGap,
      chartWindowDays: chartWindowDays,
      onChartWindowChanged: onChartWindowChanged,
    ),
    ..._recentNotificationsSection(
      context: context,
      l10n: l10n,
      summary: summary,
      sectionGap: sectionGap,
    ),
    ..._quickActionsSection(
      l10n: l10n,
      sectionGap: sectionGap,
      permissions: permissions,
      showQuickActions: showQuickActions,
    ),
  ];
}

List<Widget> _technician({
  required BuildContext context,
  required AppLocalizations l10n,
  required RoleDashboardSummary summary,
  required double sectionGap,
  required int chartWindowDays,
  required ValueChanged<int> onChartWindowChanged,
  PermissionChecker? permissions,
  bool showQuickActions = false,
}) {
  final attendance = summary.attendance;
  final overtime = summary.overtime;
  final work = summary.work;
  final pm = summary.preventiveMaintenance;
  final location = summary.location;
  final performance = summary.performance;
  final cards = <Widget>[];

  final hero = DashboardHeroMetrics(
      metrics: [
        if (work != null)
          DashboardMetric(
            label: l10n.dashboardKpiWoAssigned,
            value: '${work.assigned}',
            icon: Icons.assignment_ind_outlined,
            onTap: () => context.go(RoutePaths.workOrders),
          ),
        if (work != null)
          DashboardMetric(
            label: l10n.dashboardKpiWoCompleted,
            value: '${work.completed}',
            icon: Icons.check_circle_outline,
          ),
        if (attendance != null)
          DashboardMetric(
            label: l10n.dashboardKpiTotalWorkingHours,
            value: formatDashboardHours(attendance.totalWorkingHours, l10n, context),
            icon: Icons.schedule_outlined,
            onTap: () => context.go(RoutePaths.attendance),
          ),
        if (performance != null)
          DashboardMetric(
            label: l10n.dashboardKpiAttendanceRate,
            value: formatDashboardPercent(performance.attendanceRate, l10n, context),
            icon: Icons.percent_outlined,
            onTap: () => context.go(RoutePaths.attendance),
          ),
      ],
    );

  cards.add(
    DashboardMetricGroupCard(
      title: l10n.dashboardSectionPerformance,
      metrics: [
        if (overtime != null)
          DashboardMetric(
            label: l10n.dashboardKpiTotalApprovedHours,
            value: formatDashboardHours(overtime.approvedOvertimeHours, l10n, context),
            icon: Icons.more_time_outlined,
          ),
        if (overtime != null)
          DashboardMetric(
            label: l10n.dashboardKpiTotalOvertimeHours,
            value: formatDashboardHours(overtime.totalOvertimeHours, l10n, context),
            icon: Icons.more_time_outlined,
          ),
        if (work != null)
          DashboardMetric(
            label: l10n.dashboardKpiWoPending,
            value: '${work.pending}',
            icon: Icons.hourglass_empty,
          ),
        if (pm != null) ...[
          DashboardMetric(
            label: l10n.dashboardKpiPmDue,
            value: '${pm.assignedTasks}',
            icon: Icons.event_available_outlined,
          ),
          DashboardMetric(
            label: l10n.dashboardKpiPmCompleted,
            value: '${pm.completedTasks}',
            icon: Icons.task_alt_outlined,
          ),
        ],
        if (performance != null) ...[
          DashboardMetric(
            label: l10n.dashboardKpiMonthlyOtHours,
            value: formatDashboardHours(performance.monthlyOvertimeHours, l10n, context),
            icon: Icons.insights_outlined,
          ),
          DashboardMetric(
            label: l10n.dashboardKpiAvgCompletionHours,
            value: formatDashboardHours(
              performance.averageCompletionHours,
              l10n,
              context,
            ),
            icon: Icons.timer_outlined,
          ),
        ],
      ],
      footer: location == null
          ? null
          : ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined, size: 20),
              title: Text(
                location.lastKnownAddress ?? l10n.dashboardLocationUnknown,
              ),
              subtitle: location.lastSynchronization == null
                  ? null
                  : Text(
                      l10n.dashboardLastSync(
                        location.lastSynchronization!.toLocal().toString(),
                      ),
                    ),
            ),
    ),
  );

  return [
    hero,
    SizedBox(height: sectionGap),
    DashboardSectionGrid(gap: sectionGap, children: cards),
    SizedBox(height: sectionGap),
    ..._trendChartsSection(
      context: context,
      l10n: l10n,
      summary: summary,
      sectionGap: sectionGap,
      chartWindowDays: chartWindowDays,
      onChartWindowChanged: onChartWindowChanged,
    ),
    ..._recentNotificationsSection(
      context: context,
      l10n: l10n,
      summary: summary,
      sectionGap: sectionGap,
    ),
    ..._quickActionsSection(
      l10n: l10n,
      sectionGap: sectionGap,
      permissions: permissions,
      showQuickActions: showQuickActions,
    ),
  ];
}

List<Widget> _trendChartsSection({
  required BuildContext context,
  required AppLocalizations l10n,
  required RoleDashboardSummary summary,
  required double sectionGap,
  required int chartWindowDays,
  required ValueChanged<int> onChartWindowChanged,
  bool asStandaloneSection = false,
}) {
  final charts = summary.charts;
  final children = <Widget>[];

  final visibleTrends = <Widget>[];
  void addIfTrend(
    String title,
    List<DashboardChartPoint> points, {
    DashboardChartValueKind valueKind = DashboardChartValueKind.generic,
  }) {
    final window = points.length <= chartWindowDays
        ? points
        : points.sublist(points.length - chartWindowDays);
    if (window.length < 2) return;
    final maxV = window.fold<double>(0, (p, e) => e.value > p ? e.value : p);
    if (maxV <= 0) return;
    visibleTrends.add(
      DashboardTrendChart(
        title: title,
        points: points,
        windowDays: chartWindowDays,
        height: asStandaloneSection ? 120 : 140,
        valueKind: valueKind,
      ),
    );
  }

  addIfTrend(l10n.dashboardChartAttendance, charts.attendance);
  addIfTrend(l10n.dashboardChartWorkOrders, charts.workOrders);
  addIfTrend(
    l10n.dashboardChartOvertime,
    charts.overtime,
    valueKind: DashboardChartValueKind.hours,
  );
  addIfTrend(l10n.dashboardChartPm, charts.preventiveMaintenance);

  if (visibleTrends.isEmpty) return const [];

  final segmentedButton = SegmentedButton<int>(
    segments: [
      ButtonSegment(
        value: 7,
        label: Text('7', style: DashboardTypography.windowSelector(context)),
      ),
      ButtonSegment(
        value: 30,
        label: Text('30', style: DashboardTypography.windowSelector(context)),
      ),
    ],
    selected: {chartWindowDays},
    onSelectionChanged: (value) => onChartWindowChanged(value.first),
    style: ButtonStyle(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStatePropertyAll(
        DashboardTypography.windowSelector(context),
      ),
    ),
  );

  final trendGrid = DashboardSectionGrid(
    gap: asStandaloneSection ? AppSpacing.xs : AppSpacing.sm,
    children: visibleTrends,
  );

  if (asStandaloneSection) {
    children.add(
      LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              AppBreakpoints.isDashboardCompact(constraints.maxWidth);
          if (compact) {
            return DashboardPanel(
              title: l10n.dashboardTrends,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: segmentedButton,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  trendGrid,
                ],
              ),
            );
          }
          return DashboardPanel(
            title: l10n.dashboardTrends,
            trailing: segmentedButton,
            child: trendGrid,
          );
        },
      ),
    );
  } else {
    children.add(
      DashboardSection(
        title: l10n.dashboardTrends,
        trailing: segmentedButton,
        child: trendGrid,
      ),
    );
  }

  return children;
}

Widget _notificationsPanel({
  required BuildContext context,
  required AppLocalizations l10n,
  required RoleDashboardSummary summary,
}) {
  final previewItems = summary.notifications
      .where((n) => !isInternalSystemAuditEvent(n.title))
      .map(
        (n) => DashboardFeedItem(
          title: localizeAuditEvent(l10n, n.title),
          subtitle: localizeNotificationBody(l10n, n.body),
          icon: Icons.notifications_outlined,
          onTap: () => context.push(RoutePaths.notifications),
        ),
      )
      .toList(growable: false);

  return DashboardFeedCard(
    title: l10n.dashboardRecentNotifications,
    emptyLabel: l10n.dashboardNoNotifications,
    maxItems: 6,
    onViewAll: () => context.push(RoutePaths.notifications),
    items: previewItems,
  );
}

List<Widget> _recentNotificationsSection({
  required BuildContext context,
  required AppLocalizations l10n,
  required RoleDashboardSummary summary,
  required double sectionGap,
}) {
  final previewItems = summary.notifications
      .where((n) => !isInternalSystemAuditEvent(n.title))
      .map(
        (n) => DashboardFeedItem(
          title: localizeAuditEvent(l10n, n.title),
          subtitle: localizeNotificationBody(l10n, n.body),
          icon: Icons.notifications_outlined,
          onTap: () => context.push(RoutePaths.notifications),
        ),
      )
      .toList(growable: false);

  return [
    SizedBox(height: sectionGap),
    DashboardFeedCard(
      title: l10n.dashboardRecentNotifications,
      emptyLabel: l10n.dashboardNoNotifications,
      maxItems: 5,
      onViewAll: () => context.push(RoutePaths.notifications),
      items: previewItems,
    ),
  ];
}

List<Widget> _quickActionsSection({
  required AppLocalizations l10n,
  required double sectionGap,
  required PermissionChecker? permissions,
  required bool showQuickActions,
}) {
  if (!showQuickActions ||
      !DashboardQuickActionsGrid.hasVisibleActions(permissions)) {
    return const [];
  }

  return [
    SizedBox(height: sectionGap),
    DashboardSection(
      title: l10n.dashboardQuickActions,
      child: DashboardQuickActionsGrid(permissions: permissions),
    ),
  ];
}
