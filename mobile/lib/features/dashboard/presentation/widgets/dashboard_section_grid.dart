import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';

/// Arranges dashboard section cards in 1 or 2 columns by breakpoint.
///
/// Does **not** use [IntrinsicHeight]: metric cards contain [LayoutBuilder],
/// and IntrinsicHeight + LayoutBuilder throws during layout on desktop
/// ("LayoutBuilder does not support returning intrinsic dimensions"),
/// which blanks the dashboard body.
class DashboardSectionGrid extends StatelessWidget {
  const DashboardSectionGrid({
    super.key,
    required this.children,
    this.gap = AppSpacing.lg,
  });

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox(height: 0);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            AppBreakpoints.isDashboardCompact(constraints.maxWidth) ? 1 : 2;

        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          final left = children[i];
          final hasRight = i + 1 < children.length;
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                SizedBox(width: gap),
                Expanded(
                  child: hasRight
                      ? children[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}
