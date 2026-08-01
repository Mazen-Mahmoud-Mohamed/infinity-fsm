import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';

/// Side-by-side layout on desktop; stacked column on narrower viewports.
class AppDesktopSplitView extends StatelessWidget {
  const AppDesktopSplitView({
    super.key,
    required this.start,
    required this.end,
    this.startFlex = 3,
    this.endFlex = 2,
    this.gap = AppSpacing.lg,
    this.breakpoint = AppBreakpoints.tabletMax,
  });

  final Widget start;
  final Widget end;
  final int startFlex;
  final int endFlex;
  final double gap;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: startFlex, child: start),
              SizedBox(width: gap),
              Expanded(flex: endFlex, child: end),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            start,
            SizedBox(height: gap),
            end,
          ],
        );
      },
    );
  }
}
