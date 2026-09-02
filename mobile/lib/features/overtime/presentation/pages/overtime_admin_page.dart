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
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_responsive_card_list.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_admin_cubit.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_excel_export_flow.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_formatters.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_empty_state.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_admin_desktop_table.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_status_badge.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_export_filters.dart';

class OvertimeAdminPage extends StatelessWidget {
  const OvertimeAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OvertimeAdminCubit>()..loadFirstPage(),
      child: const _OvertimeAdminView(),
    );
  }
}

class _OvertimeAdminView extends StatefulWidget {
  const _OvertimeAdminView();

  @override
  State<_OvertimeAdminView> createState() => _OvertimeAdminViewState();
}

class _OvertimeAdminViewState extends State<_OvertimeAdminView> {
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<OvertimeAdminCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDateTime(context);
    final isDesktop = AppBreakpoints.isDesktopOf(context);
    final canExport = canExportOvertimeExcel(
      context.watch<AuthCubit>().state.user,
    );

    if (isDesktop) {
      return Scaffold(
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
                    BlocBuilder<OvertimeAdminCubit, OvertimeAdminState>(
                      buildWhen: (previous, current) =>
                          previous.isRefreshing != current.isRefreshing,
                      builder: (context, state) {
                        return AppRefreshBar(visible: state.isRefreshing);
                      },
                    ),
                    Text(
                      l10n.overtimeManagement,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BlocBuilder<OvertimeAdminCubit, OvertimeAdminState>(
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
                                  controller: _searchController,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: l10n.overtimeSearchTechnician,
                                    prefixIcon: const Icon(Icons.search),
                                    isDense: true,
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _searchController.clear();
                                              context
                                                  .read<OvertimeAdminCubit>()
                                                  .search('');
                                              setState(() {});
                                            },
                                          ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (value) => context
                                      .read<OvertimeAdminCubit>()
                                      .search(value),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _FilterChip(
                                    label: l10n.workOrderFilterAll,
                                    selected: state.filterStatus == null,
                                    onSelected: () => context
                                        .read<OvertimeAdminCubit>()
                                        .setFilter(null),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _FilterChip(
                                    label: l10n.filterPending,
                                    selected: state.filterStatus ==
                                        OvertimeStatus.pendingReview,
                                    onSelected: () => context
                                        .read<OvertimeAdminCubit>()
                                        .setFilter(
                                            OvertimeStatus.pendingReview),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _FilterChip(
                                    label: l10n.filterApproved,
                                    selected: state.filterStatus ==
                                        OvertimeStatus.approved,
                                    onSelected: () => context
                                        .read<OvertimeAdminCubit>()
                                        .setFilter(OvertimeStatus.approved),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _FilterChip(
                                    label: l10n.filterRejected,
                                    selected: state.filterStatus ==
                                        OvertimeStatus.rejected,
                                    onSelected: () => context
                                        .read<OvertimeAdminCubit>()
                                        .setFilter(OvertimeStatus.rejected),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: BlocBuilder<OvertimeAdminCubit, OvertimeAdminState>(
                        buildWhen: (previous, current) =>
                            previous.status != current.status ||
                            previous.items != current.items ||
                            previous.isRefreshing != current.isRefreshing,
                        builder: (context, state) {
                          return _buildOvertimeListBody(
                            context,
                            state: state,
                            l10n: l10n,
                            dateFormat: dateFormat,
                            isDesktop: true,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (canExport)
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
                          SizedBox(
                            width: 160,
                            height: 48,
                            child: FilledButton.icon(
                              key: const Key('overtime-export-excel'),
                              onPressed: () {
                                final state =
                                    context.read<OvertimeAdminCubit>().state;
                                showOvertimeExcelExportFlow(
                                  context,
                                  initialFilters: OvertimeExportFilters(
                                    status: state.filterStatus,
                                    search: state.search.isEmpty
                                        ? null
                                        : state.search,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.file_download_outlined),
                              label: Text(
                                l10n.overtimeExportExcel,
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.overtimeManagement),
        actions: [
          if (canExport)
            IconButton(
              tooltip: l10n.overtimeExportExcel,
              onPressed: () {
                final state = context.read<OvertimeAdminCubit>().state;
                showOvertimeExcelExportFlow(
                  context,
                  initialFilters: OvertimeExportFilters(
                    status: state.filterStatus,
                    search: state.search.isEmpty ? null : state.search,
                  ),
                );
              },
              icon: const Icon(Icons.file_download_outlined),
            ),
        ],
      ),
      floatingActionButton: canExport
          ? FloatingActionButton.extended(
              onPressed: () {
                final state = context.read<OvertimeAdminCubit>().state;
                showOvertimeExcelExportFlow(
                  context,
                  initialFilters: OvertimeExportFilters(
                    status: state.filterStatus,
                    search: state.search.isEmpty ? null : state.search,
                  ),
                );
              },
              icon: const Icon(Icons.table_view_outlined),
              label: Text(l10n.overtimeExportExcel),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.overtimeSearchTechnician,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<OvertimeAdminCubit>().search('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) =>
                  context.read<OvertimeAdminCubit>().search(value),
            ),
          ),
          BlocBuilder<OvertimeAdminCubit, OvertimeAdminState>(
            buildWhen: (previous, current) =>
                previous.filterStatus != current.filterStatus,
            builder: (context, state) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    _FilterChip(
                      label: l10n.workOrderFilterAll,
                      selected: state.filterStatus == null,
                      onSelected: () =>
                          context.read<OvertimeAdminCubit>().setFilter(null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: l10n.filterPending,
                      selected:
                          state.filterStatus == OvertimeStatus.pendingReview,
                      onSelected: () => context
                          .read<OvertimeAdminCubit>()
                          .setFilter(OvertimeStatus.pendingReview),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: l10n.filterApproved,
                      selected: state.filterStatus == OvertimeStatus.approved,
                      onSelected: () => context
                          .read<OvertimeAdminCubit>()
                          .setFilter(OvertimeStatus.approved),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: l10n.filterRejected,
                      selected: state.filterStatus == OvertimeStatus.rejected,
                      onSelected: () => context
                          .read<OvertimeAdminCubit>()
                          .setFilter(OvertimeStatus.rejected),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: BlocBuilder<OvertimeAdminCubit, OvertimeAdminState>(
              builder: (context, state) => _buildOvertimeListBody(
                context,
                state: state,
                l10n: l10n,
                dateFormat: dateFormat,
                isDesktop: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeListBody(
    BuildContext context, {
    required OvertimeAdminState state,
    required AppLocalizations l10n,
    required DateFormat dateFormat,
    required bool isDesktop,
  }) {
    if (state.status == OvertimeAdminStatus.loading && state.items.isEmpty) {
      return AppLoader(message: l10n.overtimeLoading);
    }

    if (state.status == OvertimeAdminStatus.failure && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.message != null
                    ? localizeAppMessage(l10n, state.message)
                    : l10n.overtimeLoadFailed,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () =>
                    context.read<OvertimeAdminCubit>().loadFirstPage(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return isDesktop
          ? AppDesktopEmptyState(
              icon: Icons.more_time_outlined,
              title: l10n.overtimeAdminEmpty,
            )
          : Center(child: Text(l10n.overtimeAdminEmpty));
    }

    return Column(
      children: [
        if (!isDesktop) AppRefreshBar(visible: state.isRefreshing),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                context.read<OvertimeAdminCubit>().loadFirstPage(),
            child: isDesktop
                ? OvertimeAdminDesktopTable(
                    sessions: state.items,
                    dateFormat: dateFormat,
                    scrollController: _scrollController,
                    loadingMore:
                        state.status == OvertimeAdminStatus.loadingMore,
                  )
                : AppResponsiveCardList(
                    controller: _scrollController,
                    chrome: AppBottomChrome.system,
                    itemCount: state.items.length,
                    loadingMore:
                        state.status == OvertimeAdminStatus.loadingMore,
                    itemBuilder: (context, index) {
                      final session = state.items[index];
                      return _AdminSessionCard(
                        session: session,
                        dateFormat: dateFormat,
                        l10n: l10n,
                        onTap: () => context.push(
                          RoutePaths.overtimeAdminDetail(session.id),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
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

class _AdminSessionCard extends StatelessWidget {
  const _AdminSessionCard({
    required this.session,
    required this.dateFormat,
    required this.l10n,
    required this.onTap,
  });

  final OvertimeSession session;
  final DateFormat dateFormat;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final technician = session.technician;
    final theme = Theme.of(context);

    return AppListCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  technician?.displayName ?? l10n.workOrderTechnician,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OvertimeStatusBadge(status: session.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            technician?.email ?? '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaChip(
                icon: Icons.category_outlined,
                label: overtimeTypeLabel(l10n, session.type),
              ),
              if (session.type == OvertimeType.travel && session.isOvernight)
                _MetaChip(
                  icon: Icons.nightlight_round,
                  label: l10n.overtimeOvernightShort,
                ),
              _MetaChip(
                icon: Icons.timer_outlined,
                label:
                    '${l10n.overtimeEligible}: '
                    '${OvertimeFormatters.durationFromMinutes(session.eligibleOvertimeMinutes, l10n)}',
              ),
              if (session.status == OvertimeStatus.approved)
                _MetaChip(
                  icon: Icons.verified_outlined,
                  label:
                      '${l10n.overtimeApprovedHours}: '
                      '${OvertimeFormatters.hoursValue(session.effectiveApprovedHours, l10n)}',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoLine(
            label: l10n.labelStart,
            value: dateFormat.format(session.startAt.toLocal()),
          ),
          _InfoLine(
            label: l10n.labelEnd,
            value: session.endAt == null
                ? '-'
                : dateFormat.format(session.endAt!.toLocal()),
          ),
          _InfoLine(
            label: l10n.labelCreated,
            value: session.createdAt == null
                ? '-'
                : dateFormat.format(session.createdAt!.toLocal()),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
