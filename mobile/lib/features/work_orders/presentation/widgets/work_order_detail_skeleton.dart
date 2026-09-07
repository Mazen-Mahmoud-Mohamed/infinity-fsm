import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

/// First-load placeholder when Work Order detail has no loaded entity yet.
class WorkOrderDetailSkeleton extends StatelessWidget {
  const WorkOrderDetailSkeleton({
    super.key,
    this.semanticsLabel,
  });

  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);
    final horizontalPad = AppBreakpoints.pagePadding(width);

    final body = SkeletonScope(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppScrollPadding.resolve(
          context,
          base: EdgeInsets.fromLTRB(
            horizontalPad,
            AppSpacing.md,
            horizontalPad,
            AppSpacing.md,
          ),
          chrome: AppBottomChrome.system,
        ),
        children: [
          if (isDesktop)
            const _DesktopSplitSkeleton()
          else ...[
            const _HeaderSkeleton(),
            const SizedBox(height: AppSpacing.md),
            const _InfoSectionSkeleton(),
            const SizedBox(height: AppSpacing.md),
            const _GallerySectionSkeleton(),
            const SizedBox(height: AppSpacing.md),
            const _NotesSectionSkeleton(),
            const SizedBox(height: AppSpacing.lg),
            const _ActionBarSkeleton(),
          ],
        ],
      ),
    );

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: body),
    );
  }
}

class _DesktopSplitSkeleton extends StatelessWidget {
  const _DesktopSplitSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 13,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderSkeleton(),
              SizedBox(height: AppSpacing.md),
              _InfoSectionSkeleton(),
              SizedBox(height: AppSpacing.md),
              _NotesSectionSkeleton(),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GallerySectionSkeleton(),
              SizedBox(height: AppSpacing.md),
              _InfoSectionSkeleton(rows: 4),
              SizedBox(height: AppSpacing.md),
              _ActionBarSkeleton(),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonText(lines: 2, widthFactors: [0.7, 0.35], lineHeight: 16),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SkeletonChip(width: 80, height: 28),
              SkeletonChip(width: 72, height: 28),
              SkeletonChip(width: 96, height: 28),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSectionSkeleton extends StatelessWidget {
  const _InfoSectionSkeleton({this.rows = 5});

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
                  flex: 2,
                  child: SkeletonText(lines: 1, widthFactors: [0.7]),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: SkeletonText(lines: 1, widthFactors: [0.9]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GallerySectionSkeleton extends StatelessWidget {
  const _GallerySectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPanel(
      titleWidthFactor: 0.4,
      child: SkeletonGalleryGrid(tileCount: 6),
    );
  }
}

class _NotesSectionSkeleton extends StatelessWidget {
  const _NotesSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPanel(
      child: SkeletonText(
        lines: 4,
        widthFactors: [1.0, 1.0, 0.85, 0.55],
        lineHeight: 12,
      ),
    );
  }
}

class _ActionBarSkeleton extends StatelessWidget {
  const _ActionBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: SkeletonBox(height: 48)),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: SkeletonBox(height: 48)),
      ],
    );
  }
}
