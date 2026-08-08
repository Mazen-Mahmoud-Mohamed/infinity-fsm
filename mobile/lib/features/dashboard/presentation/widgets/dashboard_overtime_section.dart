import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_dense_widgets.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_mini_chart.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_role_sections.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_typography.dart';

/// Cohesive overtime analytics block (KPI strip + charts + technician table).
List<Widget> buildDashboardOvertimeItems({
  required BuildContext context,
  required DashboardOvertimeSummary overtime,
  required List<DashboardChartPoint> hoursOverTime,
  required double sectionGap,
}) {
  final l10n = AppLocalizations.of(context);

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

  return [
    DashboardPanel(
      title: l10n.dashboardOvertimeAnalytics,
      trailing: IconButton(
        tooltip: l10n.overtime,
        visualDensity: VisualDensity.compact,
        onPressed: () => context.go(RoutePaths.overtime),
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OvertimeKpiRow(overtime: overtime),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 720;
              final charts = <Widget>[
                DashboardMiniChart(
                  title: l10n.dashboardChartHoursPerTechnician,
                  height: 150,
                  embedded: true,
                  points: hoursPoints,
                ),
                DashboardMiniChart(
                  title: l10n.dashboardChartTripsPerTechnician,
                  height: 150,
                  embedded: true,
                  points: tripsPoints,
                ),
                if (hoursOverTime.isNotEmpty)
                  DashboardMiniChart(
                    title: l10n.dashboardChartHoursOverTime,
                    height: 150,
                    embedded: true,
                    points: hoursOverTime,
                  ),
              ];

              if (stacked) {
                return Column(
                  children: [
                    for (var i = 0; i < charts.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      charts[i],
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < charts.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(child: charts[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    ),
    if (overtime.topOvertimeEmployees.isNotEmpty) ...[
      SizedBox(height: sectionGap),
      DashboardTechnicianTable(employees: overtime.topOvertimeEmployees),
    ],
  ];
}

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

class _OvertimeKpiRow extends StatelessWidget {
  const _OvertimeKpiRow({required this.overtime});

  final DashboardOvertimeSummary overtime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final items = [
      (
        l10n.dashboardKpiTotalApprovedHours,
        formatDashboardHours(overtime.totalOvertimeHours, l10n, context),
        Icons.verified_outlined,
      ),
      (
        l10n.dashboardKpiTotalTrips,
        '${overtime.totalTrips}',
        Icons.route_outlined,
      ),
      (
        l10n.dashboardKpiOvernightTrips,
        '${overtime.overnightTrips}',
        Icons.hotel_outlined,
      ),
      (
        l10n.dashboardKpiOtTechnicians,
        '${overtime.totalTechnicians}',
        Icons.groups_outlined,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 640 ? 4 : 2;
            return Wrap(
              children: [
                for (final item in items)
                  SizedBox(
                    width: constraints.maxWidth / cols,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Icon(item.$3, size: 16, color: scheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DashboardTypography.metricValue(context),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.$1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DashboardTypography.kpiLabel(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
