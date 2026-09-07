import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/skeleton/skeleton_box.dart';

/// One or more text-line bones.
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.lines = 1,
    this.width,
    this.lineHeight = 12,
    this.spacing = AppSpacing.xs,
    this.widthFactors = const [1.0],
  });

  final int lines;
  final double? width;
  final double lineHeight;
  final double spacing;

  /// Relative widths per line (cycles if shorter than [lines]).
  final List<double> widthFactors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          FractionallySizedBox(
            widthFactor: widthFactors[i % widthFactors.length].clamp(0.15, 1.0),
            alignment: AlignmentDirectional.centerStart,
            child: SkeletonBox(
              width: width,
              height: lineHeight,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
        ],
      ],
    );
  }
}
