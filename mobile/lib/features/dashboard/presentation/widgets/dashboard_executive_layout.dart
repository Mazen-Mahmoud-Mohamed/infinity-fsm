import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_metric_group_card.dart';

/// Trend chart that only renders when there is a meaningful multi-day series.
class DashboardTrendChart extends StatelessWidget {
  const DashboardTrendChart({
    super.key,
    required this.title,
    required this.points,
    this.windowDays = 30,
    this.height = 140,
  });

  final String title;
  final List<DashboardChartPoint> points;
  final int windowDays;
  final double height;

  List<DashboardChartPoint> get _windowed {
    if (points.isEmpty) return const [];
    if (points.length <= windowDays) return points;
    return points.sublist(points.length - windowDays);
  }

  bool get _hasTrend {
    final series = _windowed;
    if (series.length < 2) return false;
    final values = series.map((p) => p.value).toList();
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    return maxV > 0 && (maxV - minV > 0 || series.any((p) => p.value > 0));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasTrend) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final series = _windowed;
    final maxValue = series.fold<double>(
      0,
      (prev, p) => p.value > prev ? p.value : prev,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)
                      .dashboardChartWindowDays(windowDays),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: height,
              child: CustomPaint(
                painter: _TrendLinePainter(
                  values: series.map((p) => p.value).toList(),
                  maxValue: maxValue <= 0 ? 1 : maxValue,
                  lineColor: colorScheme.primary,
                  fillColor: colorScheme.primary.withValues(alpha: 0.12),
                  gridColor: colorScheme.outlineVariant,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  series.first.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  series.last.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  _TrendLinePainter({
    required this.values,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<double> values;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * (i / (values.length - 1));
      final y = size.height - (values[i] / maxValue) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastX = values.length == 1
        ? size.width / 2
        : size.width;
    final lastY =
        size.height - (values.last / maxValue) * size.height;
    canvas.drawCircle(
      Offset(lastX, lastY),
      3.5,
      Paint()..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor;
  }
}

/// Compact feed list (activity / notifications) with optional View All.
class DashboardFeedCard extends StatelessWidget {
  const DashboardFeedCard({
    super.key,
    required this.title,
    required this.items,
    required this.emptyLabel,
    this.onViewAll,
    this.maxItems = 5,
  });

  final String title;
  final List<DashboardFeedItem> items;
  final String emptyLabel;
  final VoidCallback? onViewAll;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final visible = items.take(maxItems).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onViewAll != null && items.isNotEmpty)
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(l10n.dashboardViewAll),
                  ),
              ],
            ),
          ),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text(
                emptyLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...visible.map(
              (item) => ListTile(
                dense: true,
                leading: Icon(item.icon ?? Icons.circle_outlined, size: 20),
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: item.subtitle == null
                    ? null
                    : Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                onTap: item.onTap,
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

class DashboardFeedItem {
  const DashboardFeedItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
}

/// Hero strip: most important KPIs in a single shared card (2-column grid).
class DashboardHeroMetrics extends StatelessWidget {
  const DashboardHeroMetrics({super.key, required this.metrics});

  final List<DashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return DashboardMetricGroupCard(
      title: l10n.dashboardKeyMetrics,
      metrics: metrics,
    );
  }
}
