import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

/// First-load placeholder for Overtime history / admin result lists.
class OvertimeListSkeleton extends StatelessWidget {
  const OvertimeListSkeleton({
    super.key,
    this.itemCount = 7,
    this.semanticsLabel,
  });

  final int itemCount;
  final String? semanticsLabel;

  static const int kMaxItems = 8;

  @override
  Widget build(BuildContext context) {
    final count = itemCount.clamp(1, kMaxItems);
    final isDesktop = AppBreakpoints.isDesktopOf(context);

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: SkeletonScope(
          child: isDesktop
              ? ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: count,
                  itemBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: SkeletonTableRow(columnCount: 5),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppScrollPadding.resolve(
                    context,
                    base: const EdgeInsets.all(AppSpacing.lg),
                    chrome: AppBottomChrome.system,
                  ),
                  itemCount: count,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, _) => const SkeletonListTile(
                    lines: 3,
                    widthFactors: [0.62, 0.85, 0.4],
                    showTrailing: true,
                  ),
                ),
        ),
      ),
    );
  }
}
