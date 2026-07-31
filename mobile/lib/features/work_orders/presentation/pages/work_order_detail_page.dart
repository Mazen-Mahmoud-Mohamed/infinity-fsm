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
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/organization/domain/entities/user_summary.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_detail_cubit.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_badges.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_execution_panel.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_section_card.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_text_prompt.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_timeline.dart';

class WorkOrderDetailPage extends StatelessWidget {
  const WorkOrderDetailPage({super.key, required this.workOrderId});

  final String workOrderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WorkOrderDetailCubit>(param1: workOrderId)..load(),
      child: const _WorkOrderDetailView(),
    );
  }
}

class _WorkOrderDetailView extends StatefulWidget {
  const _WorkOrderDetailView();

  @override
  State<_WorkOrderDetailView> createState() => _WorkOrderDetailViewState();
}

class _WorkOrderDetailViewState extends State<_WorkOrderDetailView> {
  String _completionNotesDraft = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.select((AuthCubit cubit) => cubit.state.user);
    final permissions = user?.permissionChecker;
    final currentUserId = user?.id;
    final dateFormat = AppFormatters.mediumDateTime(context);
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 900 ? 880.0 : double.infinity;
    final horizontalPad = width >= 700 ? AppSpacing.xl : AppSpacing.md;

    return BlocConsumer<WorkOrderDetailCubit, WorkOrderDetailState>(
      listenWhen: (previous, current) =>
          previous.deleted != current.deleted ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.deleted) {
          if (context.mounted) {
            context.pop(true);
          }
          return;
        }
        if (state.message != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizeAppMessage(l10n, state.message)),
            ),
          );
          context.read<WorkOrderDetailCubit>().clearMessage();
        }
      },
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.workOrder != current.workOrder ||
          previous.action != current.action ||
          previous.deleted != current.deleted,
      builder: (context, state) {
        final workOrder = state.workOrder;
        final showInitialLoader =
            (state.status == WorkOrderDetailStatus.loading ||
                    state.status == WorkOrderDetailStatus.initial) &&
                workOrder == null;
        final isAssignee = workOrder != null &&
            currentUserId != null &&
            workOrder.assignedTechnicianId == currentUserId;
        final canExecute = isAssignee;

        final bottomBar = workOrder == null
            ? null
            : _PrimaryActionBar(
                l10n: l10n,
                state: state,
                permissions: permissions,
                currentUserId: currentUserId,
                completionNotesDraft: _completionNotesDraft,
                onAssign: () => _assignTechnician(context, l10n),
              );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            if (context.mounted) {
              context.pop(state.mutated || state.deleted);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.workOrderDetails),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.mounted) {
                    context.pop(state.mutated || state.deleted);
                  }
                },
              ),
              actions: [
                if (permissions?.canUpdateWorkOrder() == true &&
                    workOrder != null &&
                    workOrder.status != WorkOrderStatus.completed &&
                    workOrder.status != WorkOrderStatus.cancelled)
                  IconButton(
                    tooltip: l10n.workOrderEdit,
                    onPressed: state.isBusy
                        ? null
                        : () async {
                            final updated = await context.push<bool>(
                              RoutePaths.workOrderFormEdit(workOrder.id),
                            );
                            if (updated == true && context.mounted) {
                              await context
                                  .read<WorkOrderDetailCubit>()
                                  .load(silent: true);
                            }
                          },
                    icon: const Icon(Icons.edit_outlined),
                  ),
                if (workOrder != null)
                  _OverflowMenu(
                    l10n: l10n,
                    state: state,
                    permissions: permissions,
                    onAssign: () => _assignTechnician(context, l10n),
                  ),
              ],
            ),
            body: showInitialLoader
                ? const AppLoader()
                : workOrder == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.message != null
                                    ? localizeAppMessage(l10n, state.message)
                                    : l10n.workOrderLoadFailed,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton(
                                onPressed: () =>
                                    context.read<WorkOrderDetailCubit>().load(),
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: ListView(
                            padding: AppScrollPadding.resolve(
                              context,
                              base: EdgeInsets.fromLTRB(
                                horizontalPad,
                                AppSpacing.md,
                                horizontalPad,
                                AppSpacing.xl,
                              ),
                              chrome: bottomBar != null
                                  ? AppBottomChrome.stickyActions
                                  : AppBottomChrome.system,
                            ),
                            children: [
                              _HeaderSection(
                                workOrder: workOrder,
                                dateFormat: dateFormat,
                                unassignedLabel: l10n.workOrderUnassigned,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              WorkOrderExecutionPanel(
                                workOrder: workOrder,
                                state: state,
                                canExecute: canExecute,
                                completionNotesDraft: _completionNotesDraft,
                                onCompletionNotesChanged: (value) {
                                  _completionNotesDraft = value;
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              WorkOrderSectionCard(
                                icon: Icons.timeline,
                                title: l10n.workOrderTimeline,
                                subtitle: l10n.workOrderTimelineSubtitle,
                                initiallyExpanded: true,
                                child: WorkOrderTimelineSection(
                                  events: workOrder.timeline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
            bottomNavigationBar: bottomBar,
          ),
        );
      },
    );
  }

  Future<void> _assignTechnician(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final result = await getIt<OrganizationRepository>().getUsers();
    if (!context.mounted) {
      return;
    }

    if (result is Failure<List<UserSummary>>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizeAppMessage(l10n, result.message))),
      );
      return;
    }

    final users = (result as Success<List<UserSummary>>).data;
    final technicians = users
        .where(
          (user) => user.roles.any((r) => r.toUpperCase().contains('TECH')),
        )
        .toList();
    final options = technicians.isEmpty ? users : technicians;

    final selected = await showModalBottomSheet<UserSummary>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.workOrderSelectTechnician,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              if (options.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(l10n.workOrderNoTechnicians),
                ),
              ...options.map(
                (user) => ListTile(
                  title: Text(user.fullName),
                  subtitle: Text(user.email),
                  onTap: () => Navigator.pop(sheetContext, user),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && context.mounted) {
      await context.read<WorkOrderDetailCubit>().assign(
            technicianId: selected.id,
          );
    }
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.workOrder,
    required this.dateFormat,
    required this.unassignedLabel,
  });

  final WorkOrder workOrder;
  final DateFormat dateFormat;
  final String unassignedLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    workOrder.jobTitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                WorkOrderStatusBadge(status: workOrder.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              workOrder.jobNumber,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                WorkOrderPriorityBadge(priority: workOrder.priority),
                if (workOrder.scheduledAt != null)
                  Chip(
                    avatar: const Icon(Icons.event_outlined, size: 16),
                    label: Text(
                      dateFormat.format(workOrder.scheduledAt!.toLocal()),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  avatar: const Icon(Icons.engineering_outlined, size: 16),
                  label: Text(
                    workOrder.assignedTechnicianName ?? unassignedLabel,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (workOrder.rejectionReason != null &&
                workOrder.rejectionReason!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.workOrderRejectionReason,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onErrorContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workOrder.rejectionReason!,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionBar extends StatelessWidget {
  const _PrimaryActionBar({
    required this.l10n,
    required this.state,
    required this.permissions,
    required this.currentUserId,
    required this.completionNotesDraft,
    required this.onAssign,
  });

  final AppLocalizations l10n;
  final WorkOrderDetailState state;
  final PermissionChecker? permissions;
  final String? currentUserId;
  final String completionNotesDraft;
  final VoidCallback onAssign;

  bool _isAssignee(WorkOrder workOrder) {
    if (currentUserId == null || workOrder.assignedTechnicianId == null) {
      return false;
    }
    return workOrder.assignedTechnicianId == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final workOrder = state.workOrder;
    if (workOrder == null) {
      return const SizedBox.shrink();
    }

    final busy = state.isBusy;
    final isAssignee = _isAssignee(workOrder);
    final scheme = Theme.of(context).colorScheme;

    Widget? primary;
    Widget? secondary;

    if (workOrder.status == WorkOrderStatus.assigned && isAssignee) {
      primary = FilledButton(
        onPressed: busy
            ? null
            : () => context.read<WorkOrderDetailCubit>().accept(),
        child: state.action == WorkOrderAction.accept
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.workOrderAccept),
      );
      secondary = OutlinedButton(
        onPressed: busy
            ? null
            : () async {
                final reason = await promptWorkOrderText(
                  context,
                  title: l10n.workOrderReject,
                  hint: l10n.workOrderReasonOptional,
                  confirmLabel: l10n.confirm,
                  cancelLabel: l10n.close,
                );
                if (reason == null || !context.mounted) {
                  return;
                }
                await context.read<WorkOrderDetailCubit>().reject(
                      reason: reason.isEmpty ? null : reason,
                    );
              },
        child: Text(l10n.workOrderReject),
      );
    } else if (workOrder.status == WorkOrderStatus.accepted && isAssignee) {
      primary = FilledButton.icon(
        onPressed: busy
            ? null
            : () => context.read<WorkOrderDetailCubit>().start(),
        icon: state.action == WorkOrderAction.start
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.workOrderStart),
      );
    } else if (workOrder.status == WorkOrderStatus.inProgress) {
      final canCompleteAsAssignee = isAssignee &&
          permissions?.canCompleteWorkOrder() == true;
      final canCompleteAsManager = !isAssignee &&
          permissions?.canCompleteWorkOrder() == true &&
          (permissions?.canViewAllWorkOrders() == true ||
              permissions?.canViewTeamWorkOrders() == true);
      if (canCompleteAsAssignee || canCompleteAsManager) {
        final ready = workOrder.afterPhotos.isNotEmpty;
        primary = FilledButton.icon(
          onPressed: busy || !ready
              ? null
              : () => completeWork(
                    context,
                    completionNotes: completionNotesDraft,
                  ),
          icon: state.action == WorkOrderAction.complete
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(l10n.workOrderComplete),
        );
      }
    }

    if (primary == null &&
        permissions?.canAssignWorkOrder() == true &&
        (workOrder.status == WorkOrderStatus.pending ||
            workOrder.status == WorkOrderStatus.assigned ||
            workOrder.status == WorkOrderStatus.rejected)) {
      primary = FilledButton.tonalIcon(
        onPressed: busy ? null : onAssign,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.workOrderAssign),
      );
    }

    if (primary == null && secondary == null) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 8,
      color: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Row(
              children: [
                if (secondary != null) ...[
                  Expanded(child: secondary),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (primary != null)
                  Expanded(
                    flex: secondary == null ? 1 : 1,
                    child: primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({
    required this.l10n,
    required this.state,
    required this.permissions,
    required this.onAssign,
  });

  final AppLocalizations l10n;
  final WorkOrderDetailState state;
  final PermissionChecker? permissions;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final workOrder = state.workOrder!;
    final busy = state.isBusy;
    final items = <PopupMenuEntry<String>>[];

    if (permissions?.canAssignWorkOrder() == true &&
        (workOrder.status == WorkOrderStatus.pending ||
            workOrder.status == WorkOrderStatus.assigned ||
            workOrder.status == WorkOrderStatus.rejected)) {
      items.add(
        PopupMenuItem(value: 'assign', child: Text(l10n.workOrderAssign)),
      );
    }
    if (permissions?.canCancelWorkOrder() == true &&
        workOrder.status != WorkOrderStatus.completed &&
        workOrder.status != WorkOrderStatus.cancelled) {
      items.add(
        PopupMenuItem(value: 'cancel', child: Text(l10n.workOrderCancel)),
      );
    }
    if (permissions?.canUpdateWorkOrder() == true) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: Text(
            l10n.workOrderDelete,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      enabled: !busy,
      onSelected: (value) async {
        switch (value) {
          case 'assign':
            onAssign();
          case 'cancel':
            final reason = await promptWorkOrderText(
              context,
              title: l10n.workOrderCancel,
              hint: l10n.workOrderReasonOptional,
              confirmLabel: l10n.confirm,
              cancelLabel: l10n.close,
            );
            if (reason == null || !context.mounted) {
              return;
            }
            await context.read<WorkOrderDetailCubit>().cancel(
                  reason: reason.isEmpty ? null : reason,
                );
          case 'delete':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.workOrderDelete),
                content: Text(l10n.workOrderDeleteConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(l10n.no),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(l10n.yes),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              await context.read<WorkOrderDetailCubit>().delete();
            }
        }
      },
      itemBuilder: (_) => items,
    );
  }
}
