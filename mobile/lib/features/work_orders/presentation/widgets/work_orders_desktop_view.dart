import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_data_table.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_empty_state.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_table_cell.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_orders_list_cubit.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_labels.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_badges.dart';

/// Desktop-only work orders list — table layout with toolbar.
class WorkOrdersDesktopView extends StatelessWidget {
  const WorkOrdersDesktopView({
    super.key,
    required this.isAdminMode,
    required this.scrollController,
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenForm,
  });

  final bool isAdminMode;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final Future<void> Function() onOpenForm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDateTime(context);
    final canCreate = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canCreateWorkOrder() == true,
    );

    return BlocListener<WorkOrdersListCubit, WorkOrdersListState>(
      listenWhen: (previous, current) =>
          previous.message != current.message &&
          current.message != null &&
          current.status == WorkOrdersListStatus.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizeAppMessage(l10n, state.message),
            ),
          ),
        );
      },
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BlocBuilder<WorkOrdersListCubit, WorkOrdersListState>(
                      buildWhen: (previous, current) =>
                          previous.isRefreshing != current.isRefreshing,
                      builder: (context, state) {
                        return AppRefreshBar(visible: state.isRefreshing);
                      },
                    ),
                    Text(
                      l10n.workOrders,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BlocBuilder<WorkOrdersListCubit, WorkOrdersListState>(
                      buildWhen: (previous, current) =>
                          previous.filterStatus != current.filterStatus,
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 480),
                                child: TextField(
                                  controller: searchController,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: l10n.workOrderSearchHint,
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: searchController.text.isEmpty
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              searchController.clear();
                                              context
                                                  .read<WorkOrdersListCubit>()
                                                  .search('');
                                              onSearchChanged();
                                            },
                                          ),
                                    isDense: true,
                                  ),
                                  onChanged: (_) => onSearchChanged(),
                                  onSubmitted: (value) => context
                                      .read<WorkOrdersListCubit>()
                                      .search(value),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _StatusFilters(filterStatus: state.filterStatus),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: BlocBuilder<WorkOrdersListCubit,
                          WorkOrdersListState>(
                        buildWhen: (previous, current) =>
                            previous.status != current.status ||
                            previous.items != current.items ||
                            previous.hasMore != current.hasMore ||
                            previous.isRefreshing != current.isRefreshing,
                        builder: (context, state) {
                          return _WorkOrdersDesktopTableBody(
                            state: state,
                            isAdminMode: isAdminMode,
                            scrollController: scrollController,
                            dateFormat: dateFormat,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ),
                child: SizedBox(
                  height: 72,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (canCreate) ...[
                          SizedBox(
                            width: 160,
                            height: 48,
                            child: FilledButton.icon(
                              key: const Key('work-orders-create-order'),
                              onPressed: () => onOpenForm(),
                              icon: const Icon(Icons.add),
                              label: Text(
                                l10n.workOrderCreateOrder,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        SizedBox(
                          width: 125,
                          height: 48,
                          child: OutlinedButton.icon(
                            key: const Key('work-orders-refresh'),
                            onPressed: () =>
                                context.read<WorkOrdersListCubit>().refresh(),
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              l10n.refresh,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.filterStatus});

  final WorkOrderStatus? filterStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: l10n.workOrderFilterAll,
            selected: filterStatus == null,
            onSelected: () =>
                context.read<WorkOrdersListCubit>().setFilter(null),
          ),
          ...WorkOrderStatus.values.map(
            (status) => Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.sm,
              ),
              child: _FilterChip(
                label: workOrderStatusLabel(l10n, status),
                selected: filterStatus == status,
                onSelected: () =>
                    context.read<WorkOrdersListCubit>().setFilter(status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _WorkOrdersDesktopTableBody extends StatelessWidget {
  const _WorkOrdersDesktopTableBody({
    required this.state,
    required this.isAdminMode,
    required this.scrollController,
    required this.dateFormat,
  });

  final WorkOrdersListState state;
  final bool isAdminMode;
  final ScrollController scrollController;
  final DateFormat dateFormat;

  Future<void> _openDetail(BuildContext context, WorkOrder item) async {
    final changed = await context.push<bool>(
      RoutePaths.workOrderDetail(item.id),
    );
    if (!context.mounted) return;
    if (changed == true) {
      context.read<WorkOrdersListCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if ((state.status == WorkOrdersListStatus.loading ||
            state.status == WorkOrdersListStatus.initial) &&
        state.items.isEmpty) {
      return AppLoader(message: l10n.workOrderLoading);
    }

    if (state.status == WorkOrdersListStatus.failure && state.items.isEmpty) {
      return Center(
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
                    context.read<WorkOrdersListCubit>().refresh(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: AppDesktopEmptyState(
            icon: Icons.assignment_outlined,
            title: l10n.workOrderEmpty,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<WorkOrdersListCubit>().refresh(),
      child: LayoutBuilder(
          builder: (context, constraints) {
            return AppDesktopDataTable(
              controller: scrollController,
              loadingMore: state.status == WorkOrdersListStatus.loadingMore,
              expandVertically: true,
              columnMinWidth: isAdminMode ? 128 : 136,
              columns: [
                DataColumn(label: Text(l10n.reportsJobNumber)),
                DataColumn(label: Text(l10n.workOrderJobTitle)),
                DataColumn(label: Text(l10n.workOrderCustomer)),
                DataColumn(label: Text(l10n.workOrderLocation)),
                if (isAdminMode)
                  DataColumn(label: Text(l10n.workOrderTechnicians)),
                DataColumn(label: Text(l10n.workOrderPriority)),
                DataColumn(label: Text(l10n.reportsCenterStatusFilter)),
                DataColumn(label: Text(l10n.workOrderScheduledDate)),
              ],
              rows: [
                for (final item in state.items)
                  DataRow(
                    onSelectChanged: (_) => _openDetail(context, item),
                    cells: [
                      DataCell(AppDesktopTableCell(item.jobNumber)),
                      DataCell(
                        AppDesktopTableCell(
                          item.jobTitle,
                          maxLines: 2,
                        ),
                      ),
                      DataCell(
                        AppDesktopTableCell(item.customerName ?? '—'),
                      ),
                      DataCell(
                        AppDesktopTableCell(
                          item.locationDisplay.isEmpty
                              ? '—'
                              : item.locationDisplay,
                        ),
                      ),
                      if (isAdminMode)
                        DataCell(
                          AppDesktopTableCell(
                            item.assigneesDisplay.isEmpty
                                ? '—'
                                : item.assigneesDisplay,
                          ),
                        ),
                      DataCell(
                        WorkOrderPriorityBadge(priority: item.priority),
                      ),
                      DataCell(WorkOrderStatusBadge(status: item.status)),
                      DataCell(
                        AppDesktopTableCell(
                          item.scheduledAt == null
                              ? '—'
                              : dateFormat.format(
                                  item.scheduledAt!.toLocal(),
                                ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
    );
  }
}
