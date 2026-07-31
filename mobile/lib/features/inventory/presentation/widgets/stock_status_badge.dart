import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';

class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({super.key, required this.status});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final (label, color) = switch (status) {
      StockStatus.inStock => (l10n.inventoryInStock, colorScheme.primary),
      StockStatus.lowStock => (l10n.inventoryLowStock, colorScheme.tertiary),
      StockStatus.outOfStock => (l10n.inventoryOutOfStock, colorScheme.error),
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
