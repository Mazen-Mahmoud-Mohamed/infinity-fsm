import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

/// First-load placeholder for Notifications (mobile list + desktop split).
class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({
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

    final body = SkeletonScope(
      child: isDesktop
          ? _DesktopNotificationsSkeleton(itemCount: count)
          : _MobileNotificationsSkeleton(itemCount: count),
    );

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: body),
    );
  }
}

class _MobileNotificationsSkeleton extends StatelessWidget {
  const _MobileNotificationsSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final pagePad = AppBreakpoints.pagePadding(MediaQuery.sizeOf(context).width);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(pagePad, AppSpacing.md, pagePad, AppSpacing.md),
      children: [
        SkeletonBox(height: 48, borderRadius: BorderRadius.circular(8)),
        const SizedBox(height: AppSpacing.md),
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SkeletonChip(width: 64),
            SkeletonChip(width: 88),
            SkeletonChip(width: 96),
            SkeletonChip(width: 80),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < itemCount; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          const SkeletonListTile(
            leadingSize: 40,
            lines: 3,
            widthFactors: [0.75, 1.0, 0.35],
            showTrailing: true,
            trailingWidth: 48,
          ),
        ],
      ],
    );
  }
}

class _DesktopNotificationsSkeleton extends StatelessWidget {
  const _DesktopNotificationsSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: 0.28,
              child: SkeletonBox(height: 28, borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SkeletonBox(height: 44, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: AppSpacing.sm),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SkeletonChip(width: 72),
              SkeletonChip(width: 96),
              SkeletonChip(width: 88),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: ListView.separated(
                    itemCount: itemCount,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, _) => const SkeletonListTile(
                      lines: 3,
                      widthFactors: [0.8, 1.0, 0.4],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  flex: 4,
                  child: SkeletonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SkeletonText(lines: 2, widthFactors: [0.7, 0.4]),
                        SizedBox(height: AppSpacing.md),
                        SkeletonText(
                          lines: 5,
                          widthFactors: [1, 1, 0.95, 0.8, 0.5],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
