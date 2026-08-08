import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_typography.dart';

/// Compact bar chart with grid, axis hint, and tap tooltip.
class DashboardMiniChart extends StatefulWidget {
  const DashboardMiniChart({
    super.key,
    required this.title,
    required this.points,
    this.height = 150,
    this.embedded = false,
  });

  final String title;
  final List<DashboardChartPoint> points;
  final double height;

  /// When true, omit outer Card (already inside a panel).
  final bool embedded;

  @override
  State<DashboardMiniChart> createState() => _DashboardMiniChartState();
}

class _DashboardMiniChartState extends State<DashboardMiniChart> {
  int? _selected;

  String _shortLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.length <= 10) return trimmed;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final candidate = '${parts.first} ${parts.last[0]}.';
      if (candidate.length <= 12) return candidate;
    }
    return '${trimmed.substring(0, 9)}…';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final points = widget.points;

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
            height: widget.height,
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
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '${points[_selected!].label}: ${_formatValue(points[_selected!].value)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DashboardTypography.chartTooltip(context),
              ),
            ),
          SizedBox(
            height: widget.height,
            width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          final count = points.length;
                          if (count == 0 || constraints.maxWidth <= 0) return;
                          final slot = (details.localPosition.dx /
                                  constraints.maxWidth *
                                  count)
                              .floor()
                              .clamp(0, count - 1);
                          setState(() => _selected = slot);
                        },
                        child: CustomPaint(
                          painter: _MiniBarChartPainter(
                            points: points,
                            shortLabels:
                                points.map((p) => _shortLabel(p.label)).toList(),
                            selectedIndex: _selected,
                            barColor:
                                colorScheme.primary.withValues(alpha: 0.88),
                            selectedColor: colorScheme.primary,
                            gridColor: colorScheme.outlineVariant
                                .withValues(alpha: 0.45),
                            labelStyle: DashboardTypography.chartAxis(context),
                            valueStyle: DashboardTypography.chartAxis(context)
                                .copyWith(fontSize: 9),
                          ),
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
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: painted,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: painted,
      ),
    );
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }
}

class _MiniBarChartPainter extends CustomPainter {
  _MiniBarChartPainter({
    required this.points,
    required this.shortLabels,
    required this.barColor,
    required this.selectedColor,
    required this.gridColor,
    required this.labelStyle,
    required this.valueStyle,
    this.selectedIndex,
  });

  final List<DashboardChartPoint> points;
  final List<String> shortLabels;
  final Color barColor;
  final Color selectedColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const labelBand = 26.0;
    const topPad = 14.0;
    final chartHeight =
        (size.height - labelBand - topPad).clamp(4.0, size.height);
    final count = points.length;
    final barWidth = (size.width / count * 0.55).clamp(10.0, 28.0);
    final slot = size.width / count;

    var maxValue = 0.0;
    for (final p in points) {
      if (p.value > maxValue) maxValue = p.value;
    }
    if (maxValue <= 0) maxValue = 1;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topPad + chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxLabel = TextPainter(
      text: TextSpan(
        text: maxValue == maxValue.roundToDouble()
            ? maxValue.round().toString()
            : maxValue.toStringAsFixed(1),
        style: valueStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    maxLabel.paint(canvas, const Offset(0, 0));

    for (var i = 0; i < count; i++) {
      final point = points[i];
      final barH = ((point.value / maxValue) * chartHeight).clamp(3.0, chartHeight);
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

      final tp = TextPainter(
        text: TextSpan(text: shortLabels[i], style: labelStyle),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: slot - 2);
      tp.paint(
        canvas,
        Offset(
          slot * i + (slot - tp.width) / 2,
          topPad + chartHeight + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBarChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.barColor != barColor;
  }
}
