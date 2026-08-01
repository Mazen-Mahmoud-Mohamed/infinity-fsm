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
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_section.dart';

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
      );
    case DashboardViewRole.supervisor:
      return _supervisor(
        context: context,
        l10n: l10n,
        summary: summary,
        sectionGap: sectionGap,
        chartWindowDays: chartWindowDays,
        onChartWindowChanged: onChartWindowChanged,
      );
    case DashboardViewRole.technician:
      return _technician(
        context: context,
        l10n: l10n,
        summary: summary,
        sectionGap: sectionGap,
        chartWindowDays: chartWindowDays,
        onChartWindowChanged: onChartWindowChanged,
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
}) {
  final kpis = summary.kpis;
  final attendance = summary.attendance;
  final overtime = summary.overtime;
  final workOrders = summary.workOrders;
  final pm = summary.preventiveMaintenance;
  final inventory = summary.inventory;
  final assets = summary.assets;
  final children = <Widget>[];

  // Hero: most important live signals first.
  children.add(
    DashboardHeroMetrics(
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
            value: '${kpis.employeesOnOvertime + kpis.employeesOnTravelOvertime}',
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
    ),
  );
  children.add(SizedBox(height: sectionGap));

  if (kpis != null || attendance != null || overtime != null) {
    children.add(
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
            DashboardMetric(
              label: l10n.dashboardKpiOnTravelOt,
              value: '${kpis.employeesOnTravelOvertime}',
              icon: Icons.flight_takeoff_outlined,
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
          if (overtime != null) ...[
            DashboardMetric(
              label: l10n.dashboardKpiOtHours,
              value: formatDashboardHours(overtime.totalOvertimeHours, l10n, context),
              icon: Icons.more_time_outlined,
              onTap: () => context.go(RoutePaths.overtime),
            ),
            DashboardMetric(
              label: l10n.dashboardKpiTravelOtHours,
              value:
                  formatDashboardHours(overtime.totalTravelOvertimeHours, l10n, context),
              icon: Icons.flight_outlined,
            ),
          ],
        ],
        footer: overtime != null && overtime.topOvertimeEmployees.isNotEmpty
            ? Column(
                children: overtime.topOvertimeEmployees
                    .take(3)
                    .map(
                      (e) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline, size: 20),
                        title: Text(e.fullName),
                        trailing: Text(formatDashboardHours(e.hours, l10n, context)),
                      ),
                    )
                    .toList(),
              )
            : null,
      ),
    );
    children.add(SizedBox(height: sectionGap));
  }

  if (workOrders != null || pm != null) {
    children.add(
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
    children.add(SizedBox(height: sectionGap));
  }

  if (inventory != null || assets != null) {
    children.add(
      DashboardMetricGroupCard(
        title: l10n.dashboardResources,
        metrics: [
          if (inventory != null) ...[
            DashboardMetric(
              label: l10n.dashboardLowStock,
              value: '${inventory.lowStock}',
              icon: Icons.warning_amber_outlined,
              onTap: () => context.push(RoutePaths.inventory),
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
    children.add(SizedBox(height: sectionGap));
  }

  children.addAll(
    _trendsAndFeeds(
      context: context,
      l10n: l10n,
      summary: summary,
      sectionGap: sectionGap,
      chartWindowDays: chartWindowDays,
      onChartWindowChanged: onChartWindowChanged,
    ),
  );

  return children;
}

List<Widget> _supervisor({
  required BuildContext context,
  required AppLocalizations l10n,
  required RoleDashboardSummary summary,
  required double sectionGap,
  required int chartWindowDays,
  required ValueChanged<int> onChartWindowChanged,
}) {
  final attendance = summary.teamAttendance;
  final overtime = summary.teamOvertime;
  final workOrders = summary.teamWorkOrders;
  final pm = summary.teamPm;
  final inventory = summary.teamInventoryAlerts;
  final performance = summary.teamPerformance;
  final children = <Widget>[];

  children.add(
    DashboardHeroMetrics(
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
            label: l10n.dashboardKpiOtHours,
            value: formatDashboardHours(overtime.totalOvertimeHours, l10n, context),
            icon: Icons.more_time_outlined,
          ),
      ],
    ),
  );
  children.add(SizedBox(height: sectionGap));

  children.add(
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
        if (overtime != null) ...[
          DashboardMetric(
            label: l10n.dashboardKpiOtHours,
            value: formatDashboardHours(overtime.totalOvertimeHours, l10n, context),
            icon: Icons.more_time_outlined,
          ),
          DashboardMetric(
            label: l10n.dashboardKpiTravelOtHours,
            value:
                formatDashboardHours(overtime.totalTravelOvertimeHours, l10n, context),
            icon: Icons.flight_outlined,
          ),
        ],
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
  children.add(SizedBox(height: sectionGap));

  if (workOrders != null || pm != null || inventory != null) {
    children.add(
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
              onTap: () => context.push(RoutePaths.inventory),
            ),
        ],
      ),
    );
    children.add(SizedBox(height: sectionGap));
  }

  children.addAll(
    _trendsAndFeeds(
      context: context,
      l10n: l10n,
      summary: summary,
      sectionGap: sectionGap,
      chartWindowDays: chartWindowDays,
      onChartWindowChanged: onChartWindowChanged,
      activityOverride: summary.teamActivity,
    ),
  );

  return children;
}

List<Widget> _technician({
  required BuildContext context,
  required AppLocalizations l10n,
  required RoleDashboardSummary summary,
  required double sectionGap,
  required int chartWindowDays,
  required ValueChanged<int> onChartWindowChanged,
}) {
  final attendance = summary.attendance;
  final overtime = summary.overtime;
  final work = summary.work;
  final pm = summary.preventiveMaintenance;
  final location = summary.location;
  final performance = summary.performance;
  final children = <Widget>[];

  children.add(
    DashboardHeroMetrics(
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
    ),
  );
  children.add(SizedBox(height: sectionGap));

  children.add(
    DashboardMetricGroupCard(
      title: l10n.dashboardSectionPerformance,
      metrics: [
        if (overtime != null) ...[
          DashboardMetric(
            label: l10n.dashboardKpiOtHours,
            value: formatDashboardHours(overtime.totalOvertimeHours, l10n, context),
            icon: Icons.more_time_outlined,
          ),
          DashboardMetric(
            label: l10n.dashboardKpiTravelOtHours,
            value:
                formatDashboardHours(overtime.totalTravelOvertimeHours, l10n, context),
            icon: Icons.flight_outlined,
          ),
        ],
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
  children.add(SizedBox(height: sectionGap));

  children.addAll(
    _trendsAndFeeds(
      context: context,
      l10n: l10n,
      summary: summary,
      sectionGap: sectionGap,
      chartWindowDays: chartWindowDays,
      onChartWindowChanged: onChartWindowChanged,
      includeActivity: false,
    ),
  );

  return children;
}

List<Widget> _trendsAndFeeds({
  required BuildContext context,
  required AppLocalizations l10n,
  required RoleDashboardSummary summary,
  required double sectionGap,
  required int chartWindowDays,
  required ValueChanged<int> onChartWindowChanged,
  List<DashboardLiveActivityItem>? activityOverride,
  bool includeActivity = true,
}) {
  final charts = summary.charts;
  final activity = activityOverride ?? summary.liveActivity;
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

  if (visibleTrends.isNotEmpty) {
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
        child: Column(
          children: [
            for (var i = 0; i < visibleTrends.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              visibleTrends[i],
            ],
          ],
        ),
      ),
    );
    children.add(SizedBox(height: sectionGap));
  }

  if (includeActivity || summary.notifications.isNotEmpty) {
    children.add(
      LayoutBuilder(
        builder: (context, constraints) {
          final feeds = <Widget>[
            if (includeActivity)
              DashboardFeedCard(
                title: l10n.dashboardSectionLiveActivity,
                emptyLabel: l10n.dashboardNoLiveActivity,
                maxItems: 5,
                onViewAll: activity.isEmpty
                    ? null
                    : () => _showFeedSheet(
                          context,
                          title: l10n.dashboardSectionLiveActivity,
                          items: activity
                              .map(
                                (e) => DashboardFeedItem(
                                  title: localizeAuditEvent(l10n, e.action),
                                  subtitle: localizeAuditFeedSubtitle(
                                    l10n,
                                    module: e.module,
                                    actorName: e.actorName,
                                  ),
                                  icon: Icons.history,
                                ),
                              )
                              .toList(),
                        ),
                items: activity
                    .map(
                      (e) => DashboardFeedItem(
                        title: localizeAuditEvent(l10n, e.action),
                        subtitle: localizeAuditFeedSubtitle(
                          l10n,
                          module: e.module,
                          actorName: e.actorName,
                        ),
                        icon: Icons.history,
                      ),
                    )
                    .toList(),
              ),
            DashboardFeedCard(
              title: l10n.dashboardRecentNotifications,
              emptyLabel: l10n.dashboardNoNotifications,
              maxItems: 5,
              onViewAll: () => context.push(RoutePaths.notifications),
              items: summary.notifications
                  .map(
                    (n) => DashboardFeedItem(
                      title: localizeAuditEvent(l10n, n.title),
                      subtitle: _localizeNotificationBody(l10n, n.body),
                      icon: Icons.notifications_outlined,
                      onTap: () => context.push(RoutePaths.notifications),
                    ),
                  )
                  .toList(),
            ),
          ];

          if (constraints.maxWidth >= 700) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < feeds.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(child: feeds[i]),
                ],
              ],
            );
          }

          return Column(
            children: [
              for (var i = 0; i < feeds.length; i++) ...[
                if (i > 0) SizedBox(height: sectionGap),
                feeds[i],
              ],
            ],
          );
        },
      ),
    );
  }

  return children;
}

String _localizeNotificationBody(AppLocalizations l10n, String? body) {
  final raw = (body ?? '').trim();
  if (raw.isEmpty) return l10n.eventGenericActivity;

  final separator = raw.contains(' · ') ? ' · ' : (raw.contains('·') ? '·' : null);
  if (separator != null) {
    final parts = raw.split(separator);
    if (parts.length >= 2) {
      final module = parts.first.trim();
      final actor = parts.sublist(1).join(separator).trim();
      return localizeAuditFeedSubtitle(
        l10n,
        module: module,
        actorName: actor,
      );
    }
  }

  return localizeAuditEvent(l10n, raw);
}

void _showFeedSheet(
  BuildContext context, {
  required String title,
  required List<DashboardFeedItem> items,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            ...items.map(
              (item) => ListTile(
                leading: Icon(item.icon ?? Icons.circle_outlined),
                title: Text(item.title),
                subtitle: item.subtitle == null ? null : Text(item.subtitle!),
              ),
            ),
          ],
        ),
      );
    },
  );
}
