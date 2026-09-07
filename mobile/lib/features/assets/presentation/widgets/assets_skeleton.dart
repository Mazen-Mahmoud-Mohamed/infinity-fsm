import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_stat_grid.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

enum AssetsSkeletonVariant { dashboard, list }

/// First-load placeholder for the Assets dashboard or assets list body.
class AssetsSkeleton extends StatelessWidget {
  const AssetsSkeleton({
    super.key,
    this.variant = AssetsSkeletonVariant.dashboard,
    this.itemCount = 7,
    this.semanticsLabel,
  });

  final AssetsSkeletonVariant variant;
  final int itemCount;
  final String? semanticsLabel;

  static const int kMaxItems = 8;
  static const int kStatCount = 5;

  @override
  Widget build(BuildContext context) {
    final count = itemCount.clamp(1, kMaxItems);
    final isDesktop = AppBreakpoints.isDesktopOf(context);

    final body = SkeletonScope(
      child: variant == AssetsSkeletonVariant.list
          ? _AssetsListSkeleton(itemCount: count)
          : _AssetsDashboardSkeleton(isDesktop: isDesktop),
    );

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: body),
    );
  }
}

class _AssetsDashboardSkeleton extends StatelessWidget {
  const _AssetsDashboardSkeleton({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final isPhone = AppBreakpoints.isPhoneOf(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.contentWideMax,
        ),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppScrollPadding.resolve(
            context,
            base: EdgeInsets.all(isPhone ? AppSpacing.md : AppSpacing.lg),
            chrome: AppBottomChrome.system,
          ),
          children: [
            if (isDesktop) ...[
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: 0.22,
                  child: SkeletonBox(height: 28),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            const AppDesktopStatGrid(
              phoneColumns: 2,
              tabletColumns: 3,
              desktopColumns: 5,
              children: [
                _StatCardBone(),
                _StatCardBone(),
                _StatCardBone(),
                _StatCardBone(),
                _StatCardBone(),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isDesktop)
              const Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  SizedBox(width: 260, child: _NavTileBone()),
                  SizedBox(width: 260, child: _NavTileBone()),
                  SizedBox(width: 260, child: _NavTileBone()),
                  SizedBox(width: 260, child: _NavTileBone()),
                ],
              )
            else
              const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SkeletonChip(width: 96),
                  SkeletonChip(width: 120),
                  SkeletonChip(width: 108),
                  SkeletonChip(width: 88),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AssetsListSkeleton extends StatelessWidget {
  const _AssetsListSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.all(AppSpacing.md),
        chrome: AppBottomChrome.fab,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const _AssetRowBone(),
    );
  }
}

class _StatCardBone extends StatelessWidget {
  const _StatCardBone();

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 36, height: 36),
          SizedBox(height: AppSpacing.sm),
          SkeletonText(lines: 2, widthFactors: [0.7, 0.38]),
        ],
      ),
    );
  }
}

class _NavTileBone extends StatelessWidget {
  const _NavTileBone();

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      child: SkeletonText(lines: 2, widthFactors: [0.75, 0.45]),
    );
  }
}

class _AssetRowBone extends StatelessWidget {
  const _AssetRowBone();

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: SkeletonText(
              lines: 2,
              widthFactors: [0.85, 0.55],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const SkeletonChip(width: 72, height: 22),
        ],
      ),
    );
  }
}
