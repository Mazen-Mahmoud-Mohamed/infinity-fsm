import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';

/// Responsive equal-width grid for stat cards and compact action rows.
class AppDesktopStatGrid extends StatelessWidget {
  const AppDesktopStatGrid({
    super.key,
    required this.children,
    this.spacing = AppSpacing.md,
    this.phoneColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
  });

  final List<Widget> children;
  final double spacing;
  final int phoneColumns;
  final int tabletColumns;
  final int desktopColumns;

  int _columnsFor(double width) {
    if (width >= AppBreakpoints.tabletMax) return desktopColumns;
    if (width >= AppBreakpoints.phoneMax) return tabletColumns;
    return phoneColumns;
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _columnsFor(constraints.maxWidth);
        final itemWidth =
            (constraints.maxWidth - (spacing * (cols - 1))) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
