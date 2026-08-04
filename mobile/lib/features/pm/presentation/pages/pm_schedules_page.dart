import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_schedules_history_cubits.dart';
import 'package:mobile/features/pm/presentation/widgets/pm_schedule_tile.dart';

class PmSchedulesPage extends StatefulWidget {
  const PmSchedulesPage({
    super.key,
    this.initialStatus,
    this.planId,
  });

  final PmScheduleStatus? initialStatus;
  final String? planId;

  @override
  State<PmSchedulesPage> createState() => _PmSchedulesPageState();
}

class _PmSchedulesPageState extends State<PmSchedulesPage> {
  late final PmSchedulesCubit _cubit;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<PmSchedulesCubit>(
      param1: widget.planId ?? '',
      param2: widget.initialStatus?.apiValue ?? '',
    )..loadFirstPage(status: widget.initialStatus);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  Future<void> _complete(MaintenanceSchedule schedule) async {
    final l10n = AppLocalizations.of(context);
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pmCompleteSchedule),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(labelText: l10n.pmNotes),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.pmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.pmCompleteSchedule),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      notesController.dispose();
      return;
    }
    final result = await _cubit.complete(
      schedule.id,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );
    notesController.dispose();
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pmScheduleCompleted)),
        );
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  Future<void> _cancel(MaintenanceSchedule schedule) async {
    final l10n = AppLocalizations.of(context);
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pmCancelSchedule),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(labelText: l10n.pmNotes),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.pmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.pmCancelSchedule),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      notesController.dispose();
      return;
    }
    final result = await _cubit.cancel(
      schedule.id,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );
    notesController.dispose();
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pmScheduleCancelled)),
        );
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canUpdate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canUpdatePm() == true,
    );

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.pmSchedules)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.pmSearchSchedulesHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _cubit.search,
              ),
            ),
            BlocBuilder<PmSchedulesCubit, PmSchedulesState>(
              buildWhen: (p, c) => p.filterStatus != c.filterStatus,
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(l10n.pmFilterAll),
                        selected: state.filterStatus == null,
                        onSelected: (_) => _cubit.setFilter(null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...PmScheduleStatus.values.map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text(switch (status) {
                              PmScheduleStatus.scheduled =>
                                l10n.pmScheduleScheduled,
                              PmScheduleStatus.overdue =>
                                l10n.pmScheduleOverdue,
                              PmScheduleStatus.completed =>
                                l10n.pmScheduleCompleted,
                              PmScheduleStatus.cancelled =>
                                l10n.pmScheduleCancelled,
                            }),
                            selected: state.filterStatus == status,
                            onSelected: (_) => _cubit.setFilter(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            BlocSelector<PmSchedulesCubit, PmSchedulesState, bool>(
              selector: (state) => state.isRefreshing,
              builder: (context, refreshing) =>
                  AppRefreshBar(visible: refreshing),
            ),
            Expanded(
              child: BlocBuilder<PmSchedulesCubit, PmSchedulesState>(
                builder: (context, state) {
                  if ((state.status == PmSchedulesStatus.loading ||
                          state.status == PmSchedulesStatus.initial) &&
                      state.items.isEmpty) {
                    return AppLoader(message: l10n.pmLoading);
                  }
                  if (state.status == PmSchedulesStatus.failure &&
                      state.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.pmLoadFailed,
                        ),
                          FilledButton(
                            onPressed: () => _cubit.loadFirstPage(),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state.items.isEmpty) {
                    return Center(child: Text(l10n.pmSchedulesEmpty));
                  }
                  return RefreshIndicator(
                    onRefresh: () => _cubit.loadFirstPage(),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: AppScrollPadding.resolve(
                        context,
                        base: const EdgeInsets.all(AppSpacing.md),
                        chrome: AppBottomChrome.system,
                      ),
                      itemCount:
                          state.items.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final schedule = state.items[index];
                        final actionable = canUpdate &&
                            (schedule.status == PmScheduleStatus.scheduled ||
                                schedule.status == PmScheduleStatus.overdue);
                        return PmScheduleTile(
                          schedule: schedule,
                          trailing: actionable
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'complete') {
                                      _complete(schedule);
                                    } else if (value == 'cancel') {
                                      _cancel(schedule);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'complete',
                                      child: Text(l10n.pmCompleteSchedule),
                                    ),
                                    PopupMenuItem(
                                      value: 'cancel',
                                      child: Text(l10n.pmCancelSchedule),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
