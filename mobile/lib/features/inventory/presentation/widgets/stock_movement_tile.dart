import 'package:flutter/material.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/inventory/domain/entities/stock_movement.dart';

class StockMovementTile extends StatelessWidget {
  const StockMovementTile({super.key, required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateFormat = AppFormatters.mediumDateTimeSpaced(context);
    final typeLabel = switch (movement.type) {
      StockMovementType.stockIn => l10n.inventoryStockIn,
      StockMovementType.stockOut => l10n.inventoryStockOut,
      StockMovementType.transfer => l10n.inventoryTransfer,
      StockMovementType.adjustment => l10n.inventoryAdjustment,
    };
    final delta = movement.quantityDelta;
    final deltaText = delta > 0
        ? '+${_formatQty(context, delta)}'
        : _formatQty(context, delta);
    final partName =
        movement.sparePart.name ?? movement.sparePart.partNumber ?? l10n.valueNotSet;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(
            _iconForType(movement.type),
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          '$typeLabel · $partName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              [
                if (movement.user?.name != null) movement.user!.name!,
                if (movement.movementDate != null)
                  dateFormat.format(movement.movementDate!.toLocal()),
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            if (movement.reason != null && movement.reason!.isNotEmpty)
              Text(
                movement.reason!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Text(
          deltaText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: delta < 0
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  IconData _iconForType(StockMovementType type) {
    return switch (type) {
      StockMovementType.stockIn => Icons.add_box_outlined,
      StockMovementType.stockOut => Icons.outbox_outlined,
      StockMovementType.transfer => Icons.swap_horiz,
      StockMovementType.adjustment => Icons.tune,
    };
  }

  String _formatQty(BuildContext context, double value) {
    return AppFormatters.formatDecimalOrInt(context, value);
  }
}
