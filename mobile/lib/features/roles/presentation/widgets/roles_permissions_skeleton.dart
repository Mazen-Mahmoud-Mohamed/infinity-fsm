import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_stat_grid.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

enum RolesPermissionsSkeletonVariant { dashboard, list, detail }

/// First-load placeholder for Roles & Permissions surfaces.
class RolesPermissionsSkeleton extends StatelessWidget {
  const RolesPermissionsSkeleton({
    super.key,
    this.variant = RolesPermissionsSkeletonVariant.dashboard,
    this.itemCount = 7,
    this.semanticsLabel,
  });

  final RolesPermissionsSkeletonVariant variant;
  final int itemCount;
  final String? semanticsLabel;

  static const int kMaxItems = 8;
  static const int kMaxPermissionRows = 6;

  @override
  Widget build(BuildContext context) {
    final count = itemCount.clamp(1, kMaxItems);
    final isDesktop = AppBreakpoints.isDesktopOf(context);

    final Widget child;
    switch (variant) {
      case RolesPermissionsSkeletonVariant.list:
        child = _RolesListSkeleton(itemCount: count, isDesktop: isDesktop);
      case RolesPermissionsSkeletonVariant.detail:
        child = const _RoleDetailSkeleton();
      case RolesPermissionsSkeletonVariant.dashboard:
        child = _RolesDashboardSkeleton(isDesktop: isDesktop);
    }

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: SkeletonScope(child: child)),
    );
  }
}

class _RolesDashboardSkeleton extends StatelessWidget {
  const _RolesDashboardSkeleton({required this.isDesktop});

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
            chrome: AppBottomChrome.fab,
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
              tabletColumns: 2,
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
                ],
              )
            else
              const Wrap(
                spacing: AppSpacing.sm,
                children: [
                  SkeletonChip(width: 96),
                  SkeletonChip(width: 108),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RolesListSkeleton extends StatelessWidget {
  const _RolesListSkeleton({
    required this.itemCount,
    required this.isDesktop,
  });

  final int itemCount;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          children: [
            const SkeletonTableRow(columnCount: 4, height: 36),
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: itemCount,
                itemBuilder: (_, _) =>
                    const SkeletonTableRow(columnCount: 4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          0,
        ),
        chrome: AppBottomChrome.fab,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => SkeletonCard(
        child: Row(
          children: [
            SkeletonBox(
              width: 12,
              height: 48,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonText(lines: 2, widthFactors: [0.7, 0.4]),
                  SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      SkeletonChip(width: 64, height: 22),
                      SkeletonChip(width: 72, height: 22),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleDetailSkeleton extends StatelessWidget {
  const _RoleDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.all(AppSpacing.md),
        chrome: AppBottomChrome.system,
      ),
      children: [
        const SkeletonText(lines: 2, widthFactors: [0.55, 0.3]),
        const SizedBox(height: AppSpacing.md),
        const Wrap(
          spacing: AppSpacing.sm,
          children: [
            SkeletonChip(width: 88, height: 28),
            SkeletonChip(width: 120, height: 28),
            SkeletonChip(width: 96, height: 28),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: 0.35,
            child: SkeletonBox(height: 16),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const SkeletonPanel(
          child: Column(
            children: [
              SkeletonListTile(
                leadingSize: 20,
                lines: 2,
                widthFactors: [0.7, 0.9],
              ),
              SizedBox(height: AppSpacing.sm),
              SkeletonListTile(
                leadingSize: 20,
                lines: 2,
                widthFactors: [0.65, 0.8],
              ),
              SizedBox(height: AppSpacing.sm),
              SkeletonListTile(
                leadingSize: 20,
                lines: 2,
                widthFactors: [0.75, 0.85],
              ),
              SizedBox(height: AppSpacing.sm),
              SkeletonListTile(
                leadingSize: 20,
                lines: 2,
                widthFactors: [0.6, 0.7],
              ),
              SizedBox(height: AppSpacing.sm),
              SkeletonListTile(
                leadingSize: 20,
                lines: 2,
                widthFactors: [0.72, 0.88],
              ),
              SizedBox(height: AppSpacing.sm),
              SkeletonListTile(
                leadingSize: 20,
                lines: 2,
                widthFactors: [0.68, 0.78],
              ),
            ],
          ),
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
        const SkeletonListTile(lines: 2, widthFactors: [0.6, 0.5]),
        const SizedBox(height: AppSpacing.sm),
        const SkeletonListTile(lines: 2, widthFactors: [0.55, 0.45]),
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
      child: SkeletonText(lines: 2, widthFactors: [0.7, 0.45]),
    );
  }
}
