import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_surface.dart';

/// Scrollable Material [DataTable] wrapped in a desktop surface.
class AppDesktopDataTable extends StatelessWidget {
  /// Shared row height — [DataTable.dataRowMaxHeight] must be >= [DataTable.dataRowMinHeight].
  static const double desktopRowHeight = 52;

  const AppDesktopDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.controller,
    this.loadingMore = false,
    this.minWidth,
    this.columnMinWidth = 132,
    this.expandVertically = false,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final ScrollController? controller;
  final bool loadingMore;
  final double? minWidth;
  final double columnMinWidth;
  final bool expandVertically;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final computedMinWidth = minWidth ??
            [
              viewportWidth,
              columns.length * columnMinWidth,
            ].reduce((a, b) => a > b ? a : b);

        final table = DataTable(
          showCheckboxColumn: false,
          dataRowMinHeight: desktopRowHeight,
          dataRowMaxHeight: desktopRowHeight,
          headingRowHeight: desktopRowHeight,
          columnSpacing: AppSpacing.lg,
          horizontalMargin: AppSpacing.md,
          dividerThickness: 1,
          headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          columns: columns,
          rows: [
            for (final row in rows)
              DataRow(
                onSelectChanged: row.onSelectChanged,
                color: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return scheme.surfaceContainerHighest
                        .withValues(alpha: 0.55);
                  }
                  if (states.contains(WidgetState.selected)) {
                    return scheme.primaryContainer.withValues(alpha: 0.35);
                  }
                  return null;
                }),
                cells: row.cells,
              ),
            if (loadingMore)
              DataRow(
                cells: List.generate(
                  columns.length,
                  (index) => index == 0
                      ? const DataCell(
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const DataCell(SizedBox.shrink()),
                ),
              ),
          ],
        );

        final tableContent = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          primary: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: computedMinWidth),
            child: table,
          ),
        );

        final body = AppDesktopSurface(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Scrollbar(
              thumbVisibility: true,
              controller: controller,
              child: SingleChildScrollView(
                controller: controller,
                primary: controller == null,
                physics: expandVertically && constraints.hasBoundedHeight
                    ? const AlwaysScrollableScrollPhysics()
                    : null,
                child: tableContent,
              ),
            ),
          ),
        );

        if (expandVertically && constraints.hasBoundedHeight) {
          return SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: body,
          );
        }

        return body;
      },
    );
  }
}
