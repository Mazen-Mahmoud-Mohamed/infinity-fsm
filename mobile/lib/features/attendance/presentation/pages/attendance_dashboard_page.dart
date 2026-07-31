import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status_snapshot.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_state.dart';
import 'package:mobile/features/attendance/presentation/widgets/attendance_timeline.dart';
import 'package:mobile/features/attendance/presentation/widgets/clock_action_buttons.dart';
import 'package:mobile/features/attendance/presentation/widgets/today_status_card.dart';
import 'package:mobile/features/organization/presentation/widgets/offline_banner.dart';

class AttendanceDashboardPage extends StatelessWidget {
  const AttendanceDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AttendanceCubit>()..initialize(),
      child: const _AttendanceDashboardView(),
    );
  }
}

class _AttendanceDashboardView extends StatelessWidget {
  const _AttendanceDashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<AttendanceCubit, AttendanceState>(
      listenWhen: (previous, current) =>
          previous.message != current.message &&
          current.message != null &&
          !current.isOffline &&
          !isUserFacingNetworkNoise(current.message),
      listener: (context, state) {
        if (state.message == null ||
            isUserFacingNetworkNoise(state.message)) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(localizeAppMessage(l10n, state.message)),
              backgroundColor: state.isError
                  ? Theme.of(context).colorScheme.error
                  : AppThemeColors.of(context).success,
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.attendance),
          actions: [
            IconButton(
              tooltip: l10n.attendanceHistoryTooltip,
              icon: const Icon(Icons.history),
              onPressed: () => context.push(RoutePaths.attendanceHistory),
            ),
          ],
        ),
        body: BlocBuilder<AttendanceCubit, AttendanceState>(
          buildWhen: (previous, current) {
            if (previous.loadStatus != current.loadStatus ||
                previous.isRefreshing != current.isRefreshing ||
                previous.message != current.message ||
                previous.isOffline != current.isOffline ||
                previous.isError != current.isError ||
                previous.today != current.today) {
              return true;
            }
            final prev = previous.status;
            final next = current.status;
            if (identical(prev, next)) {
              return false;
            }
            if (prev == null || next == null) {
              return prev != next;
            }
            return prev.status != next.status ||
                prev.clockInAt != next.clockInAt ||
                prev.clockOutAt != next.clockOutAt ||
                prev.breakCount != next.breakCount ||
                prev.breakMinutes != next.breakMinutes ||
                prev.workingMinutes != next.workingMinutes;
          },
          builder: (context, state) {
            if (state.loadStatus == AttendanceLoadStatus.loading &&
                state.status == null) {
              return AppLoader(message: l10n.attendanceLoading);
            }

            if (state.loadStatus == AttendanceLoadStatus.failure &&
                state.status == null &&
                !state.isOffline &&
                !isUserFacingNetworkNoise(state.message)) {
              return _ErrorView(
                message: localizeAppMessage(l10n, state.message),
                onRetry: () => context.read<AttendanceCubit>().refresh(),
              );
            }

            final snapshot =
                state.status ?? AttendanceStatusSnapshot.empty();

            return Column(
              children: [
                AppRefreshBar(visible: state.isRefreshing),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<AttendanceCubit>().refresh(),
                    child: ListView(
                      padding: AppScrollPadding.resolve(
                        context,
                        base: const EdgeInsets.all(AppSpacing.lg),
                        chrome: AppBottomChrome.system,
                      ),
                      children: [
                        TodayStatusCard(snapshot: snapshot),
                        const SizedBox(height: AppSpacing.lg),
                        ClockActionButtons(
                          status: snapshot.status,
                          isBusy: state.loadStatus ==
                              AttendanceLoadStatus.actionInProgress,
                          onClockIn: () =>
                              context.read<AttendanceCubit>().clockIn(),
                          onClockOut: () =>
                              context.read<AttendanceCubit>().clockOut(),
                          onStartBreak: () =>
                              context.read<AttendanceCubit>().startBreak(),
                          onEndBreak: () =>
                              context.read<AttendanceCubit>().endBreak(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.attendanceTimeline,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AttendanceTimeline(
                          events: state.today?.events ?? const [],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
