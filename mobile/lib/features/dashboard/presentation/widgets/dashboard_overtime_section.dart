import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_mini_chart.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_role_sections.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_section_grid.dart';

/// Builds overtime analytics as separate scroll children so phone ListViews
/// can lazy-build technician cards (same visual order as before).
List<Widget> buildDashboardOvertimeItems({
  required BuildContext context,
  required DashboardOvertimeSummary overtime,
  required List<DashboardChartPoint> hoursOverTime,
  required double sectionGap,
}) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final width = MediaQuery.sizeOf(context).width;
  final columns = width >= AppBreakpoints.tabletMax
      ? 3
      : width >= AppBreakpoints.phoneMax
          ? 2
          : 1;

  final hoursPoints = overtime.hoursPerTechnician.isNotEmpty
      ? overtime.hoursPerTechnician
      : overtime.topOvertimeEmployees
          .map(
            (e) => DashboardChartPoint(label: e.fullName, value: e.hours),
          )
          .toList(growable: false);
  final tripsPoints = overtime.tripsPerTechnician.isNotEmpty
      ? overtime.tripsPerTechnician
      : overtime.topOvertimeEmployees
          .map(
            (e) => DashboardChartPoint(
              label: e.fullName,
              value: e.trips.toDouble(),
            ),
          )
          .toList(growable: false);

  final items = <Widget>[
    DashboardSection(
      title: l10n.dashboardOvertimeAnalytics,
      trailing: IconButton(
        tooltip: l10n.overtime,
        onPressed: () => context.go(RoutePaths.overtime),
        icon: const Icon(Icons.open_in_new_rounded, size: 20),
      ),
      child: _OvertimeSummaryCards(overtime: overtime),
    ),
  ];

  if (overtime.topOvertimeEmployees.isNotEmpty) {
    items.add(SizedBox(height: sectionGap));
    items.add(
      Text(
        l10n.dashboardTechnicianSummary,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
    items.add(const SizedBox(height: AppSpacing.md));

    if (columns == 1) {
      // Phone: one card per list child → lazy mount while scrolling.
      for (var i = 0; i < overtime.topOvertimeEmployees.length; i++) {
        if (i > 0) items.add(const SizedBox(height: AppSpacing.md));
        final employee = overtime.topOvertimeEmployees[i];
        items.add(
          _TechnicianCard(
            key: ValueKey<String>('ot-tech-${employee.userId}'),
            employee: employee,
          ),
        );
      }
    } else {
      items.add(
        _TechnicianSummaryGrid(
          employees: overtime.topOvertimeEmployees,
          columns: columns,
        ),
      );
    }
  }

  items.add(SizedBox(height: sectionGap));
  items.add(
    DashboardSectionGrid(
      gap: AppSpacing.md,
      children: [
        DashboardMiniChart(
          title: l10n.dashboardChartHoursPerTechnician,
          height: 180,
          points: hoursPoints,
        ),
        DashboardMiniChart(
          title: l10n.dashboardChartTripsPerTechnician,
          height: 180,
          points: tripsPoints,
        ),
        if (hoursOverTime.isNotEmpty)
          DashboardMiniChart(
            title: l10n.dashboardChartHoursOverTime,
            height: 180,
            points: hoursOverTime,
          ),
      ],
    ),
  );

  return items;
}

/// Admin overtime analytics — summary cards, technician cards, charts.
/// Prefer [buildDashboardOvertimeItems] inside scrollable dashboards.
class DashboardOvertimeSection extends StatelessWidget {
  const DashboardOvertimeSection({
    super.key,
    required this.overtime,
    required this.hoursOverTime,
    required this.sectionGap,
  });

  final DashboardOvertimeSummary overtime;
  final List<DashboardChartPoint> hoursOverTime;
  final double sectionGap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buildDashboardOvertimeItems(
        context: context,
        overtime: overtime,
        hoursOverTime: hoursOverTime,
        sectionGap: sectionGap,
      ),
    );
  }
}

class _OvertimeSummaryCards extends StatelessWidget {
  const _OvertimeSummaryCards({required this.overtime});

  final DashboardOvertimeSummary overtime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      _SummaryCardData(
        label: l10n.dashboardKpiTotalApprovedHours,
        value: formatDashboardHours(overtime.totalOvertimeHours, l10n, context),
        icon: Icons.verified_outlined,
      ),
      _SummaryCardData(
        label: l10n.dashboardKpiTotalTrips,
        value: '${overtime.totalTrips}',
        icon: Icons.route_outlined,
      ),
      _SummaryCardData(
        label: l10n.dashboardKpiOvernightTrips,
        value: '${overtime.overnightTrips}',
        icon: Icons.hotel_outlined,
      ),
      _SummaryCardData(
        label: l10n.dashboardKpiOtTechnicians,
        value: '${overtime.totalTechnicians}',
        icon: Icons.groups_outlined,
      ),
      _SummaryCardData(
        label: l10n.dashboardKpiAvgHoursPerTrip,
        value: formatDashboardHours(
          overtime.averageHoursPerTrip,
          l10n,
          context,
        ),
        icon: Icons.av_timer_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= AppBreakpoints.tabletMax
            ? 4
            : width >= AppBreakpoints.phoneMax
                ? 2
                : 1;

        if (columns == 1) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                _OvertimeStatCard(data: items[i]),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += columns) {
          final slice = items.skip(i).take(columns).toList();
          rows.add(
            Padding(
              padding: EdgeInsets.only(
                bottom: i + columns < items.length ? AppSpacing.md : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: j < slice.length
                          ? _OvertimeStatCard(data: slice[j])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _OvertimeStatCard extends StatelessWidget {
  const _OvertimeStatCard({required this.data});

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => context.go(RoutePaths.overtime),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(data.icon, color: scheme.primary, size: 20),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                data.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechnicianSummaryGrid extends StatelessWidget {
  const _TechnicianSummaryGrid({
    required this.employees,
    required this.columns,
  });

  final List<DashboardTopOvertimeEmployee> employees;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < employees.length; i += columns) {
      final slice = employees.skip(i).take(columns).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i + columns < employees.length ? AppSpacing.md : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: j < slice.length
                      ? _TechnicianCard(
                          key: ValueKey<String>('ot-tech-${slice[j].userId}'),
                          employee: slice[j],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({super.key, required this.employee});

  final DashboardTopOvertimeEmployee employee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final metrics = [
      (
        label: l10n.dashboardKpiTotalApprovedHours,
        value: formatDashboardHours(employee.hours, l10n, context),
        icon: Icons.verified_outlined,
      ),
      (
        label: l10n.dashboardKpiTotalTrips,
        value: '${employee.trips}',
        icon: Icons.route_outlined,
      ),
      (
        label: l10n.dashboardKpiOvernightTrips,
        value: '${employee.overnightTrips}',
        icon: Icons.hotel_outlined,
      ),
      (
        label: l10n.dashboardKpiAvgHoursPerTrip,
        value: formatDashboardHours(
          employee.averageHoursPerTrip,
          l10n,
          context,
        ),
        icon: Icons.av_timer_outlined,
      ),
    ];

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline,
                      size: 22,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      employee.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: metrics[0].label,
                          value: metrics[0].value,
                          icon: metrics[0].icon,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MetricTile(
                          label: metrics[1].label,
                          value: metrics[1].value,
                          icon: metrics[1].icon,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: metrics[2].label,
                          value: metrics[2].value,
                          icon: metrics[2].icon,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MetricTile(
                          label: metrics[3].label,
                          value: metrics[3].value,
                          icon: metrics[3].icon,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox(
        height: 84,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: scheme.primary),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
