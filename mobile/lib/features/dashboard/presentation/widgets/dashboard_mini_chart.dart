import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';

class DashboardMiniChart extends StatelessWidget {
  const DashboardMiniChart({
    super.key,
    required this.title,
    required this.points,
    this.height = 160,
  });

  final String title;
  final List<DashboardChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final maxValue = points.fold<double>(
      0,
      (prev, p) => p.value > prev ? p.value : prev,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (points.isEmpty)
              SizedBox(
                height: height,
                child: Center(
                  child: Text(
                    l10n.dashboardChartEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = (constraints.maxWidth / points.length)
                        .clamp(8.0, 36.0);
                    final gap = (constraints.maxWidth -
                            (barWidth * points.length)) /
                        (points.length + 1);
                    final chartHeight = constraints.maxHeight - 28;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < points.length; i++) ...[
                          SizedBox(width: gap.clamp(2.0, 12.0)),
                          SizedBox(
                            width: barWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: barWidth,
                                      height: maxValue <= 0
                                          ? 4
                                          : ((points[i].value / maxValue) *
                                                  chartHeight)
                                              .clamp(4.0, chartHeight),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.sm,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  points[i].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(width: gap.clamp(2.0, 12.0)),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
