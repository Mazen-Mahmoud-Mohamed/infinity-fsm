import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_event.dart';

class AttendanceTimeline extends StatelessWidget {
  const AttendanceTimeline({super.key, required this.events});

  final List<AttendanceEventEntity> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          l10n.attendanceTimelineEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final timeFormat = AppFormatters.jm(context);

    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineTile(
            event: events[i],
            isLast: i == events.length - 1,
            timeFormat: timeFormat,
          ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.isLast,
    required this.timeFormat,
  });

  final AttendanceEventEntity event;
  final bool isLast;
  final DateFormat timeFormat;

  (IconData, Color, String) _presentation(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final colors = Theme.of(context).colorScheme;
    final semantic = AppThemeColors.of(context);
    switch (event.type) {
      case AttendanceEventType.clockIn:
        return (Icons.login, semantic.success, l10n.attendanceEventClockedIn);
      case AttendanceEventType.clockOut:
        return (Icons.logout, colors.primary, l10n.attendanceEventClockedOut);
      case AttendanceEventType.breakStart:
        return (
          Icons.pause_circle_outline,
          semantic.warning,
          l10n.attendanceEventBreakStarted,
        );
      case AttendanceEventType.breakEnd:
        return (
          Icons.play_circle_outline,
          semantic.warning,
          l10n.attendanceEventBreakEnded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final (icon, color, label) = _presentation(context, l10n);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    timeFormat.format(event.at.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (event.source == 'OFFLINE_SYNC') ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.attendanceSyncedOffline,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppThemeColors.of(context).warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
