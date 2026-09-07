import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/skeleton/skeleton_box.dart';

/// Non-scrolling square tile grid matching gallery Wrap columns.
class SkeletonGalleryGrid extends StatelessWidget {
  const SkeletonGalleryGrid({
    super.key,
    this.tileCount = 6,
    this.spacing = AppSpacing.sm,
  });

  final int tileCount;
  final double spacing;

  static int crossAxisCountForWidth(double width) {
    if (width >= 900) return 5;
    if (width >= 600) return 4;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = crossAxisCountForWidth(
          MediaQuery.sizeOf(context).width,
        );
        final count = tileCount.clamp(1, 8);
        final tileSize =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < count; i++)
              SkeletonBox(
                width: tileSize,
                height: tileSize,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
          ],
        );
      },
    );
  }
}

/// Convenience for tests / callers using [AppBreakpoints.tabletMax].
@visibleForTesting
int skeletonGalleryCrossAxisCount(double width) =>
    SkeletonGalleryGrid.crossAxisCountForWidth(width);
