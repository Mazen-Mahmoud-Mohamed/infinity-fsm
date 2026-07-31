import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';

class UserStatusBadge extends StatelessWidget {
  const UserStatusBadge({super.key, required this.status});

  final ManagedUserStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      ManagedUserStatus.active => (l10n.usersStatusActive, colorScheme.primary),
      ManagedUserStatus.disabled =>
        (l10n.usersStatusDisabled, colorScheme.outline),
      ManagedUserStatus.locked => (l10n.usersStatusLocked, colorScheme.error),
    };

    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
