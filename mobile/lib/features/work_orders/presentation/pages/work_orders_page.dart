import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_list_card.dart';
import 'package:mobile/core/widgets/technician_main_app_bar.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_responsive_card_list.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/notifications/presentation/widgets/notifications_bell_action.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_orders_list_cubit.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_labels.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_badges.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_orders_desktop_view.dart';

class WorkOrdersPage extends StatefulWidget {
  const WorkOrdersPage({super.key});

  @override
  State<WorkOrdersPage> createState() => _WorkOrdersPageState();
}

class _WorkOrdersPageState extends State<WorkOrdersPage> {
  late final bool _isAdminMode;
  late final WorkOrdersListCubit _cubit;

  @override
  void initState() {
    super.initState();
    final permissions =
        context.read<AuthCubit>().state.user?.permissionChecker;
    _isAdminMode = permissions?.canManageWorkOrders() == true ||
        permissions?.canViewAllWorkOrders() == true ||
        permissions?.canViewTeamWorkOrders() == true;
    _cubit = getIt<WorkOrdersListCubit>()
      ..loadFirstPage(isAdminMode: _isAdminMode);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: _WorkOrdersView(isAdminMode: _isAdminMode),
    );
  }
}

class _WorkOrdersView extends StatefulWidget {
  const _WorkOrdersView({required this.isAdminMode});

  final bool isAdminMode;

  @override
  State<_WorkOrdersView> createState() => _WorkOrdersViewState();
}

class _WorkOrdersViewState extends State<_WorkOrdersView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<WorkOrdersListCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktopOf(context)) {
      return WorkOrdersDesktopView(
        isAdminMode: widget.isAdminMode,
        scrollController: _scrollController,
        searchController: _searchController,
        onSearchChanged: () => setState(() {}),
        onOpenForm: () => _openForm(context),
      );
    }

    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDateTime(context);
    final width = MediaQuery.sizeOf(context).width;
    final canCreate = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canCreateWorkOrder() == true,
    );
    final pagePad = AppBreakpoints.pagePadding(width);

    return Scaffold(
      appBar: TechnicianMainAppBar(
        title: Text(l10n.workOrders),
        actions: const [
          NotificationsBellAction(),
        ],
      ),
      floatingActionButton: canCreate
          ? (width < 360
              ? FloatingActionButton(
                  onPressed: () => _openForm(context),
                  tooltip: l10n.workOrderCreate,
                  child: const Icon(Icons.add),
                )
              : FloatingActionButton.extended(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.workOrderCreate),
                ))
          : null,
      body: AppPageFrame(
        maxWidth: AppBreakpoints.contentWideMax,
        child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePad,
                  AppSpacing.md,
                  pagePad,
                  AppSpacing.sm,
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.workOrderSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<WorkOrdersListCubit>().search('');
                              setState(() {});
                            },
                          ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (value) =>
                      context.read<WorkOrdersListCubit>().search(value),
                ),
              ),
              BlocBuilder<WorkOrdersListCubit, WorkOrdersListState>(
                buildWhen: (previous, current) =>
                    previous.filterStatus != current.filterStatus,
                builder: (context, state) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: pagePad),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: l10n.workOrderFilterAll,
                          selected: state.filterStatus == null,
                          onSelected: () => context
                              .read<WorkOrdersListCubit>()
                              .setFilter(null),
                        ),
                        ...WorkOrderStatus.values.map(
                          (status) => Padding(
                            padding:
                                const EdgeInsets.only(left: AppSpacing.sm),
                            child: _FilterChip(
                              label: workOrderStatusLabel(l10n, status),
                              selected: state.filterStatus == status,
                              onSelected: () => context
                                  .read<WorkOrdersListCubit>()
                                  .setFilter(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: BlocConsumer<WorkOrdersListCubit, WorkOrdersListState>(
                  listenWhen: (previous, current) =>
                      previous.message != current.message &&
                      current.message != null &&
                      current.status == WorkOrdersListStatus.failure,
                  listener: (context, state) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localizeAppMessage(
                            AppLocalizations.of(context),
                            state.message,
                          ),
                        ),
                      ),
                    );
                  },
                  buildWhen: (previous, current) =>
                      previous.status != current.status ||
                      previous.items != current.items ||
                      previous.hasMore != current.hasMore ||
                      previous.isRefreshing != current.isRefreshing ||
                      previous.message != current.message,
                  builder: (context, state) {
                    if ((state.status == WorkOrdersListStatus.loading ||
                            state.status == WorkOrdersListStatus.initial) &&
                        state.items.isEmpty) {
                      return AppLoader(message: l10n.workOrderLoading);
                    }

                    if (state.status == WorkOrdersListStatus.failure &&
                        state.items.isEmpty) {
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
                                onPressed: () => context
                                    .read<WorkOrdersListCubit>()
                                    .refresh(),
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state.items.isEmpty) {
                      return Column(
                        children: [
                          AppRefreshBar(visible: state.isRefreshing),
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Text(
                                  l10n.workOrderEmpty,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        AppRefreshBar(visible: state.isRefreshing),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () =>
                                context.read<WorkOrdersListCubit>().refresh(),
                            child: AppResponsiveCardList(
                              controller: _scrollController,
                              chrome: AppBottomChrome.fab,
                              padding: EdgeInsets.fromLTRB(
                                pagePad,
                                AppSpacing.sm,
                                pagePad,
                                0,
                              ),
                              itemCount: state.items.length,
                              loadingMore: state.status ==
                                  WorkOrdersListStatus.loadingMore,
                              itemBuilder: (context, index) {
                                final item = state.items[index];
                                return _WorkOrderTile(
                                  workOrder: item,
                                  dateFormat: dateFormat,
                                  showTechnician: widget.isAdminMode,
                                  onTap: () async {
                                    final changed = await context.push<bool>(
                                      RoutePaths.workOrderDetail(item.id),
                                    );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    if (changed == true) {
                                      context
                                          .read<WorkOrdersListCubit>()
                                          .refresh();
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final created = await context.push<bool>(RoutePaths.workOrderForm);
    if (!context.mounted) {
      return;
    }
    if (created == true) {
      context.read<WorkOrdersListCubit>().refresh();
    }
  }
}

class _WorkOrderTile extends StatelessWidget {
  const _WorkOrderTile({
    required this.workOrder,
    required this.dateFormat,
    required this.showTechnician,
    required this.onTap,
  });

  final WorkOrder workOrder;
  final DateFormat dateFormat;
  final bool showTechnician;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppListCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  workOrder.jobTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              WorkOrderStatusBadge(status: workOrder.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            workOrder.jobNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (workOrder.customerName != null &&
              workOrder.customerName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              workOrder.customerName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              WorkOrderPriorityBadge(priority: workOrder.priority),
              if (workOrder.scheduledAt != null)
                Text(
                  dateFormat.format(workOrder.scheduledAt!.toLocal()),
                  style: theme.textTheme.bodySmall,
                ),
              if (showTechnician &&
                  workOrder.assigneesDisplay.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    workOrder.assigneesDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
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
    );
  }
}
