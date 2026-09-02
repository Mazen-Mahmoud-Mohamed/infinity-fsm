import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/branding/infinity_brand.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_constants.dart';
import 'package:mobile/features/global_search/presentation/widgets/global_search_dialog.dart';
import 'package:mobile/features/notifications/presentation/widgets/notifications_bell_action.dart';

/// Desktop application top bar — brand, global search, notifications, profile.
class AppDesktopTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppDesktopTopBar({super.key});

  static const double _iconButtonSize = 40;

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppDesktopConstants.topBarHeight);

  IconButtonThemeData _compactIconButtonTheme(
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(_iconButtonSize, _iconButtonSize),
        maximumSize: const Size(_iconButtonSize, _iconButtonSize),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        foregroundColor: scheme.onSurface,
        hoverColor: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

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
        child: Theme(
          data: theme.copyWith(
            iconButtonTheme: _compactIconButtonTheme(theme, scheme),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: AppDesktopConstants.topBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    const _TopBarBrandCluster(),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      width: 1,
                      height: 24,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const GlobalSearchAction(),
                    const Expanded(child: SizedBox.shrink()),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NotificationsBellAction(),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          tooltip: l10n.profile,
                          onPressed: () => context.go(RoutePaths.profile),
                          icon: const Icon(Icons.account_circle_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarBrandCluster extends StatelessWidget {
  const _TopBarBrandCluster();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const InfinityBrandImageView.logo(height: 28),
        const SizedBox(width: AppSpacing.sm),
        Text(
          AppConfig.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
