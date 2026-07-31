import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status_snapshot.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_state.dart';
import 'package:mobile/features/attendance/presentation/widgets/attendance_status_badge.dart';
import 'package:mobile/features/attendance/presentation/widgets/working_timer.dart';

class TodayStatusCard extends StatelessWidget {
  const TodayStatusCard({super.key, required this.snapshot});

  final AttendanceStatusSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final timeFormat = AppFormatters.jm(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.attendanceTodayStatus,
                  style: theme.textTheme.titleMedium,
                ),
                AttendanceStatusBadge(status: snapshot.status),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: BlocSelector<AttendanceCubit, AttendanceState, int>(
                selector: (state) =>
                    state.status?.liveWorkingSeconds ??
                    snapshot.liveWorkingSeconds,
                builder: (context, seconds) => WorkingTimer(seconds: seconds),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                l10n.attendanceWorkingHours,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: l10n.attendanceClockIn,
                    value: snapshot.clockInAt != null
                        ? timeFormat.format(snapshot.clockInAt!.toLocal())
                        : '--:--',
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: l10n.attendanceClockOut,
                    value: snapshot.clockOutAt != null
                        ? timeFormat.format(snapshot.clockOutAt!.toLocal())
                        : '--:--',
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: l10n.attendanceBreaks,
                    value:
                        '${snapshot.breakCount} (${snapshot.breakMinutes}m)',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
