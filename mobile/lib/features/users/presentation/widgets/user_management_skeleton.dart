import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_stat_grid.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

enum UserManagementSkeletonVariant { dashboard, list, detail }

/// First-load placeholder for Users dashboard or user list body.
class UserManagementSkeleton extends StatelessWidget {
  const UserManagementSkeleton({
    super.key,
    this.variant = UserManagementSkeletonVariant.dashboard,
    this.itemCount = 7,
    this.semanticsLabel,
  });

  final UserManagementSkeletonVariant variant;
  final int itemCount;
  final String? semanticsLabel;

  static const int kMaxItems = 8;

  @override
  Widget build(BuildContext context) {
    final count = itemCount.clamp(1, kMaxItems);
    final isDesktop = AppBreakpoints.isDesktopOf(context);

    final Widget child;
    switch (variant) {
      case UserManagementSkeletonVariant.list:
        child = _UsersListSkeleton(itemCount: count, isDesktop: isDesktop);
      case UserManagementSkeletonVariant.detail:
        child = const _UserDetailSkeleton();
      case UserManagementSkeletonVariant.dashboard:
        child = _UsersDashboardSkeleton(isDesktop: isDesktop);
    }

    final body = SkeletonScope(child: child);

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: body),
    );
  }
}

class _UsersDashboardSkeleton extends StatelessWidget {
  const _UsersDashboardSkeleton({required this.isDesktop});

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
                  widthFactor: 0.24,
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
                  SizedBox(width: 240, child: _NavTileBone()),
                  SizedBox(width: 240, child: _NavTileBone()),
                  SizedBox(width: 240, child: _NavTileBone()),
                ],
              )
            else
              const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
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

class _UsersListSkeleton extends StatelessWidget {
  const _UsersListSkeleton({
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

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.all(AppSpacing.md),
        chrome: AppBottomChrome.fab,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const SkeletonListTile(
        leadingSize: 40,
        lines: 3,
        widthFactors: [0.7, 0.85, 0.45],
        showTrailing: true,
        trailingWidth: 64,
      ),
    );
  }
}

class _UserDetailSkeleton extends StatelessWidget {
  const _UserDetailSkeleton();

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
        Center(child: SkeletonCircle(size: 96)),
        SizedBox(height: AppSpacing.md),
        Center(
          child: SizedBox(
            width: 180,
            child: SkeletonText(lines: 1, widthFactors: [1]),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Center(child: SkeletonChip(width: 88, height: 24)),
        SizedBox(height: AppSpacing.lg),
        SkeletonText(lines: 6, widthFactors: [0.35, 0.7, 0.4, 0.65, 0.38, 0.55]),
        SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SkeletonChip(width: 120, height: 36),
            SkeletonChip(width: 108, height: 36),
          ],
        ),
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
      child: SkeletonText(lines: 2, widthFactors: [0.75, 0.45]),
    );
  }
}
