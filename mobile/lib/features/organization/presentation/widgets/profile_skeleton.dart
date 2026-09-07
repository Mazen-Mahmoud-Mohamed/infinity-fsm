import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

/// First-load placeholder for Profile (header, metadata rows, permissions).
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({
    super.key,
    this.permissionRowCount = 6,
    this.semanticsLabel,
  });

  final int permissionRowCount;
  final String? semanticsLabel;

  static const int kMaxPermissionRows = 6;

  @override
  Widget build(BuildContext context) {
    final count = permissionRowCount.clamp(1, kMaxPermissionRows);
    final isDesktop = AppBreakpoints.isDesktopOf(context);

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: SkeletonScope(
          child: _ProfileSkeletonBody(
            isDesktop: isDesktop,
            permissionRowCount: count,
          ),
        ),
      ),
    );
  }
}

class _ProfileSkeletonBody extends StatelessWidget {
  const _ProfileSkeletonBody({
    required this.isDesktop,
    required this.permissionRowCount,
  });

  final bool isDesktop;
  final int permissionRowCount;

  @override
  Widget build(BuildContext context) {
    final isPhone = AppBreakpoints.isPhoneOf(context);
    final account = [
      if (isDesktop)
        const SkeletonCard(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              SkeletonCircle(size: 72),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.55,
                      child: SkeletonBox(height: 22),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    FractionallySizedBox(
                      widthFactor: 0.72,
                      child: SkeletonBox(height: 14),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonChip(),
                  ],
                ),
              ),
            ],
          ),
        )
      else ...[
        const Center(child: SkeletonCircle(size: 84)),
        const SizedBox(height: AppSpacing.md),
        const Center(
          child: FractionallySizedBox(
            widthFactor: 0.45,
            child: SkeletonBox(height: 22),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      SkeletonCard(
        child: Column(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              const Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: SkeletonBox(height: 12),
                  ),
                  Expanded(child: SkeletonBox(height: 14)),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const SkeletonListTile(lines: 1, widthFactors: [0.5], leadingSize: 24),
      const SizedBox(height: AppSpacing.sm),
      const SkeletonListTile(lines: 1, widthFactors: [0.4], leadingSize: 24),
    ];

    final permissions = [
      const Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: 0.4,
          child: SkeletonBox(height: 18),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const Wrap(
        spacing: AppSpacing.sm,
        children: [
          SkeletonChip(),
          SkeletonChip(),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      for (var i = 0; i < permissionRowCount; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.sm),
        const SkeletonListTile(lines: 2, widthFactors: [0.7, 0.45]),
      ],
    ];

    return ListView(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(children: account)),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: Column(children: permissions)),
            ],
          ),
        ] else ...[
          ...account,
          const SizedBox(height: AppSpacing.lg),
          ...permissions,
        ],
      ],
    );
  }
}
