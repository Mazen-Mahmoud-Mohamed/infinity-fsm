import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_list_card.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

/// Permission-filtered admin shortcuts that are NOT on bottom navigation.
class DashboardQuickActionsGrid extends StatelessWidget {
  const DashboardQuickActionsGrid({
    super.key,
    required this.permissions,
  });

  final PermissionChecker? permissions;

  static bool hasVisibleActions(PermissionChecker? permissions) {
    final checker = permissions;
    if (checker == null) return false;
    return checker.canViewUsers() ||
        checker.canViewRoles() ||
        checker.canViewInventory() ||
        checker.canViewAssets() ||
        checker.canViewPm() ||
        checker.canViewReports();
  }

  List<_QuickAction> _actions(AppLocalizations l10n) {
    final checker = permissions;
    if (checker == null) return const [];

    return [
      if (checker.canViewUsers())
        _QuickAction(
          label: l10n.usersTitle,
          icon: Icons.manage_accounts_outlined,
          route: RoutePaths.users,
        ),
      if (checker.canViewRoles())
        _QuickAction(
          label: l10n.rolesTitle,
          icon: Icons.admin_panel_settings_outlined,
          route: RoutePaths.roles,
        ),
      if (checker.canViewInventory())
        _QuickAction(
          label: l10n.inventory,
          icon: Icons.inventory_2_outlined,
          route: RoutePaths.inventory,
        ),
      if (checker.canViewAssets())
        _QuickAction(
          label: l10n.assets,
          icon: Icons.precision_manufacturing_outlined,
          route: RoutePaths.assets,
        ),
      if (checker.canViewPm())
        _QuickAction(
          label: l10n.pmTitle,
          icon: Icons.build_circle_outlined,
          route: RoutePaths.pm,
        ),
      if (checker.canViewReports())
        _QuickAction(
          label: l10n.reportsCenter,
          icon: Icons.analytics_outlined,
          route: RoutePaths.reports,
        ),
    ];
  }

  int _columnsFor(double width) {
    if (width >= AppBreakpoints.tabletMax) return 4;
    if (width >= AppBreakpoints.phoneMax) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = _actions(l10n);
    if (actions.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= AppBreakpoints.tabletMax;

        if (isDesktop) {
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final action in actions)
                _DesktopQuickActionChip(
                  label: action.label,
                  icon: action.icon,
                  onTap: () => context.push(action.route),
                ),
            ],
          );
        }

        final columns = _columnsFor(width);
        const spacing = AppSpacing.sm;
        final aspectRatio = width < 340
            ? 1.15
            : width < 400
                ? 1.1
                : width < 600
                    ? 1.05
                    : 1.2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _QuickActionTile(
              label: action.label,
              icon: action.icon,
              onTap: () => context.push(action.route),
            );
          },
        );
      },
    );
  }
}

class _DesktopQuickActionChip extends StatelessWidget {
  const _DesktopQuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppListCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 360;
    final iconBox = compact ? 34.0 : 40.0;
    final iconSize = compact ? 18.0 : 22.0;
    final pad = compact ? AppSpacing.sm : AppSpacing.md;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: iconSize, color: colorScheme.primary),
              ),
              SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      fontSize: compact ? 12 : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
