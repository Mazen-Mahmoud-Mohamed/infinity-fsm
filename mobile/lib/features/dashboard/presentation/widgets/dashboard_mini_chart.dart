import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_typography.dart';

typedef DashboardChartValueFormatter = String Function(double value);

/// How bar chart values are presented (numeric [points] are never changed).
enum DashboardChartValueKind {
  /// Integer / decimal fallback.
  generic,

  /// Decimal hours → human-readable duration via [DurationFormatter].
  hours,

  /// Whole counts (trips, items, …).
  count,
}

String _defaultFormatValue(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

/// Shared LTR plot geometry for bars and X-axis labels.
///
/// Both [CustomPainter] bar centers and label [Positioned] widgets must derive
/// positions from this helper so they share one coordinate system.
@visibleForTesting
class DashboardBarChartGeometry {
  const DashboardBarChartGeometry({
    required this.plotWidth,
    required this.barCount,
  });

  final double plotWidth;
  final int barCount;

  double get slotWidth => barCount <= 0 ? 0 : plotWidth / barCount;

  double barCenterX(int index) => (index + 0.5) * slotWidth;

  int indexForLocalDx(double dx) {
    if (barCount <= 0 || plotWidth <= 0) return 0;
    return (dx / plotWidth * barCount).floor().clamp(0, barCount - 1);
  }
}

/// Compact bar chart with readable labels and tap tooltip.
class DashboardMiniChart extends StatefulWidget {
  const DashboardMiniChart({
    super.key,
    required this.title,
    required this.points,
    this.height = 150,
    this.embedded = false,
    this.valueKind = DashboardChartValueKind.generic,
    this.formatValue,
    this.formatAxisValue,
  });

  final String title;
  final List<DashboardChartPoint> points;
  final double height;
  final bool embedded;

  /// Preferred presentation mode — ensures [DurationFormatter] even without callbacks.
  final DashboardChartValueKind valueKind;

  /// Optional override for tooltip / selection text.
  final DashboardChartValueFormatter? formatValue;

  /// Optional override for Y-axis tick labels.
  final DashboardChartValueFormatter? formatAxisValue;

  @override
  State<DashboardMiniChart> createState() => _DashboardMiniChartState();
}

class _DashboardMiniChartState extends State<DashboardMiniChart> {
  int? _selected;

  bool get _compact {
    final width = MediaQuery.sizeOf(context).width;
    return AppBreakpoints.isDashboardCompact(width);
  }

  bool _isRtlLabel(String text) {
    // Arabic / RTL unicode ranges. Used only to set Text.textDirection so
    // the label string itself renders naturally without affecting
    // chart geometry (which must remain LTR).
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(text);
  }

  String _formatValue(double value, AppLocalizations l10n) {
    if (widget.formatValue != null) return widget.formatValue!(value);
    switch (widget.valueKind) {
      case DashboardChartValueKind.hours:
        return DurationFormatter.fromHours(value, l10n);
      case DashboardChartValueKind.count:
        return value.round().toString();
      case DashboardChartValueKind.generic:
        return _defaultFormatValue(value);
    }
  }

  String _formatAxisValue(double value, AppLocalizations l10n) {
    if (widget.formatAxisValue != null) return widget.formatAxisValue!(value);
    switch (widget.valueKind) {
      case DashboardChartValueKind.hours:
        return DurationFormatter.compactFromHours(value, l10n);
      case DashboardChartValueKind.count:
        return value.round().toString();
      case DashboardChartValueKind.generic:
        return _defaultFormatValue(value);
    }
  }

  String _shortLabel(String label, {required bool compact}) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return '—';
    if (!compact || trimmed.length <= 12) return trimmed;

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final candidate = '${parts.first} ${parts.last[0]}.';
      if (candidate.length <= 14) return candidate;
    }
    return '${trimmed.substring(0, 11)}…';
  }

  int _xLabelStep(int count, double chartWidth, bool compact) {
    if (count <= 1) return 1;
    final minSlot = compact ? 44.0 : 36.0;
    final slot = chartWidth / count;
    if (slot >= minSlot) return 1;
    return (minSlot / slot).ceil().clamp(1, count);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final points = widget.points;
    final compact = _compact;
    final axisStyle = DashboardTypography.chartAxis(context, compact: compact);
    final chartHeight = compact ? widget.height + 24 : widget.height;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: DashboardTypography.chartTitle(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (points.isEmpty)
          SizedBox(
            height: chartHeight,
            child: Center(
              child: Text(
                l10n.dashboardChartEmpty,
                style: DashboardTypography.secondary(context),
              ),
            ),
          )
        else ...[
          if (_selected != null &&
              _selected! >= 0 &&
              _selected! < points.length)
            _SelectionBanner(
              label: points[_selected!].label,
              value: _formatValue(points[_selected!].value, l10n),
            ),
          SizedBox(
            height: chartHeight,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final yAxisWidth = compact ? 52.0 : 44.0;

                var maxValue = 0.0;
                for (final p in points) {
                  if (p.value > maxValue) maxValue = p.value;
                }
                if (maxValue <= 0) maxValue = 1;

                final yTicks = <double>[maxValue, maxValue / 2, 0];

                // Chart geometry is always LTR regardless of app Directionality.
                // RTL must not mirror the Row or bar slots — only label text direction.
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: yAxisWidth,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  for (final tick in yTicks)
                                    Text(
                                      tick <= 0
                                          ? ''
                                          : _formatAxisValue(tick, l10n),
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
                              child: LayoutBuilder(
                                builder: (context, plotConstraints) {
                                  final geometry = DashboardBarChartGeometry(
                                    plotWidth: plotConstraints.maxWidth,
                                    barCount: points.length,
                                  );
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (details) {
                                      setState(
                                        () => _selected = geometry.indexForLocalDx(
                                          details.localPosition.dx,
                                        ),
                                      );
                                    },
                                    child: CustomPaint(
                                      painter: _MiniBarChartPainter(
                                        points: points,
                                        maxValue: maxValue,
                                        barColor: colorScheme.primary
                                            .withValues(alpha: 0.88),
                                        selectedColor: colorScheme.primary,
                                        gridColor: colorScheme.outlineVariant
                                            .withValues(alpha: 0.45),
                                        selectedIndex: _selected,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: yAxisWidth),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, plotConstraints) {
                                final geometry = DashboardBarChartGeometry(
                                  plotWidth: plotConstraints.maxWidth,
                                  barCount: points.length,
                                );
                                final step = _xLabelStep(
                                  points.length,
                                  geometry.plotWidth,
                                  compact,
                                );

                                return SizedBox(
                                  height: compact ? 34 : 28,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      for (var i = 0; i < points.length; i++)
                                        if (i % step == 0 ||
                                            i == points.length - 1)
                                          Positioned(
                                            left: geometry.barCenterX(i) -
                                                geometry.slotWidth / 2,
                                            width: geometry.slotWidth,
                                            child: _ChartAxisLabel(
                                              text: _shortLabel(
                                                points[i].label,
                                                compact: compact,
                                              ),
                                              compact: compact,
                                              rtlText: _isRtlLabel(
                                                points[i].label,
                                              ),
                                              style: axisStyle,
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
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );

    final painted = RepaintBoundary(child: body);

    if (widget.embedded) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.sm),
          child: painted,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
        child: painted,
      ),
    );
  }
}

class _ChartAxisLabel extends StatelessWidget {
  const _ChartAxisLabel({
    required this.text,
    required this.compact,
    required this.rtlText,
    required this.style,
  });

  final String text;
  final bool compact;
  final bool rtlText;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: rtlText ? TextDirection.rtl : TextDirection.ltr,
      child: Text(
        text,
        maxLines: compact ? 2 : 1,
        softWrap: true,
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

class _SelectionBanner extends StatelessWidget {
  const _SelectionBanner({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DashboardTypography.chartTooltip(context),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DashboardTypography.chartTooltipValue(context),
          ),
        ],
      ),
    );
  }
}

class _MiniBarChartPainter extends CustomPainter {
  _MiniBarChartPainter({
    required this.points,
    required this.maxValue,
    required this.barColor,
    required this.selectedColor,
    required this.gridColor,
    this.selectedIndex,
  });

  final List<DashboardChartPoint> points;
  final double maxValue;
  final Color barColor;
  final Color selectedColor;
  final Color gridColor;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const topPad = 4.0;
    const bottomPad = 4.0;
    final chartHeight =
        (size.height - topPad - bottomPad).clamp(4.0, size.height);
    final count = points.length;
    final slot = size.width / count;
    final barWidth = (slot * 0.62).clamp(8.0, 32.0);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topPad + chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < count; i++) {
      final point = points[i];
      final barH =
          ((point.value / maxValue) * chartHeight).clamp(3.0, chartHeight);
      final left = slot * i + (slot - barWidth) / 2;
      final top = topPad + chartHeight - barH;
      final selected = selectedIndex == i;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barH),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = selected ? selectedColor : barColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBarChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.barColor != barColor;
  }
}
