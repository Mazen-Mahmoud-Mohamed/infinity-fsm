import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';

/// Desktop page title — title and optional subtitle only.
///
/// Primary page actions belong in [AppDesktopActionBar], not here.
class AppDesktopPageHeader extends StatelessWidget {
  const AppDesktopPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    @Deprecated('Use a separate AppDesktopActionBar below the title')
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          height: 1.15,
        ) ??
        TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          height: 1.15,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (trailing != null) ...[
          const SizedBox(height: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

/// Desktop sub-page chrome for pushed routes (back + title only).
class AppDesktopSubPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppDesktopSubPageHeader({
    super.key,
    required this.title,
    this.leading,
  });

  final String title;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
        ),
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                if (leading != null) leading!,
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
