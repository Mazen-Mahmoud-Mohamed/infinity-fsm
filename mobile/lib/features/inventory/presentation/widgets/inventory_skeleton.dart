import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_stat_grid.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

enum InventorySkeletonVariant { dashboard, list }

/// First-load placeholder for Inventory dashboard or spare-parts results.
class InventorySkeleton extends StatelessWidget {
  const InventorySkeleton({
    super.key,
    this.variant = InventorySkeletonVariant.dashboard,
    this.itemCount = 7,
    this.semanticsLabel,
  });

  final InventorySkeletonVariant variant;
  final int itemCount;
  final String? semanticsLabel;

  static const int kMaxItems = 8;
  static const int kStatCount = 4;

  @override
  Widget build(BuildContext context) {
    final count = itemCount.clamp(1, kMaxItems);
    final isDesktop = AppBreakpoints.isDesktopOf(context);

    final body = SkeletonScope(
      child: variant == InventorySkeletonVariant.list
          ? _SparePartsListSkeleton(itemCount: count)
          : _InventoryDashboardSkeleton(
              itemCount: count,
              isDesktop: isDesktop,
            ),
    );

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: body),
    );
  }
}

class _InventoryDashboardSkeleton extends StatelessWidget {
  const _InventoryDashboardSkeleton({
    required this.itemCount,
    required this.isDesktop,
  });

  final int itemCount;
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
                  widthFactor: 0.28,
                  child: SkeletonBox(height: 28),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            const AppDesktopStatGrid(
              phoneColumns: 2,
              tabletColumns: 4,
              desktopColumns: 4,
              children: [
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
                  SizedBox(width: 220, child: _NavTileBone()),
                  SizedBox(width: 220, child: _NavTileBone()),
                  SizedBox(width: 220, child: _NavTileBone()),
                ],
              )
            else
              const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SkeletonChip(width: 120),
                  SkeletonChip(width: 132),
                  SkeletonChip(width: 108),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: 0.42,
                child: SkeletonBox(height: 16),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < itemCount; i++) ...[
              const SkeletonListTile(
                lines: 2,
                widthFactors: [0.75, 0.45],
                showTrailing: true,
                trailingWidth: 48,
              ),
              if (i != itemCount - 1) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _SparePartsListSkeleton extends StatelessWidget {
  const _SparePartsListSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        chrome: AppBottomChrome.fab,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const _ThumbRowBone(),
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
          SkeletonText(lines: 2, widthFactors: [0.72, 0.4]),
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
      child: SkeletonText(lines: 2, widthFactors: [0.8, 0.5]),
    );
  }
}

class _ThumbRowBone extends StatelessWidget {
  const _ThumbRowBone();

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
              widthFactors: [0.8, 0.45],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const SkeletonChip(width: 64, height: 22),
        ],
      ),
    );
  }
}
