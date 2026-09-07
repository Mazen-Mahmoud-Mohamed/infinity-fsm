import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

/// Bounded results placeholder for Global Search (chrome stays mounted).
class GlobalSearchResultsSkeleton extends StatelessWidget {
  const GlobalSearchResultsSkeleton({
    super.key,
    this.itemCount = 6,
    this.semanticsLabel,
  });

  final int itemCount;
  final String? semanticsLabel;

  static const int kMaxItems = 7;

  @override
  Widget build(BuildContext context) {
    final count = itemCount.clamp(1, kMaxItems);
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: SkeletonScope(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, _) => const SkeletonListTile(
              lines: 2,
              widthFactors: [0.72, 0.48],
            ),
          ),
        ),
      ),
    );
  }
}
