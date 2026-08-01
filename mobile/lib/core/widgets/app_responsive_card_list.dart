import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';

/// Paginated card list that becomes a multi-column layout on tablet/desktop.
///
/// Cards use **intrinsic height** (no fixed [mainAxisExtent]) so content never
/// overflows a rigid grid cell.
class AppResponsiveCardList extends StatelessWidget {
  const AppResponsiveCardList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.chrome = AppBottomChrome.system,
    this.loadingMore = false,
    this.desktopColumns = 3,
    this.tabletColumns = 2,
    this.spacing = AppSpacing.md,
    @Deprecated('Ignored — cards size to content') double? mainAxisExtent,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final AppBottomChrome chrome;
  final bool loadingMore;
  final int desktopColumns;
  final int tabletColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = AppScrollPadding.resolve(
      context,
      base: padding ?? const EdgeInsets.all(AppSpacing.lg),
      chrome: chrome,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppBreakpoints.gridColumns(
          constraints.maxWidth,
          desktop: desktopColumns,
          tablet: tabletColumns,
        );
        final total = itemCount + (loadingMore ? 1 : 0);

        if (columns <= 1) {
          return ListView.separated(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: resolvedPadding,
            itemCount: total,
            separatorBuilder: (_, _) => SizedBox(height: spacing),
            itemBuilder: (context, index) {
              if (index >= itemCount) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return itemBuilder(context, index);
            },
          );
        }

        final rowCount = (total / columns).ceil();
        return ListView.builder(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: resolvedPadding,
          itemCount: rowCount,
          itemBuilder: (context, rowIndex) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex < rowCount - 1 ? spacing : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) SizedBox(width: spacing),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final index = rowIndex * columns + col;
                          if (index >= itemCount) {
                            if (index == itemCount && loadingMore) {
                              return const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          return itemBuilder(context, index);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
