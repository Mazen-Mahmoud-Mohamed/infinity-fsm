import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';

class OrganizationListTileCard extends StatelessWidget {
  const OrganizationListTileCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;

  String _localizedStatus(AppLocalizations l10n) {
    switch (trailing.toUpperCase()) {
      case 'ACTIVE':
        return l10n.orgStatusActive;
      case 'INACTIVE':
        return l10n.orgStatusInactive;
      default:
        return trailing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    final isActive = trailing.toUpperCase() == 'ACTIVE';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          _localizedStatus(l10n),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isActive ? semantic.success : semantic.warning,
              ),
        ),
      ),
    );
  }
}
