import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_stat_grid.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

enum ServiceReportsSkeletonVariant { dashboard, list, detail }

/// First-load placeholder for Service Reports surfaces.
class ServiceReportsSkeleton extends StatelessWidget {
  const ServiceReportsSkeleton({
    super.key,
    this.variant = ServiceReportsSkeletonVariant.dashboard,
    this.itemCount = 7,
    this.semanticsLabel,
  });

  final ServiceReportsSkeletonVariant variant;
  final int itemCount;
  final String? semanticsLabel;

  static const int kMaxItems = 8;
  static const int kMaxGalleryTiles = 6;

  @override
  Widget build(BuildContext context) {
    final count = itemCount.clamp(1, kMaxItems);
    final isDesktop = AppBreakpoints.isDesktopOf(context);

    final Widget child;
    switch (variant) {
      case ServiceReportsSkeletonVariant.list:
        child = _ListSkeleton(itemCount: count);
      case ServiceReportsSkeletonVariant.detail:
        child = const _DetailSkeleton();
      case ServiceReportsSkeletonVariant.dashboard:
        child = _DashboardSkeleton(isDesktop: isDesktop);
    }

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: SkeletonScope(child: child)),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({required this.isDesktop});

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
                  SizedBox(width: 200, child: _NavTileBone()),
                  SizedBox(width: 200, child: _NavTileBone()),
                  SizedBox(width: 200, child: _NavTileBone()),
                ],
              )
            else
              const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SkeletonChip(width: 96),
                  SkeletonChip(width: 140),
                  SkeletonChip(width: 108),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.all(AppSpacing.md),
        chrome: AppBottomChrome.system,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const SkeletonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonText(lines: 3, widthFactors: [0.45, 0.6, 0.35]),
            SizedBox(height: AppSpacing.sm),
            SkeletonChip(width: 88, height: 22),
          ],
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.all(AppSpacing.md),
        chrome: AppBottomChrome.system,
      ),
      children: const [
        SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 120, height: 40),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: SkeletonText(lines: 1, widthFactors: [0.5]),
                  ),
                  SkeletonChip(width: 88, height: 22),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              SkeletonText(lines: 4, widthFactors: [0.4, 0.85, 0.7, 0.6]),
              SizedBox(height: AppSpacing.md),
              SkeletonText(lines: 3, widthFactors: [0.35, 0.75, 0.55]),
              SizedBox(height: AppSpacing.md),
              SkeletonGalleryGrid(tileCount: 6),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(height: 72),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 44),
      ],
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
      child: SkeletonText(lines: 1, widthFactors: [0.7]),
    );
  }
}
