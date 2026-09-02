import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/config/app_config.dart';
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

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppDesktopConstants.topBarHeight);

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
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: AppDesktopConstants.topBarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  const InfinityBrandImageView.logo(height: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      AppConfig.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  const GlobalSearchAction(),
                  const Spacer(),
                  const NotificationsBellAction(),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: l10n.profile,
                    onPressed: () => context.go(RoutePaths.profile),
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
