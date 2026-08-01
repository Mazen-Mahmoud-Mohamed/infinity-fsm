import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/branding/infinity_brand.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_summary.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_history_cubit.dart';
import 'package:mobile/features/attendance/presentation/widgets/attendance_status_badge.dart';

class AttendanceHistoryPage extends StatelessWidget {
  const AttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AttendanceHistoryCubit>()..loadFirstPage(),
      child: const _AttendanceHistoryView(),
    );
  }
}

class _AttendanceHistoryView extends StatefulWidget {
  const _AttendanceHistoryView();

  @override
  State<_AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends State<_AttendanceHistoryView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AttendanceHistoryCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.attendanceHistoryTitle)),
      body: BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
        builder: (context, state) {
          if (state.status == AttendanceHistoryStatus.loading &&
              state.items.isEmpty) {
            return AppLoader(message: l10n.attendanceHistoryLoading);
          }

          if (state.status == AttendanceHistoryStatus.failure &&
              state.items.isEmpty) {
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
                      localizeAppMessage(l10n, state.message),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<AttendanceHistoryCubit>().loadFirstPage(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const InfinityEmptyBrandMark(size: 56),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.attendanceHistoryEmpty),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context
                      .read<AttendanceHistoryCubit>()
                      .loadFirstPage(forceRefresh: true),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: AppScrollPadding.resolve(
                      context,
                      base: const EdgeInsets.all(AppSpacing.md),
                      chrome: AppBottomChrome.system,
                    ),
                    itemCount: state.items.length +
                        (state.status == AttendanceHistoryStatus.loadingMore
                            ? 1
                            : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _HistoryTile(item: state.items[index]);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final AttendanceSummaryEntity item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.weekdayMonthDay(context);
    final timeFormat = AppFormatters.jm(context);
    final date = DateTime.tryParse(item.date) ?? DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(date),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                AttendanceStatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    label: l10n.attendanceClockIn,
                    value: item.clockInAt != null
                        ? timeFormat.format(item.clockInAt!.toLocal())
                        : '--:--',
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: l10n.attendanceClockOut,
                    value: item.clockOutAt != null
                        ? timeFormat.format(item.clockOutAt!.toLocal())
                        : '--:--',
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: l10n.attendanceStatusWorking,
                    value: DurationFormatter.fromMinutes(
                      item.workingMinutes,
                      l10n,
                    ),
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: l10n.attendanceBreaks,
                    value: '${item.breakCount}',
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

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
