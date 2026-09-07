import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_stat_grid.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

enum PreventiveMaintenanceSkeletonVariant { dashboard, list }

/// First-load placeholder for PM dashboard or plans list body.
class PreventiveMaintenanceSkeleton extends StatelessWidget {
  const PreventiveMaintenanceSkeleton({
    super.key,
    this.variant = PreventiveMaintenanceSkeletonVariant.dashboard,
    this.itemCount = 7,
    this.semanticsLabel,
  });

  final PreventiveMaintenanceSkeletonVariant variant;
  final int itemCount;
  final String? semanticsLabel;

  static const int kMaxItems = 8;
  static const int kStatCount = 4;

  @override
  Widget build(BuildContext context) {
    final count = itemCount.clamp(1, kMaxItems);
    final isDesktop = AppBreakpoints.isDesktopOf(context);

    final body = SkeletonScope(
      child: variant == PreventiveMaintenanceSkeletonVariant.list
          ? _PmPlansListSkeleton(itemCount: count)
          : _PmDashboardSkeleton(
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

class _PmDashboardSkeleton extends StatelessWidget {
  const _PmDashboardSkeleton({
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
                  widthFactor: 0.32,
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
                  SkeletonChip(width: 88),
                  SkeletonChip(width: 108),
                  SkeletonChip(width: 96),
                  SkeletonChip(width: 112),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: 0.4,
                child: SkeletonBox(height: 16),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < itemCount; i++) ...[
              const _PlanCardBone(),
              if (i != itemCount - 1) const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: 0.3,
                child: SkeletonBox(height: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PmPlansListSkeleton extends StatelessWidget {
  const _PmPlansListSkeleton({required this.itemCount});

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
      itemBuilder: (_, _) => const _PlanCardBone(),
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
          SkeletonText(lines: 2, widthFactors: [0.68, 0.36]),
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
      child: SkeletonText(lines: 2, widthFactors: [0.7, 0.48]),
    );
  }
}

class _PlanCardBone extends StatelessWidget {
  const _PlanCardBone();

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonText(lines: 3, widthFactors: [0.8, 0.4, 0.55]),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              SkeletonChip(width: 72, height: 22),
              SkeletonChip(width: 88, height: 22),
            ],
          ),
        ],
      ),
    );
  }
}
