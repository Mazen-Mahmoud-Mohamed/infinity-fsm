import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';

/// Maps the signed-in user to the dashboard layout role used for first-load
/// skeleton structure (before [RoleDashboardSummary] arrives).
DashboardViewRole resolveDashboardSkeletonRole(CurrentUser? user) {
  if (user == null) return DashboardViewRole.admin;
  final upper = user.roles.map((role) => role.toUpperCase());
  if (upper.contains('ADMIN')) return DashboardViewRole.admin;
  if (upper.contains('SUPERVISOR')) return DashboardViewRole.supervisor;
  return DashboardViewRole.technician;
}

/// First-load placeholder that mirrors role-specific dashboard structure.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({
    super.key,
    required this.viewRole,
    required this.pagePadding,
    required this.sectionGap,
    this.semanticsLabel,
  });

  final DashboardViewRole viewRole;
  final double pagePadding;
  final double sectionGap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final isPhone = AppBreakpoints.isPhoneOf(context);

    final body = SkeletonScope(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.contentWideMax,
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppScrollPadding.resolve(
              context,
              base: EdgeInsets.all(pagePadding),
              chrome: AppBottomChrome.system,
            ),
            children: [
              const _HeaderSkeleton(),
              SizedBox(height: sectionGap),
              ...switch (viewRole) {
                DashboardViewRole.admin => _adminSections(sectionGap),
                DashboardViewRole.supervisor =>
                  _supervisorSections(sectionGap, isPhone),
                DashboardViewRole.technician =>
                  _technicianSections(sectionGap, isPhone),
              },
            ],
          ),
        ),
      ),
    );

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: body),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: 0.55,
            child: SkeletonBox(
              height: 22,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SkeletonChip(width: 64),
            SkeletonChip(width: 72),
            SkeletonChip(width: 80),
            SkeletonChip(width: 88),
            SkeletonChip(width: 76),
          ],
        ),
      ],
    );
  }
}

List<Widget> _adminSections(double sectionGap) {
  return [
    const _KpiStripSkeleton(count: 4),
    SizedBox(height: sectionGap),
    _AdminTwoColumnSkeleton(sectionGap: sectionGap),
    SizedBox(height: sectionGap),
    const _FeedSkeleton(rows: 3),
  ];
}

List<Widget> _supervisorSections(double sectionGap, bool isPhone) {
  return [
    const _HeroMetricsSkeleton(count: 4),
    SizedBox(height: sectionGap),
    const _MetricGroupCardSkeleton(metricCount: 4),
    SizedBox(height: sectionGap),
    const _MetricGroupCardSkeleton(metricCount: 3),
    SizedBox(height: sectionGap),
    const _ChartBlockSkeleton(),
    SizedBox(height: sectionGap),
    const _FeedSkeleton(rows: 3),
    if (isPhone) ...[
      SizedBox(height: sectionGap),
      const _QuickActionsSkeleton(),
    ],
  ];
}

List<Widget> _technicianSections(double sectionGap, bool isPhone) {
  return [
    const _HeroMetricsSkeleton(count: 2),
    SizedBox(height: sectionGap),
    const _MetricGroupCardSkeleton(metricCount: 4),
    SizedBox(height: sectionGap),
    const _ChartBlockSkeleton(),
    SizedBox(height: sectionGap),
    const _FeedSkeleton(rows: 2),
    if (isPhone) ...[
      SizedBox(height: sectionGap),
      const _QuickActionsSkeleton(),
    ],
  ];
}

class _KpiStripSkeleton extends StatelessWidget {
  const _KpiStripSkeleton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= AppBreakpoints.tabletMax;
    final compact = AppBreakpoints.isDashboardCompact(width);
    final columns = wide
        ? count.clamp(1, 5)
        : compact
            ? (width < 360 ? 1 : 2)
            : 3;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
          vertical: compact ? AppSpacing.xs : AppSpacing.sm,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tileW = constraints.maxWidth / columns;
            return Wrap(
              runSpacing: AppSpacing.xs,
              children: [
                for (var i = 0; i < count; i++)
                  SizedBox(
                    width: tileW,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
                        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          SkeletonCircle(size: compact ? 30 : 34),
                          const SizedBox(width: AppSpacing.sm),
                          const Expanded(
                            child: SkeletonText(
                              lines: 2,
                              lineHeight: 10,
                              widthFactors: [0.9, 0.55],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminTwoColumnSkeleton extends StatelessWidget {
  const _AdminTwoColumnSkeleton({required this.sectionGap});

  final double sectionGap;

  @override
  Widget build(BuildContext context) {
    final main = <Widget>[
      const _WorkforcePanelSkeleton(),
      SizedBox(height: sectionGap),
      const _ChartBlockSkeleton(),
      SizedBox(height: sectionGap),
      const _ChartBlockSkeleton(height: 120),
    ];
    final side = <Widget>[
      const _StatusPanelSkeleton(rows: 5),
      SizedBox(height: sectionGap),
      const _StatusPanelSkeleton(rows: 4),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns =
            constraints.maxWidth > AppBreakpoints.dashboardCompactMax;
        if (!useColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [...main, SizedBox(height: sectionGap), ...side],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: main,
              ),
            ),
            SizedBox(width: sectionGap),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: side,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WorkforcePanelSkeleton extends StatelessWidget {
  const _WorkforcePanelSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPanel(
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(child: SkeletonText(lines: 2, widthFactors: [0.7, 0.4])),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonText(lines: 2, widthFactors: [0.7, 0.4])),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Expanded(child: SkeletonText(lines: 2, widthFactors: [0.7, 0.4])),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonText(lines: 2, widthFactors: [0.7, 0.4])),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SkeletonBox(
            height: 8,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricsSkeleton extends StatelessWidget {
  const _HeroMetricsSkeleton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= AppBreakpoints.tabletMax
        ? count.clamp(1, 4)
        : (width < 400 ? 1 : 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileW =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: tileW,
                child: const SkeletonCard(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      SkeletonCircle(size: 36),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SkeletonText(
                          lines: 2,
                          widthFactors: [0.85, 0.45],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MetricGroupCardSkeleton extends StatelessWidget {
  const _MetricGroupCardSkeleton({required this.metricCount});

  final int metricCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonPanel(
      child: Column(
        children: [
          for (var i = 0; i < metricCount; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            const Row(
              children: [
                SkeletonCircle(size: 28),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SkeletonText(
                    lines: 2,
                    lineHeight: 10,
                    widthFactors: [0.8, 0.4],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartBlockSkeleton extends StatelessWidget {
  const _ChartBlockSkeleton({this.height = 140});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonPanel(
      child: SkeletonBox(
        height: height,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

class _StatusPanelSkeleton extends StatelessWidget {
  const _StatusPanelSkeleton({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return SkeletonPanel(
      child: Column(
        children: [
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            const Row(
              children: [
                Expanded(
                  child: SkeletonText(lines: 1, widthFactors: [0.7]),
                ),
                SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 36,
                  child: SkeletonText(lines: 1, widthFactors: [1]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return SkeletonPanel(
      titleWidthFactor: 0.4,
      child: Column(
        children: [
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonCircle(size: 36),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SkeletonText(
                    lines: 3,
                    widthFactors: [0.9, 1.0, 0.45],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionsSkeleton extends StatelessWidget {
  const _QuickActionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        SkeletonChip(width: 108, height: 40),
        SkeletonChip(width: 120, height: 40),
        SkeletonChip(width: 100, height: 40),
      ],
    );
  }
}
