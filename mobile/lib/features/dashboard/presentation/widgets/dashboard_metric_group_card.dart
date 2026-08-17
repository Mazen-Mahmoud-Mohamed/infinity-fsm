import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_typography.dart';

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;
}

/// One Material card that hosts several related metrics (2-column on phones).
class DashboardMetricGroupCard extends StatelessWidget {
  const DashboardMetricGroupCard({
    super.key,
    required this.title,
    required this.metrics,
    this.subtitle,
    this.onHeaderTap,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final List<DashboardMetric> metrics;
  final VoidCallback? onHeaderTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onHeaderTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: DashboardTypography.sectionTitle(context),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: DashboardTypography.secondary(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onHeaderTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    AppBreakpoints.isDashboardCompact(constraints.maxWidth);
                final columns = compact
                    ? 1
                    : constraints.maxWidth >= 720
                        ? 4
                        : constraints.maxWidth >= 480
                            ? 3
                            : 2;
                final rows = <Widget>[];
                for (var i = 0; i < metrics.length; i += columns) {
                  final slice = metrics.skip(i).take(columns).toList();
                  // Avoid IntrinsicHeight (2× layout cost on every rebuild).
                  rows.add(
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i + columns < metrics.length ? AppSpacing.sm : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var j = 0; j < columns; j++) ...[
                            if (j > 0) const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: j < slice.length
                                  ? _MetricCell(
                                      metric: slice[j],
                                      compact: compact,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return Column(children: rows);
              },
            ),
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric, this.compact = false});

  final DashboardMetric metric;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: compact ? 64 : 72),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
          vertical: compact ? AppSpacing.xs : AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metric.icon != null) ...[
                  Icon(
                    metric.icon,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    metric.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardTypography.kpiLabel(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              metric.value,
              maxLines: compact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: DashboardTypography.metricValue(context),
            ),
          ],
        ),
      ),
    );

    if (metric.onTap == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: content,
      );
    }

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: metric.onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: content,
      ),
    );
  }
}
