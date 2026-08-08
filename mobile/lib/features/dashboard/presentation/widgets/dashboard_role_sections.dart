import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_audit_event.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_executive_layout.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_metric_group_card.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_overtime_section.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_quick_actions.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_section_grid.dart';
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
  final cards = <Widget>[];

  // Hero: most important live signals first.
  final hero = DashboardHeroMetrics(
      metrics: [
        if (kpis != null)
          DashboardMetric(
            label: l10n.dashboardKpiCurrentlyWorking,
            value: '${kpis.employeesCurrentlyWorking}',
            icon: Icons.work_outline,
            onTap: () => context.go(RoutePaths.attendance),
          ),
        if (kpis != null)
          DashboardMetric(
            label: l10n.dashboardKpiOnOvertime,
            value: '${kpis.employeesOnOvertime}',
            icon: Icons.more_time_outlined,
            onTap: () => context.go(RoutePaths.overtime),
          ),
        if (workOrders != null)
          DashboardMetric(
            label: l10n.dashboardKpiWoInProgress,
            value: '${workOrders.inProgress}',
            icon: Icons.play_circle_outline,
            onTap: () => context.go(RoutePaths.workOrders),
          ),
        if (attendance != null)
          DashboardMetric(
            label: l10n.dashboardKpiAttendanceRate,
            value: formatDashboardPercent(attendance.attendanceRate, l10n, context),
            icon: Icons.percent_outlined,
            onTap: () => context.go(RoutePaths.attendance),
          ),
      ],
    );

  if (kpis != null || attendance != null) {
    cards.add(
      DashboardMetricGroupCard(
        title: l10n.dashboardWorkforce,
        metrics: [
          if (kpis != null) ...[
            DashboardMetric(
              label: l10n.dashboardKpiTotalEmployees,
              value: '${kpis.totalEmployees}',
              icon: Icons.groups_outlined,
            ),
            DashboardMetric(
              label: l10n.dashboardKpiActiveEmployees,
              value: '${kpis.activeEmployees}',
              icon: Icons.badge_outlined,
            ),
          ],
          if (attendance != null) ...[
            DashboardMetric(
              label: l10n.dashboardKpiTotalWorkingHours,
              value: formatDashboardHours(attendance.totalWorkingHours, l10n, context),
              icon: Icons.schedule_outlined,
              onTap: () => context.go(RoutePaths.attendance),
            ),
            DashboardMetric(
              label: l10n.dashboardKpiAverageWorkingHours,
              value: formatDashboardHours(attendance.averageWorkingHours, l10n, context),
              icon: Icons.av_timer_outlined,
              onTap: () => context.go(RoutePaths.attendance),
            ),
          ],
        ],
      ),
    );
  }

  if (workOrders != null || pm != null) {
    cards.add(
      DashboardMetricGroupCard(
        title: l10n.dashboardOperations,
        onHeaderTap: workOrders != null
            ? () => context.go(RoutePaths.workOrders)
            : null,
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
            DashboardMetric(
              label: l10n.dashboardKpiWoCancelled,
              value: '${workOrders.cancelled}',
              icon: Icons.cancel_outlined,
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
        ],
      ),
    );
  }

  if (inventory != null || assets != null) {
    cards.add(
      DashboardMetricGroupCard(
        title: l10n.dashboardResources,
        metrics: [
          if (inventory != null) ...[
            DashboardMetric(
              label: l10n.dashboardLowStock,
              value: '${inventory.lowStock}',
              icon: Icons.warning_amber_outlined,
              onTap: () => context.go(RoutePaths.inventory),
            ),
            DashboardMetric(
              label: l10n.dashboardKpiOutOfStock,
              value: '${inventory.outOfStock}',
              icon: Icons.inventory_2_outlined,
            ),
          ],
          if (assets != null) ...[
            DashboardMetric(
              label: l10n.dashboardKpiAssetsTotal,
              value: '${assets.totalAssets}',
              icon: Icons.precision_manufacturing_outlined,
            ),
            DashboardMetric(
              label: l10n.dashboardKpiAssetsActive,
              value: '${assets.active}',
              icon: Icons.check_circle_outline,
            ),
            DashboardMetric(
              label: l10n.dashboardKpiAssetsMaintenance,
              value: '${assets.underMaintenance}',
              icon: Icons.build_outlined,
            ),
            DashboardMetric(
              label: l10n.dashboardKpiAssetsRetired,
              value: '${assets.retired}',
              icon: Icons.archive_outlined,
            ),
          ],
        ],
        footer: inventory != null && inventory.recentStockMovements.isNotEmpty
            ? Column(
                children: inventory.recentStockMovements
                    .take(3)
                    .map(
                      (m) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.swap_horiz, size: 20),
                        title: Text(m.partName ?? m.sku ?? m.type),
                        trailing: Text('${m.quantityDelta ?? m.quantity ?? ''}'),
                      ),
                    )
                    .toList(),
              )
            : null,
      ),
    );
  }

  return [
    hero,
    SizedBox(height: sectionGap),
    DashboardSectionGrid(gap: sectionGap, children: cards),
    if (overtime != null) ...[
      SizedBox(height: sectionGap),
      // Flattened scroll children so phone ListView can lazy-build tech cards.
      ...buildDashboardOvertimeItems(
        context: context,
        overtime: overtime,
        hoursOverTime: summary.charts.overtime,
        sectionGap: sectionGap,
      ),
    ],
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
}) {
  final charts = summary.charts;
  final children = <Widget>[];

  final visibleTrends = <Widget>[];
  void addIfTrend(String title, List<DashboardChartPoint> points) {
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
      ),
    );
  }

  addIfTrend(l10n.dashboardChartAttendance, charts.attendance);
  addIfTrend(l10n.dashboardChartWorkOrders, charts.workOrders);
  addIfTrend(l10n.dashboardChartOvertime, charts.overtime);
  addIfTrend(l10n.dashboardChartPm, charts.preventiveMaintenance);

  if (visibleTrends.isEmpty) return const [];

  children.add(
    DashboardSection(
      title: l10n.dashboardTrends,
      trailing: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 7, label: Text('7')),
          ButtonSegment(value: 30, label: Text('30')),
        ],
        selected: {chartWindowDays},
        onSelectionChanged: (value) => onChartWindowChanged(value.first),
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      child: DashboardSectionGrid(
        gap: AppSpacing.sm,
        children: visibleTrends,
      ),
    ),
  );

  return children;
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
