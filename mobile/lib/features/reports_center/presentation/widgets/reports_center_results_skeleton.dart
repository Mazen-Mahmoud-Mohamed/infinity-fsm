import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

/// Result-area placeholder for Reports Center (filters stay mounted).
class ReportsCenterResultsSkeleton extends StatelessWidget {
  const ReportsCenterResultsSkeleton({
    super.key,
    this.itemCount = 6,
    this.semanticsLabel,
  });

  final int itemCount;
  final String? semanticsLabel;

  static const int kMaxItems = 6;

  @override
  Widget build(BuildContext context) {
    final count = itemCount.clamp(1, kMaxItems);
    final isPhone = AppBreakpoints.isPhoneOf(context);

    final body = SkeletonScope(
      child: isPhone
          ? _MobileResultsSkeleton(itemCount: count)
          : _DesktopResultsSkeleton(itemCount: count),
    );

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: body),
    );
  }
}

class _MobileResultsSkeleton extends StatelessWidget {
  const _MobileResultsSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const SkeletonCard(
        child: SkeletonText(lines: 2, widthFactors: [0.8, 0.55]),
      ),
    );
  }
}

class _DesktopResultsSkeleton extends StatelessWidget {
  const _DesktopResultsSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          const SkeletonTableRow(columnCount: 5, height: 36),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: itemCount,
              itemBuilder: (_, _) =>
                  const SkeletonTableRow(columnCount: 5),
            ),
          ),
        ],
      ),
    );
  }
}
