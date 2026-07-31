import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_plan_detail_form_checklist_cubits.dart';
import 'package:mobile/features/pm/presentation/widgets/pm_status_badges.dart';

class PmPlanDetailPage extends StatefulWidget {
  const PmPlanDetailPage({super.key, required this.planId});

  final String planId;

  @override
  State<PmPlanDetailPage> createState() => _PmPlanDetailPageState();
}

class _PmPlanDetailPageState extends State<PmPlanDetailPage> {
  late final PmPlanDetailCubit _cubit;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<PmPlanDetailCubit>(param1: widget.planId)..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _generateSchedules() async {
    final l10n = AppLocalizations.of(context);
    final result = await _cubit.generateSchedules();
    if (!mounted) return;
    switch (result) {
      case Success(data: final count):
        _changed = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pmSchedulesGenerated(count))),
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
    final dateFormat = AppFormatters.mediumDate(context);
    final canUpdate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canUpdatePm() == true,
    );
    final canDelete = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canDeletePm() == true,
    );
    final canCreate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canCreatePm() == true,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: BlocProvider.value(
        value: _cubit,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.pmPlanDetails),
            actions: [
              if (canUpdate)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final changed = await context.push<bool>(
                      RoutePaths.pmPlanFormEdit(widget.planId),
                    );
                    if (changed == true && mounted) {
                      _changed = true;
                      await _cubit.load();
                    }
                  },
                ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.pmDeletePlan),
                        content: Text(l10n.pmDeletePlanConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.pmCancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.pmDeletePlan),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    final result = await _cubit.delete();
                    if (!context.mounted) return;
                    switch (result) {
                      case Success():
                        Navigator.of(context).pop(true);
                      case Failure(message: final message):
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(localizeAppMessage(l10n, message))),
                        );
                    }
                  },
                ),
            ],
          ),
          body: BlocBuilder<PmPlanDetailCubit, PmPlanDetailState>(
            buildWhen: (p, c) =>
                p.status != c.status ||
                p.plan != c.plan ||
                p.message != c.message ||
                p.isRefreshing != c.isRefreshing,
            builder: (context, state) {
              if ((state.status == PmPlanDetailStatus.loading ||
                      state.status == PmPlanDetailStatus.initial) &&
                  state.plan == null) {
                return AppLoader(message: l10n.pmLoading);
              }
              if (state.status == PmPlanDetailStatus.failure &&
                  state.plan == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message ?? l10n.pmLoadFailed),
                      FilledButton(
                        onPressed: _cubit.load,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              }

              final plan = state.plan!;
              return Column(
                children: [
                  AppRefreshBar(visible: state.isRefreshing),
                  Expanded(
                    child: RefreshIndicator(
                onRefresh: _cubit.load,
                child: ListView(
                  padding: AppScrollPadding.resolve(
                    context,
                    base: const EdgeInsets.all(AppSpacing.md),
                    chrome: AppBottomChrome.system,
                  ),
                  children: [
                    Text(plan.name,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(plan.code,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (plan.description != null &&
                        plan.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(plan.description!),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        PmPlanStatusBadge(status: plan.status),
                        PmPriorityBadge(priority: plan.priority),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _row(l10n.pmFrequency,
                        pmFrequencyLabel(l10n, plan.frequency)),
                    _row(l10n.pmTrigger, pmTriggerLabel(l10n, plan.trigger)),
                    _row(
                      l10n.pmNextDueDate,
                      plan.nextDueDate != null
                          ? dateFormat.format(plan.nextDueDate!.toLocal())
                          : '—',
                    ),
                    _row(
                      l10n.pmEstimatedDuration,
                      l10n.pmMinutes(plan.estimatedDurationMinutes),
                    ),
                    _row(
                      l10n.pmAssignedTeam,
                      plan.assignedTeam?.name ?? '—',
                    ),
                    _row(
                      l10n.pmAssignedTechnician,
                      plan.assignedTechnician?.name ?? '—',
                    ),
                    _row(
                      l10n.pmLinkedAsset,
                      plan.asset == null
                          ? '—'
                          : [
                              if (plan.asset!.assetNumber != null)
                                plan.asset!.assetNumber!,
                              if (plan.asset!.name != null) plan.asset!.name!,
                            ].join(' · '),
                    ),
                    if (plan.meterThreshold != null)
                      _row(l10n.pmMeterThreshold,
                          plan.meterThreshold!.toString()),
                    if (plan.currentMeterReading != null)
                      _row(l10n.pmCurrentMeterReading,
                          plan.currentMeterReading!.toString()),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.pmChecklist,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (plan.checklistItems.isEmpty)
                      Text(l10n.pmChecklistEmpty)
                    else
                      ...plan.checklistItems.map(
                        (item) => Card(
                          child: ListTile(
                            title: Text(item.title),
                            subtitle: item.description == null ||
                                    item.description!.isEmpty
                                ? null
                                : Text(item.description!),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                if (item.requiresPassFail)
                                  Icon(Icons.rule,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                if (item.requiresNotes)
                                  Icon(Icons.notes,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary),
                                if (item.photoRequired)
                                  Icon(Icons.photo_camera_outlined,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (canUpdate)
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              final changed = await context.push<bool>(
                                RoutePaths.pmChecklistBuilder(widget.planId),
                              );
                              if (changed == true && mounted) {
                                _changed = true;
                                await _cubit.load();
                              }
                            },
                            icon: const Icon(Icons.checklist),
                            label: Text(l10n.pmChecklistBuilder),
                          ),
                        FilledButton.tonalIcon(
                          onPressed: () => context.push(
                            RoutePaths.pmSchedules,
                            extra: {'planId': widget.planId},
                          ),
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(l10n.pmSchedules),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => context.push(
                            RoutePaths.pmHistory,
                            extra: widget.planId,
                          ),
                          icon: const Icon(Icons.history),
                          label: Text(l10n.pmHistory),
                        ),
                        if (canCreate || canUpdate)
                          FilledButton.icon(
                            onPressed: _generateSchedules,
                            icon: const Icon(Icons.auto_awesome),
                            label: Text(l10n.pmGenerateSchedules),
                          ),
                      ],
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
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
