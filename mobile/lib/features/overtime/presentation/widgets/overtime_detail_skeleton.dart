import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

/// First-load placeholder when Overtime Details has no loaded session yet.
class OvertimeDetailSkeleton extends StatelessWidget {
  const OvertimeDetailSkeleton({
    super.key,
    this.semanticsLabel,
  });

  final String? semanticsLabel;

  static const int kSessionRows = 6;
  static const int kTimelineStages = 4;

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktopOf(context);
    final pad = isDesktop ? AppSpacing.xl : AppSpacing.lg;

    final body = SkeletonScope(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppScrollPadding.resolve(
          context,
          base: EdgeInsets.all(pad),
          chrome: AppBottomChrome.system,
        ),
        children: [
          if (isDesktop)
            const _DesktopOvertimeDetailSkeleton()
          else ...[
            const _TechnicianSectionSkeleton(),
            const SizedBox(height: AppSpacing.lg),
            const _SessionSectionSkeleton(),
            const SizedBox(height: AppSpacing.lg),
            const _TimelineSectionSkeleton(),
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

class _DesktopOvertimeDetailSkeleton extends StatelessWidget {
  const _DesktopOvertimeDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _TechnicianSectionSkeleton()),
            SizedBox(width: AppSpacing.lg),
            Expanded(flex: 13, child: _SessionSectionSkeleton()),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        _TimelineSectionSkeleton(),
        SizedBox(height: AppSpacing.lg),
        _JourneyOverviewSkeleton(),
      ],
    );
  }
}

class _TechnicianSectionSkeleton extends StatelessWidget {
  const _TechnicianSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPanel(
      titleWidthFactor: 0.45,
      child: Column(
        children: [
          _LabelValueBone(),
          SizedBox(height: AppSpacing.sm),
          _LabelValueBone(valueFactor: 0.85),
          SizedBox(height: AppSpacing.sm),
          _LabelValueBone(valueFactor: 0.55),
        ],
      ),
    );
  }
}

class _SessionSectionSkeleton extends StatelessWidget {
  const _SessionSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPanel(
      titleWidthFactor: 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SkeletonChip(width: 88, height: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < OvertimeDetailSkeleton.kSessionRows; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _LabelValueBone(
              valueFactor: i.isEven ? 0.7 : 0.9,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineSectionSkeleton extends StatelessWidget {
  const _TimelineSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPanel(
      titleWidthFactor: 0.42,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonBox(height: 10),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < OvertimeDetailSkeleton.kTimelineStages; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            const _TimelineStageBone(),
          ],
        ],
      ),
    );
  }
}

class _JourneyOverviewSkeleton extends StatelessWidget {
  const _JourneyOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPanel(
      titleWidthFactor: 0.38,
      child: SkeletonBox(height: 180),
    );
  }
}

class _TimelineStageBone extends StatelessWidget {
  const _TimelineStageBone();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonCircle(size: 28),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SkeletonText(
            lines: 2,
            widthFactors: [0.45, 0.7],
            lineHeight: 12,
          ),
        ),
      ],
    );
  }
}

class _LabelValueBone extends StatelessWidget {
  const _LabelValueBone({this.valueFactor = 0.8});

  final double valueFactor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 2,
          child: SkeletonText(lines: 1, widthFactors: [0.7]),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: SkeletonText(lines: 1, widthFactors: [valueFactor]),
        ),
      ],
    );
  }
}
