import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';

/// Centers page content and caps readable width on tablet/desktop.
///
/// Uses [LayoutBuilder] so scrollable children always receive bounded
/// constraints from the parent (critical under desktop shell [Expanded]).
class AppPageFrame extends StatelessWidget {
  const AppPageFrame({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.contentMax,
    this.alignment = Alignment.topCenter,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final resolvedMax = AppBreakpoints.contentMaxWidth(
          screenWidth,
          desktop: maxWidth,
        );
        final width = constraints.hasBoundedWidth
            ? math.min(
                resolvedMax.isFinite ? resolvedMax : constraints.maxWidth,
                constraints.maxWidth,
              )
            : (resolvedMax.isFinite ? resolvedMax : screenWidth);

        Widget content = child;
        if (padding != null) {
          content = Padding(padding: padding!, child: content);
        }

        // Width-cap only. Do not force height — wrapping scrollables
        // (e.g. dashboard ListView under RefreshIndicator) in a tight
        // height SizedBox has caused blank bodies on desktop.
        return Align(
          alignment: alignment,
          child: SizedBox(
            width: width,
            child: content,
          ),
        );
      },
    );
  }
}

/// Horizontal padding that scales with breakpoints.
EdgeInsets appPageInsets(BuildContext context, {double? vertical}) {
  final width = MediaQuery.sizeOf(context).width;
  final h = AppBreakpoints.pagePadding(width);
  final v = vertical ?? AppSpacing.md;
  return EdgeInsets.fromLTRB(h, v, h, v);
}
