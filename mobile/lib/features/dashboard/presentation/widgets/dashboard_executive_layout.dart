import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_metric_group_card.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_mini_chart.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_typography.dart';

/// Trend chart that only renders when there is a meaningful multi-day series.
class DashboardTrendChart extends StatelessWidget {
  const DashboardTrendChart({
    super.key,
    required this.title,
    required this.points,
    this.windowDays = 30,
    this.height = 140,
    this.valueKind = DashboardChartValueKind.generic,
  });

  final String title;
  final List<DashboardChartPoint> points;
  final int windowDays;
  final double height;
  final DashboardChartValueKind valueKind;

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

    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final compact =
        AppBreakpoints.isDashboardCompact(MediaQuery.sizeOf(context).width);
    final axisStyle = DashboardTypography.chartAxis(context, compact: compact);
    final series = _windowed;
    final values = List<double>.generate(
      series.length,
      (i) => series[i].value,
      growable: false,
    );
    var maxValue = 0.0;
    for (final v in values) {
      if (v > maxValue) maxValue = v;
    }
    final plotMax = maxValue <= 0 ? 1.0 : maxValue;

    String formatAxis(double value) {
      switch (valueKind) {
        case DashboardChartValueKind.hours:
          return DurationFormatter.compactFromHours(value, l10n);
        case DashboardChartValueKind.count:
          return value.round().toString();
        case DashboardChartValueKind.generic:
          if (value == value.roundToDouble()) return value.round().toString();
          return value.toStringAsFixed(1);
      }
    }

    String formatValue(double value) {
      switch (valueKind) {
        case DashboardChartValueKind.hours:
          return DurationFormatter.fromHours(value, l10n);
        case DashboardChartValueKind.count:
          return value.round().toString();
        case DashboardChartValueKind.generic:
          if (value == value.roundToDouble()) return value.round().toString();
          return value.toStringAsFixed(1);
      }
    }

    final chartHeight = compact ? height + 20 : height;
    final yAxisWidth = compact ? 52.0 : 44.0;
    final yTicks = <double>[plotMax, plotMax / 2, 0];

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: DashboardTypography.chartTitle(context),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)
                        .dashboardChartWindowDays(windowDays),
                    style: DashboardTypography.chartMeta(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (valueKind == DashboardChartValueKind.hours &&
                  values.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    formatValue(values.last),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardTypography.chartTooltipValue(context),
                  ),
                ),
              SizedBox(
                height: chartHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: yAxisWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final tick in yTicks)
                            Text(
                              tick <= 0 ? '' : formatAxis(tick),
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                              softWrap: true,
                              textAlign: TextAlign.end,
                              style: axisStyle,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: _TrendLinePainter(
                          values: values,
                          maxValue: plotMax,
                          lineColor: colorScheme.primary,
                          fillColor:
                              colorScheme.primary.withValues(alpha: 0.12),
                          gridColor: colorScheme.outlineVariant,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      series.first.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: axisStyle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      series.last.label,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: axisStyle,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final visible = items.take(maxItems).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: DashboardTypography.sectionTitle(context),
                  ),
                ),
                if (onViewAll != null && items.isNotEmpty)
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: DashboardTypography.windowSelector(context),
                    ),
                    child: Text(l10n.dashboardViewAll),
                  ),
              ],
            ),
          ),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text(
                emptyLabel,
                style: DashboardTypography.secondary(context),
              ),
            )
          else
            ...visible.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      indent: 48,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  InkWell(
                    onTap: item.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.icon ?? Icons.notifications_outlined,
                              size: 16,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DashboardTypography.feedTitle(context),
                                ),
                                if (item.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: DashboardTypography.secondary(context),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
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
