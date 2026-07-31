import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status});

  final ServiceReportStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      ServiceReportStatus.draft => (l10n.reportsStatusDraft, colorScheme.outline),
      ServiceReportStatus.generated =>
        (l10n.reportsStatusGenerated, colorScheme.primary),
      ServiceReportStatus.downloaded =>
        (l10n.reportsStatusDownloaded, colorScheme.tertiary),
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
