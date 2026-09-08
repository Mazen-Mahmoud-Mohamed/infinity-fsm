import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

/// First-load placeholder for the technician overtime tracking screen.
///
/// Mirrors the idle Start form (title, notes, travel rows, voice, CTA).
class OvertimeTrackingSkeleton extends StatelessWidget {
  const OvertimeTrackingSkeleton({
    super.key,
    this.semanticsLabel,
  });

  final String? semanticsLabel;

  static const int kCheckboxRows = 2;

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktopOf(context);
    final pad = isDesktop ? AppSpacing.xl : AppSpacing.lg;

    final form = const _StartFormSkeleton();
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
            AppPageFrame(
              maxWidth: AppBreakpoints.contentWideMax,
              child: form,
            )
          else
            form,
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

class _StartFormSkeleton extends StatelessWidget {
  const _StartFormSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: 0.55,
            child: SkeletonBox(height: 22),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        SkeletonBox(height: 88, borderRadius: BorderRadius.all(Radius.circular(8))),
        SizedBox(height: AppSpacing.md),
        _CheckboxRowBone(titleFactor: 0.42),
        SizedBox(height: AppSpacing.sm),
        _CheckboxRowBone(titleFactor: 0.5, indent: AppSpacing.lg),
        SizedBox(height: AppSpacing.md),
        SkeletonPanel(
          titleWidthFactor: 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonBox(height: 44),
              SizedBox(height: AppSpacing.sm),
              SkeletonText(lines: 2, widthFactors: [0.7, 0.45]),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 52, borderRadius: BorderRadius.all(Radius.circular(12))),
      ],
    );
  }
}

class _CheckboxRowBone extends StatelessWidget {
  const _CheckboxRowBone({
    required this.titleFactor,
    this.indent = 0,
  });

  final double titleFactor;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent),
      child: Row(
        children: [
          const SkeletonBox(
            width: 22,
            height: 22,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FractionallySizedBox(
              widthFactor: titleFactor,
              alignment: AlignmentDirectional.centerStart,
              child: const SkeletonBox(height: 14),
            ),
          ),
          const SkeletonBox(
            width: 22,
            height: 22,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}
