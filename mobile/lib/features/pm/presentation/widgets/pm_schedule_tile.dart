import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/presentation/widgets/pm_status_badges.dart';

class PmScheduleTile extends StatelessWidget {
  const PmScheduleTile({
    super.key,
    required this.schedule,
    this.onTap,
    this.trailing,
  });

  final MaintenanceSchedule schedule;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDate(context);
    final planName = schedule.plan.name ?? l10n.pmPlans;
    final code = schedule.plan.code;
    final date = schedule.scheduledDate;

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(planName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (code != null && code.isNotEmpty)
              Text(code, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              date != null
                  ? '${l10n.pmScheduledDate}: ${dateFormat.format(date.toLocal())}'
                  : l10n.pmScheduledDate,
            ),
            const SizedBox(height: AppSpacing.xs),
            PmScheduleStatusBadge(status: schedule.status),
          ],
        ),
        isThreeLine: true,
        trailing: trailing,
      ),
    );
  }
}
