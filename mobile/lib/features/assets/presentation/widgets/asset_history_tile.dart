import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/assets/domain/entities/asset_history.dart';

class AssetHistoryTile extends StatelessWidget {
  const AssetHistoryTile({super.key, required this.item});

  final AssetHistory item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateFormat = AppFormatters.mediumDateTimeSpaced(context);
    final typeLabel = switch (item.type) {
      AssetHistoryType.installation => l10n.assetsHistoryInstallation,
      AssetHistoryType.maintenance => l10n.assetsHistoryMaintenance,
      AssetHistoryType.repair => l10n.assetsHistoryRepair,
      AssetHistoryType.inspection => l10n.assetsHistoryInspection,
      AssetHistoryType.statusChange => l10n.assetsHistoryStatusChange,
      AssetHistoryType.created => l10n.assetsHistoryCreated,
      AssetHistoryType.updated => l10n.assetsHistoryUpdated,
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.timeline, color: theme.colorScheme.primary),
        ),
        title: Text(item.title ?? typeLabel),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(typeLabel, style: theme.textTheme.bodySmall),
            if (item.eventDate != null)
              Text(
                dateFormat.format(item.eventDate!.toLocal()),
                style: theme.textTheme.bodySmall,
              ),
            if (item.user?.name != null)
              Text(item.user!.name!, style: theme.textTheme.bodySmall),
            if (item.description != null && item.description!.isNotEmpty)
              Text(
                item.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
