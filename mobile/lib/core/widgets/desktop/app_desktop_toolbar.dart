import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';

/// Horizontal desktop toolbar: search, filters, and trailing actions.
class AppDesktopToolbar extends StatelessWidget {
  const AppDesktopToolbar({
    super.key,
    this.search,
    this.filters,
    this.actions = const [],
    this.searchFlex = 2,
  });

  final Widget? search;
  final Widget? filters;
  final List<Widget> actions;
  final int searchFlex;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (search != null)
          Expanded(
            flex: searchFlex,
            child: search!,
          ),
        if (filters != null) ...[
          const SizedBox(width: AppSpacing.md),
          Flexible(
            flex: 3,
            child: filters!,
          ),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.md),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            actions[i],
          ],
        ],
      ],
    );
  }
}
