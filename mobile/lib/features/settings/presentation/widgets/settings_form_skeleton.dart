import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

/// First-load placeholder for settings forms that fetch remote configuration.
class SettingsFormSkeleton extends StatelessWidget {
  const SettingsFormSkeleton({
    super.key,
    this.fieldCount = 8,
    this.showAvatar = true,
    this.semanticsLabel,
  });

  final int fieldCount;
  final bool showAvatar;
  final String? semanticsLabel;

  static const int kMaxFields = 8;

  @override
  Widget build(BuildContext context) {
    final count = fieldCount.clamp(1, kMaxFields);
    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: SkeletonScope(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppScrollPadding.resolve(
              context,
              base: const EdgeInsets.all(AppSpacing.md),
              chrome: AppBottomChrome.system,
            ),
            children: [
              if (showAvatar) ...[
                const Center(child: SkeletonCircle(size: 80)),
                const SizedBox(height: AppSpacing.lg),
              ],
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                const SkeletonBox(height: 48),
              ],
              const SizedBox(height: AppSpacing.xl),
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SizedBox(
                  width: 120,
                  child: SkeletonBox(height: 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
