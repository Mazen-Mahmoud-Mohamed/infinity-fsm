import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_state.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_sync_cubit.dart';
import 'package:mobile/features/attendance/presentation/widgets/attendance_status_badge.dart';
import 'package:mobile/features/attendance/presentation/widgets/working_timer.dart';

/// Compact attendance overview embedded in the main Dashboard, showing the
/// employee's live clock status without leaving the Dashboard tab.
class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AttendanceCubit>()..initialize(),
      child: const _AttendanceSummaryCardView(),
    );
  }
}

class _AttendanceSummaryCardView extends StatelessWidget {
  const _AttendanceSummaryCardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final timeFormat = AppFormatters.jm(context);
    final pendingCount = context.watch<AttendanceSyncCubit>().state.pendingCount;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(RoutePaths.attendance),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BlocBuilder<AttendanceCubit, AttendanceState>(
            buildWhen: (previous, current) {
              if (previous.loadStatus != current.loadStatus) {
                return true;
              }
              final prev = previous.status;
              final next = current.status;
              if (prev == null || next == null) {
                return prev != next;
              }
              return prev.status != next.status ||
                  prev.clockInAt != next.clockInAt ||
                  prev.clockOutAt != next.clockOutAt ||
                  prev.liveWorkingSeconds != next.liveWorkingSeconds;
            },
            builder: (context, state) {
              if (state.loadStatus == AttendanceLoadStatus.loading &&
                  state.status == null) {
                return const SizedBox(
                  height: 80,
                  child: AppLoader(),
                );
              }

              final snapshot = state.status;
              final warning = AppThemeColors.of(context).warning;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.attendance,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (snapshot != null)
                        AttendanceStatusBadge(status: snapshot.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: l10n.attendanceClockIn,
                          value: snapshot?.clockInAt != null
                              ? timeFormat.format(snapshot!.clockInAt!.toLocal())
                              : '--:--',
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: l10n.attendanceClockOut,
                          value: snapshot?.clockOutAt != null
                              ? timeFormat.format(snapshot!.clockOutAt!.toLocal())
                              : '--:--',
                        ),
                      ),
                      Expanded(
                        child: WorkingTimer(
                          seconds: snapshot?.liveWorkingSeconds ?? 0,
                        ),
                      ),
                    ],
                  ),
                  if (pendingCount > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.sync, size: 16, color: warning),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.attendancePendingOfflineRecords(pendingCount),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
