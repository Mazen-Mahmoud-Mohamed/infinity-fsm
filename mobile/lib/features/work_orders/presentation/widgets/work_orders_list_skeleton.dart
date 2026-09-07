import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

/// First-load placeholder for the Work Orders list body (search/filters stay
/// mounted by the parent page).
class WorkOrdersListSkeleton extends StatelessWidget {
  const WorkOrdersListSkeleton({
    super.key,
    this.itemCount = 7,
    this.isAdminMode = false,
    this.semanticsLabel,
  });

  final int itemCount;
  final bool isAdminMode;
  final String? semanticsLabel;

  static const int kMaxItems = 8;

  @override
  Widget build(BuildContext context) {
    final count = itemCount.clamp(1, kMaxItems);
    final isDesktop = AppBreakpoints.isDesktopOf(context);

    final body = SkeletonScope(
      child: isDesktop
          ? _DesktopTableSkeleton(
              rowCount: count,
              columnCount: isAdminMode ? 8 : 7,
            )
          : _MobileCardListSkeleton(itemCount: count),
    );

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(child: body),
    );
  }
}

class _MobileCardListSkeleton extends StatelessWidget {
  const _MobileCardListSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: SkeletonText(
                      lines: 2,
                      widthFactors: [0.95, 0.65],
                      lineHeight: 14,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SkeletonBox(
                    width: 72,
                    height: 24,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const SkeletonText(lines: 1, widthFactors: [0.35], lineHeight: 10),
              const SizedBox(height: 6),
              const SkeletonText(lines: 1, widthFactors: [0.55], lineHeight: 12),
              const SizedBox(height: 10),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SkeletonBox(
                    width: 64,
                    height: 22,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  SkeletonBox(
                    width: 96,
                    height: 12,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopTableSkeleton extends StatelessWidget {
  const _DesktopTableSkeleton({
    required this.rowCount,
    required this.columnCount,
  });

  final int rowCount;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: SkeletonTableRow(
            columnCount: columnCount,
            height: 36,
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: rowCount,
            itemBuilder: (context, index) {
              return SkeletonTableRow(columnCount: columnCount);
            },
          ),
        ),
      ],
    );
  }
}
