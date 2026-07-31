import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';

class RoleStatusChip extends StatelessWidget {
  const RoleStatusChip({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        isActive ? Icons.check_circle : Icons.pause_circle_outline,
        size: 16,
        color: isActive ? scheme.primary : scheme.outline,
      ),
      label: Text(isActive ? l10n.rolesStatusActive : l10n.rolesStatusInactive),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(
        color: isActive ? scheme.primary.withValues(alpha: 0.4) : scheme.outline,
      ),
    );
  }
}
