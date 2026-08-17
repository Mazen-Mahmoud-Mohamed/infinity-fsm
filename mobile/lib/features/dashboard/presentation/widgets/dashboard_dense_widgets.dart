import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_role_sections.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_typography.dart';

EdgeInsets _dashboardPanelPadding(BuildContext context) {
  return AppBreakpoints.isDashboardCompactOf(context)
      ? const EdgeInsets.all(AppSpacing.sm)
      : const EdgeInsets.all(AppSpacing.md);
}

/// Compact top-of-dashboard welcome + period host.
class DashboardPageHeader extends StatelessWidget {
  const DashboardPageHeader({
    super.key,
    required this.userName,
    required this.periodSelector,
  });

  final String userName;
  final Widget periodSelector;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: DashboardTypography.welcome(context),
                  children: [
                    TextSpan(text: '${l10n.welcomeBack}, '),
                    TextSpan(
                      text: userName,
                      style: DashboardTypography.welcomeName(context),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        periodSelector,
      ],
    );
  }
}

class DashboardKpiItemData {
  const DashboardKpiItemData({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? accent;
}

/// Dense KPI strip — 4–5 metrics, minimal nesting.
class DashboardKpiStrip extends StatelessWidget {
  const DashboardKpiStrip({super.key, required this.items});

  final List<DashboardKpiItemData> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final wide = width >= AppBreakpoints.tabletMax;
          final compact = AppBreakpoints.isDashboardCompact(width);
          final columns = wide
              ? items.length.clamp(1, 5)
              : compact
                  ? (width < 360 ? 1 : 2)
                  : 3;
          final horizontalPad = compact ? AppSpacing.xs : AppSpacing.sm;
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPad,
              vertical: compact ? AppSpacing.xs : AppSpacing.sm,
            ),
            child: Wrap(
              spacing: 0,
              runSpacing: AppSpacing.xs,
              children: [
                for (var i = 0; i < items.length; i++)
                  SizedBox(
                    width: (width - horizontalPad * 2) / columns,
                    child: _KpiTile(
                      item: items[i],
                      showDivider: i > 0 && wide,
                      compact: compact,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.item,
    required this.showDivider,
    this.compact = false,
  });

  final DashboardKpiItemData item;
  final bool showDivider;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = item.accent ?? scheme.primary;

    final child = InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
          vertical: compact ? AppSpacing.xs : AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDivider)
              Container(
                width: 1,
                height: 36,
                margin: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            Container(
              width: compact ? 30 : 34,
              height: compact ? 30 : 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(item.icon, size: compact ? 16 : 18, color: accent),
            ),
            SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.value,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardTypography.kpiValue(context),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardTypography.kpiLabel(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return child;
  }
}

/// Single panel surface — avoids card-in-card nesting.
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final panelPadding = padding == const EdgeInsets.all(AppSpacing.md)
        ? _dashboardPanelPadding(context)
        : padding;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: panelPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: DashboardTypography.sectionTitle(context),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class DashboardStatusItem {
  const DashboardStatusItem({
    required this.label,
    required this.value,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;
}

/// Compact status rows for operations / alerts.
class DashboardStatusList extends StatelessWidget {
  const DashboardStatusList({super.key, required this.items});

  final List<DashboardStatusItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          InkWell(
            onTap: items[i].onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: items[i].color ?? scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      items[i].label,
                      style: DashboardTypography.listLabel(context),
                    ),
                  ),
                  Text(
                    items[i].value,
                    style: DashboardTypography.listValue(
                      context,
                      color: items[i].color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact workforce overview with progress bar for active share.
class DashboardWorkforceOverview extends StatelessWidget {
  const DashboardWorkforceOverview({
    super.key,
    required this.totalEmployees,
    required this.activeEmployees,
    required this.currentlyWorking,
    required this.averageWorkingHoursLabel,
    this.onTap,
  });

  final int totalEmployees;
  final int activeEmployees;
  final int currentlyWorking;
  final String averageWorkingHoursLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ratio = totalEmployees <= 0
        ? 0.0
        : (currentlyWorking / totalEmployees).clamp(0.0, 1.0);

    return DashboardPanel(
      title: l10n.dashboardWorkforce,
      trailing: onTap == null
          ? null
          : IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onTap,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
            ),
      child: Column(
        children: [
          if (AppBreakpoints.isDashboardCompactOf(context))
            _WorkforceMetricsGrid(
              totalEmployees: totalEmployees,
              activeEmployees: activeEmployees,
              currentlyWorking: currentlyWorking,
              averageWorkingHoursLabel: averageWorkingHoursLabel,
              totalLabel: l10n.dashboardKpiTotalEmployees,
              activeLabel: l10n.dashboardKpiActiveEmployees,
              workingLabel: l10n.dashboardKpiCurrentlyWorking,
              averageLabel: l10n.dashboardKpiAverageWorkingHours,
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: l10n.dashboardKpiTotalEmployees,
                        value: '$totalEmployees',
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: l10n.dashboardKpiActiveEmployees,
                        value: '$activeEmployees',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: l10n.dashboardKpiCurrentlyWorking,
                        value: '$currentlyWorking',
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: l10n.dashboardKpiAverageWorkingHours,
                        value: averageWorkingHoursLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          SizedBox(
            height: AppBreakpoints.isDashboardCompactOf(context)
                ? AppSpacing.sm
                : AppSpacing.md,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.dashboardPercentValue(
                formatDashboardNum(ratio * 100, context),
              ),
              style: DashboardTypography.secondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DashboardTypography.metricValue(context),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DashboardTypography.kpiLabel(context),
          ),
        ],
      ),
    );
  }
}

/// Compact 2×2 workforce metrics for mobile dashboard cards.
class _WorkforceMetricsGrid extends StatelessWidget {
  const _WorkforceMetricsGrid({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.currentlyWorking,
    required this.averageWorkingHoursLabel,
    required this.totalLabel,
    required this.activeLabel,
    required this.workingLabel,
    required this.averageLabel,
  });

  final int totalEmployees;
  final int activeEmployees;
  final int currentlyWorking;
  final String averageWorkingHoursLabel;
  final String totalLabel;
  final String activeLabel;
  final String workingLabel;
  final String averageLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _WorkforceMetricCell(
                icon: Icons.groups_outlined,
                value: '$totalEmployees',
                label: totalLabel,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _WorkforceMetricCell(
                icon: Icons.people_alt_outlined,
                value: '$activeEmployees',
                label: activeLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _WorkforceMetricCell(
                icon: Icons.work_outline,
                value: '$currentlyWorking',
                label: workingLabel,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _WorkforceMetricCell(
                icon: Icons.schedule_outlined,
                value: averageWorkingHoursLabel,
                label: averageLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WorkforceMetricCell extends StatelessWidget {
  const _WorkforceMetricCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 15, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DashboardTypography.metricValue(context).copyWith(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: DashboardTypography.kpiLabel(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Technician summary as compact rows (not giant cards).
class DashboardTechnicianTable extends StatelessWidget {
  const DashboardTechnicianTable({
    super.key,
    required this.employees,
    this.maxHeight = 280,
  });

  final List<DashboardTopOvertimeEmployee> employees;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final compact = AppBreakpoints.isDashboardCompactOf(context);

    if (employees.isEmpty) return const SizedBox.shrink();

    return DashboardPanel(
      title: l10n.dashboardTechnicianSummary,
      padding: compact
          ? const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            )
          : const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
      child: compact
          ? ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: employees.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final e = employees[index];
                return _TechnicianSummaryCard(
                  employee: e,
                  l10n: l10n,
                  scheme: scheme,
                );
              },
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          l10n.labelName,
                          style: DashboardTypography.tableHeader(context),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _wrapHeaderAtWords(l10n.dashboardKpiTotalApprovedHours),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style: DashboardTypography.tableHeader(context),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          _wrapHeaderAtWords(l10n.dashboardKpiTotalTrips),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style: DashboardTypography.tableHeader(context),
                        ),
                      ),
                      SizedBox(
                        width: 76,
                        child: Text(
                          _wrapHeaderAtWords(l10n.dashboardKpiOvernightTrips),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style: DashboardTypography.tableHeader(context),
                        ),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: employees.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    itemBuilder: (context, index) {
                      final e = employees[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  scheme.primary.withValues(alpha: 0.15),
                              child: Text(
                                e.fullName.trim().isNotEmpty
                                    ? e.fullName.trim()[0].toUpperCase()
                                    : '?',
                                style: DashboardTypography.tableHeader(context)
                                    .copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.fullName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        DashboardTypography.tableName(context),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${l10n.dashboardKpiAvgHoursPerTrip}: ${formatDashboardHours(e.averageHoursPerTrip, l10n, context)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        DashboardTypography.secondary(context),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                formatDashboardHours(e.hours, l10n, context),
                                textAlign: TextAlign.end,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    DashboardTypography.tableValue(context),
                              ),
                            ),
                            SizedBox(
                              width: 56,
                              child: Text(
                                '${e.trips}',
                                textAlign: TextAlign.end,
                                style:
                                    DashboardTypography.tableValue(context),
                              ),
                            ),
                            SizedBox(
                              width: 76,
                              child: Text(
                                '${e.overnightTrips}',
                                textAlign: TextAlign.end,
                                style: DashboardTypography.tableValue(
                                  context,
                                  color: e.overnightTrips > 0
                                      ? scheme.tertiary
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _TechnicianSummaryCard extends StatelessWidget {
  const _TechnicianSummaryCard({
    required this.employee,
    required this.l10n,
    required this.scheme,
  });

  final DashboardTopOvertimeEmployee employee;
  final AppLocalizations l10n;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    employee.fullName.trim().isNotEmpty
                        ? employee.fullName.trim()[0].toUpperCase()
                        : '?',
                    style: DashboardTypography.tableHeader(context).copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    employee.fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardTypography.tableName(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _TechnicianStatRow(
              label: l10n.dashboardKpiTotalApprovedHours,
              value: formatDashboardHours(employee.hours, l10n, context),
            ),
            _TechnicianStatRow(
              label: l10n.dashboardKpiTotalTrips,
              value: '${employee.trips}',
            ),
            _TechnicianStatRow(
              label: l10n.dashboardKpiOvernightTrips,
              value: '${employee.overnightTrips}',
              valueColor:
                  employee.overnightTrips > 0 ? scheme.tertiary : null,
            ),
            _TechnicianStatRow(
              label: l10n.dashboardKpiAvgHoursPerTrip,
              value: formatDashboardHours(
                employee.averageHoursPerTrip,
                l10n,
                context,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicianStatRow extends StatelessWidget {
  const _TechnicianStatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: DashboardTypography.secondary(context),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DashboardTypography.tableValue(context, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive two-column shell for desktop/tablet dashboards.
class DashboardTwoColumnBody extends StatelessWidget {
  const DashboardTwoColumnBody({
    super.key,
    required this.main,
    required this.side,
    this.gap = AppSpacing.md,
  });

  final List<Widget> main;
  final List<Widget> side;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns =
            constraints.maxWidth > AppBreakpoints.dashboardCompactMax;
        if (!useColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._spaced(main, gap),
              if (side.isNotEmpty) ...[
                SizedBox(height: gap),
                ..._spaced(side, gap),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _spaced(main, gap),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _spaced(side, gap),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _spaced(List<Widget> widgets, double gap) {
    if (widgets.isEmpty) return const [];
    final out = <Widget>[widgets.first];
    for (var i = 1; i < widgets.length; i++) {
      out.add(SizedBox(height: gap));
      out.add(widgets[i]);
    }
    return out;
  }
}

/// Prefer wrapping multi-word headers at word boundaries (avoids "Overni/ght").
String _wrapHeaderAtWords(String label) {
  final parts = label.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return label;
  return '${parts.first}\n${parts.sublist(1).join(' ')}';
}
