import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';

/// Compact bar chart. Bars are painted via [CustomPaint] (not per-bar widgets)
/// and isolated with [RepaintBoundary] so parent rebuilds stay cheap.
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

    return RepaintBoundary(
      child: Card(
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
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _MiniBarChartPainter(
                      points: points,
                      barColor: colorScheme.primary.withValues(alpha: 0.85),
                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ) ??
                          TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBarChartPainter extends CustomPainter {
  _MiniBarChartPainter({
    required this.points,
    required this.barColor,
    required this.labelStyle,
  });

  final List<DashboardChartPoint> points;
  final Color barColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const labelBand = 28.0;
    final chartHeight = (size.height - labelBand).clamp(4.0, size.height);
    final count = points.length;
    final barWidth = (size.width / count).clamp(8.0, 36.0);
    final totalBars = barWidth * count;
    final gap = ((size.width - totalBars) / (count + 1)).clamp(2.0, 12.0);

    var maxValue = 0.0;
    for (final p in points) {
      if (p.value > maxValue) maxValue = p.value;
    }

    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    var x = gap;
    for (final point in points) {
      final barH = maxValue <= 0
          ? 4.0
          : ((point.value / maxValue) * chartHeight).clamp(4.0, chartHeight);
      final top = chartHeight - barH;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barH),
        const Radius.circular(AppRadius.sm),
      );
      canvas.drawRRect(rect, paint);

      final tp = TextPainter(
        text: TextSpan(text: point.label, style: labelStyle),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth + gap);
      tp.paint(
        canvas,
        Offset(
          x + (barWidth - tp.width) / 2,
          chartHeight + AppSpacing.xs,
        ),
      );

      x += barWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBarChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.barColor != barColor ||
        oldDelegate.labelStyle != labelStyle;
  }
}
