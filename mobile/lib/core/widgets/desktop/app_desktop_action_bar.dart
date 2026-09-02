import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';

/// Compact desktop action row — bounded, non-collapsing primary actions.
///
/// Do not wrap individual buttons in [Expanded] or [Flexible].
class AppDesktopActionBar extends StatelessWidget {
  const AppDesktopActionBar({
    super.key,
    required this.children,
    this.alignment = AlignmentDirectional.centerStart,
    this.padding,
  });

  final List<Widget> children;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry? padding;

  MainAxisAlignment get _rowAlignment {
    if (alignment == AlignmentDirectional.centerEnd ||
        alignment == AlignmentDirectional.topEnd ||
        alignment == AlignmentDirectional.bottomEnd) {
      return MainAxisAlignment.end;
    }
    return MainAxisAlignment.start;
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: _rowAlignment,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            children[i],
          ],
        ],
      ),
    );
  }
}
