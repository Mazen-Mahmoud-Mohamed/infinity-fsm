import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_quick_card.dart';

class DashboardKpiItem {
  const DashboardKpiItem({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
}

class DashboardKpiGrid extends StatelessWidget {
  const DashboardKpiGrid({
    super.key,
    required this.items,
    this.compact = false,
  });

  final List<DashboardKpiItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 600
                ? 2
                : 1;

        if (crossAxisCount == 1) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: DashboardQuickCard(
                    title: items[i].title,
                    subtitle: items[i].value,
                    icon: items[i].icon,
                    compact: compact,
                    onTap: items[i].onTap ?? () {},
                  ),
                ),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += crossAxisCount) {
          final rowItems = items.skip(i).take(crossAxisCount).toList();
          rows.add(
            Padding(
              padding: EdgeInsets.only(
                bottom: i + crossAxisCount < items.length ? AppSpacing.md : 0,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < crossAxisCount; j++) ...[
                      if (j > 0) const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: j < rowItems.length
                            ? DashboardQuickCard(
                                title: rowItems[j].title,
                                subtitle: rowItems[j].value,
                                icon: rowItems[j].icon,
                                compact: compact,
                                onTap: rowItems[j].onTap ?? () {},
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
