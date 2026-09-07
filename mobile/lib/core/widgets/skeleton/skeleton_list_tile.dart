import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/skeleton/skeleton_box.dart';
import 'package:mobile/core/widgets/skeleton/skeleton_card.dart';
import 'package:mobile/core/widgets/skeleton/skeleton_circle.dart';
import 'package:mobile/core/widgets/skeleton/skeleton_text.dart';

/// Card-style list row: leading circle + multi-line text (+ optional trailing).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({
    super.key,
    this.leadingSize = 40,
    this.lines = 3,
    this.widthFactors = const [0.85, 1.0, 0.4],
    this.showTrailing = false,
    this.trailingWidth = 56,
  });

  final double leadingSize;
  final int lines;
  final List<double> widthFactors;
  final bool showTrailing;
  final double trailingWidth;

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonCircle(size: leadingSize),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SkeletonText(
              lines: lines,
              widthFactors: widthFactors,
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: AppSpacing.sm),
            SkeletonBox(width: trailingWidth, height: 22),
          ],
        ],
      ),
    );
  }
}
