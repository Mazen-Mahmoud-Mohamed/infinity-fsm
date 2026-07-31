import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';

class AssetStatusBadge extends StatelessWidget {
  const AssetStatusBadge({super.key, required this.status});

  final AssetStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      AssetStatus.active => (l10n.assetsStatusActive, colorScheme.primary),
      AssetStatus.maintenance =>
        (l10n.assetsStatusMaintenance, colorScheme.tertiary),
      AssetStatus.offline => (l10n.assetsStatusOffline, colorScheme.outline),
      AssetStatus.retired => (l10n.assetsStatusRetired, colorScheme.error),
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
