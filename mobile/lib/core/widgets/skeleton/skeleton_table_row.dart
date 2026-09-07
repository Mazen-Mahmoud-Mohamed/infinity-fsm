import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/skeleton/skeleton_box.dart';

/// Desktop table row bone with [columnCount] cells.
class SkeletonTableRow extends StatelessWidget {
  const SkeletonTableRow({
    super.key,
    required this.columnCount,
    this.height = 44,
    this.flexes,
  });

  final int columnCount;
  final double height;
  final List<int>? flexes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final counts = columnCount.clamp(1, 12);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i < counts; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: flexes != null && i < flexes!.length ? flexes![i] : 1,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: i == 0 ? 0.7 : (i.isEven ? 0.85 : 0.55),
                      child: SkeletonBox(
                        height: 12,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
