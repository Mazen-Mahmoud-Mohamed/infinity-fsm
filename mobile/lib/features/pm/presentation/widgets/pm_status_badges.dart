import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';

class PmPlanStatusBadge extends StatelessWidget {
  const PmPlanStatusBadge({super.key, required this.status});

  final PmPlanStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      PmPlanStatus.active => (l10n.pmStatusActive, colorScheme.primary),
      PmPlanStatus.inactive => (l10n.pmStatusInactive, colorScheme.outline),
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

class PmScheduleStatusBadge extends StatelessWidget {
  const PmScheduleStatusBadge({super.key, required this.status});

  final PmScheduleStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      PmScheduleStatus.scheduled =>
        (l10n.pmScheduleScheduled, colorScheme.primary),
      PmScheduleStatus.overdue => (l10n.pmScheduleOverdue, colorScheme.error),
      PmScheduleStatus.completed =>
        (l10n.pmScheduleCompleted, colorScheme.tertiary),
      PmScheduleStatus.cancelled =>
        (l10n.pmScheduleCancelled, colorScheme.outline),
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

class PmPriorityBadge extends StatelessWidget {
  const PmPriorityBadge({super.key, required this.priority});

  final PmPriority priority;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (priority) {
      PmPriority.low => (l10n.pmPriorityLow, colorScheme.outline),
      PmPriority.medium => (l10n.pmPriorityMedium, colorScheme.primary),
      PmPriority.high => (l10n.pmPriorityHigh, colorScheme.tertiary),
      PmPriority.critical => (l10n.pmPriorityCritical, colorScheme.error),
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

String pmFrequencyLabel(AppLocalizations l10n, PmFrequency frequency) {
  return switch (frequency) {
    PmFrequency.daily => l10n.pmFrequencyDaily,
    PmFrequency.weekly => l10n.pmFrequencyWeekly,
    PmFrequency.monthly => l10n.pmFrequencyMonthly,
    PmFrequency.quarterly => l10n.pmFrequencyQuarterly,
    PmFrequency.semiAnnual => l10n.pmFrequencySemiAnnual,
    PmFrequency.annual => l10n.pmFrequencyAnnual,
  };
}

String pmTriggerLabel(AppLocalizations l10n, PmTrigger trigger) {
  return switch (trigger) {
    PmTrigger.timeBased => l10n.pmTriggerTimeBased,
    PmTrigger.meterBased => l10n.pmTriggerMeterBased,
  };
}
