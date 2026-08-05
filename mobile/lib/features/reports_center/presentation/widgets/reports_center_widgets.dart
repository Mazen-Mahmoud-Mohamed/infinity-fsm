import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/reports_center/domain/entities/report_list_row.dart';
import 'package:mobile/features/reports_center/domain/entities/reports_center_module.dart';
import 'package:mobile/features/reports_center/presentation/cubit/reports_center_cubit.dart';
import 'package:mobile/features/reports_center/presentation/utils/reports_center_labels.dart';

Future<void> showReportsCenterFilterSheet(
  BuildContext context, {
  ReportsCenterCubit? cubit,
}) {
  final resolved = cubit ?? context.read<ReportsCenterCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: resolved,
        child: const _ReportsFilterSheet(),
      );
    },
  );
}

class ReportsCenterFilterBar extends StatelessWidget {
  const ReportsCenterFilterBar({
    super.key,
    required this.searchController,
  });

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = AppBreakpoints.isPhone(width);

    return BlocBuilder<ReportsCenterCubit, ReportsCenterState>(
      buildWhen: (p, c) =>
          p.module != c.module ||
          p.statusKey != c.statusKey ||
          p.employeeId != c.employeeId ||
          p.rangeFrom != c.rangeFrom ||
          p.rangeTo != c.rangeTo ||
          p.sort != c.sort ||
          p.employees != c.employees ||
          p.search != c.search,
      builder: (context, state) {
        final cubit = context.read<ReportsCenterCubit>();
        final statusOptions = reportsStatusOptions(l10n, state.module);
        final showDate = state.module.supportsDateRange;
        final showEmployee = state.module.supportsEmployeeFilter &&
            state.employees.isNotEmpty;

        if (isPhone) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: l10n.reportsCenterSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: cubit.applySearch,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: () => showReportsCenterFilterSheet(context),
                    icon: const Icon(Icons.tune),
                    label: Text(l10n.reportsCenterFilters),
                  ),
                ),
              ],
            ),
          );
        }

        return Material(
          color: theme.colorScheme.surface,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: l10n.reportsCenterSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: cubit.applySearch,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String?>(
                        key: ValueKey(
                          'status-${state.module}-${state.statusKey}',
                        ),
                        initialValue: state.statusKey,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.reportsCenterStatusFilter,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.reportsCenterFilterAll),
                          ),
                          for (final option in statusOptions)
                            DropdownMenuItem<String?>(
                              value: option.key,
                              child: Text(option.label),
                            ),
                        ],
                        onChanged: cubit.setStatusKey,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<ReportsSort>(
                        key: ValueKey('sort-${state.sort}'),
                        initialValue: state.sort,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.reportsCenterSort,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final sort in ReportsSort.values)
                            DropdownMenuItem(
                              value: sort,
                              child: Text(reportsSortLabel(l10n, sort)),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) cubit.setSort(value);
                        },
                      ),
                    ),
                  ],
                ),
                if (showDate || showEmployee) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (showDate) ...[
                        for (final period in const [
                          DashboardPeriod.today,
                          DashboardPeriod.week,
                          DashboardPeriod.month,
                        ])
                          FilterChip(
                            label: Text(_periodLabel(l10n, period)),
                            selected: false,
                            onSelected: (_) => cubit.setPeriod(period),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _pickRange(context, cubit, state),
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            state.rangeFrom == null
                                ? l10n.reportsCenterDateRange
                                : _formatRange(
                                    context,
                                    state.rangeFrom!,
                                    state.rangeTo,
                                  ),
                          ),
                        ),
                        if (state.rangeFrom != null)
                          TextButton(
                            onPressed: () => cubit.setDateRange(null, null),
                            child: Text(l10n.reportsCenterClearDates),
                          ),
                      ],
                      if (showEmployee)
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String?>(
                            key: ValueKey('employee-${state.employeeId}'),
                            initialValue: state.employeeId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.reportsCenterEmployee,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(l10n.reportsCenterFilterAll),
                              ),
                              for (final employee in state.employees)
                                DropdownMenuItem<String?>(
                                  value: employee.id,
                                  child: Text(employee.label),
                                ),
                            ],
                            onChanged: cubit.setEmployee,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportsFilterSheet extends StatelessWidget {
  const _ReportsFilterSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: BlocBuilder<ReportsCenterCubit, ReportsCenterState>(
          builder: (context, state) {
            final cubit = context.read<ReportsCenterCubit>();
            final statusOptions = reportsStatusOptions(l10n, state.module);
            final showDate = state.module.supportsDateRange;
            final showEmployee = state.module.supportsEmployeeFilter &&
                state.employees.isNotEmpty;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.reportsCenterFilters,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.reportsCenterStatusFilter),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      FilterChip(
                        label: Text(l10n.reportsCenterFilterAll),
                        selected: state.statusKey == null,
                        onSelected: (_) => cubit.setStatusKey(null),
                      ),
                      for (final option in statusOptions)
                        FilterChip(
                          label: Text(option.label),
                          selected: state.statusKey == option.key,
                          onSelected: (_) => cubit.setStatusKey(option.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.reportsCenterSort),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<ReportsSort>(
                    key: ValueKey('sheet-sort-${state.sort}'),
                    initialValue: state.sort,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final sort in ReportsSort.values)
                        DropdownMenuItem(
                          value: sort,
                          child: Text(reportsSortLabel(l10n, sort)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) cubit.setSort(value);
                    },
                  ),
                  if (showDate) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.reportsCenterDateRange),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        for (final period in const [
                          DashboardPeriod.today,
                          DashboardPeriod.week,
                          DashboardPeriod.month,
                        ])
                          FilterChip(
                            label: Text(_periodLabel(l10n, period)),
                            selected: false,
                            onSelected: (_) => cubit.setPeriod(period),
                          ),
                        ActionChip(
                          label: Text(l10n.reportsCenterCustomRange),
                          onPressed: () => _pickRange(context, cubit, state),
                        ),
                        if (state.rangeFrom != null)
                          ActionChip(
                            label: Text(l10n.reportsCenterClearDates),
                            onPressed: () => cubit.setDateRange(null, null),
                          ),
                      ],
                    ),
                  ],
                  if (showEmployee) ...[
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String?>(
                      key: ValueKey('sheet-employee-${state.employeeId}'),
                      initialValue: state.employeeId,
                      decoration: InputDecoration(
                        labelText: l10n.reportsCenterEmployee,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(l10n.reportsCenterFilterAll),
                        ),
                        for (final employee in state.employees)
                          DropdownMenuItem<String?>(
                            value: employee.id,
                            child: Text(employee.label),
                          ),
                      ],
                      onChanged: cubit.setEmployee,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.reportsCenterApplyFilters),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ReportsCenterResults extends StatelessWidget {
  const ReportsCenterResults({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = AppBreakpoints.isPhone(width);
    final dateFormat = AppFormatters.mediumDate(context);

    return BlocBuilder<ReportsCenterCubit, ReportsCenterState>(
      builder: (context, state) {
        final rows = state.sortedRows;
        if (state.status == ReportsCenterStatus.loading && rows.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == ReportsCenterStatus.failure && rows.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.reportsCenterLoadFailed,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (rows.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    reportsModuleEmptyLabel(l10n, state.module),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        if (isPhone) {
          return ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            itemCount: rows.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index >= rows.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final row = rows[index];
              return Card(
                child: ListTile(
                  title: Text(
                    row.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      if (row.subtitle != null && row.subtitle!.isNotEmpty)
                        row.subtitle!,
                      if (row.statusLabel != null) _statusLabel(l10n, row),
                      if (row.date != null)
                        dateFormat.format(row.date!.toLocal()),
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(row.route),
                ),
              );
            },
          );
        }

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: width - (AppSpacing.md * 2),
              ),
              child: DataTable(
                showCheckboxColumn: false,
                columns: [
                  DataColumn(label: Text(l10n.reportsCenterColTitle)),
                  DataColumn(label: Text(l10n.reportsCenterColSubtitle)),
                  DataColumn(label: Text(l10n.reportsCenterStatusFilter)),
                  DataColumn(label: Text(l10n.reportsCenterColDate)),
                  DataColumn(label: Text(l10n.reportsCenterColMeta)),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(
                      onSelectChanged: (_) => context.push(row.route),
                      cells: [
                        DataCell(Text(row.title)),
                        DataCell(Text(row.subtitle ?? '—')),
                        DataCell(Text(_statusLabel(l10n, row))),
                        DataCell(
                          Text(
                            row.date == null
                                ? '—'
                                : dateFormat.format(row.date!.toLocal()),
                          ),
                        ),
                        DataCell(Text(row.meta ?? '—')),
                      ],
                    ),
                  if (state.status == ReportsCenterStatus.loadingMore)
                    const DataRow(
                      cells: [
                        DataCell(CircularProgressIndicator()),
                        DataCell(SizedBox.shrink()),
                        DataCell(SizedBox.shrink()),
                        DataCell(SizedBox.shrink()),
                        DataCell(SizedBox.shrink()),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _statusLabel(AppLocalizations l10n, ReportListRow row) {
  if (row.statusLabel == null) return '—';
  final options = reportsStatusOptions(l10n, row.module);
  for (final option in options) {
    if (option.key == row.statusLabel) return option.label;
  }
  return row.statusLabel!;
}

String _periodLabel(AppLocalizations l10n, DashboardPeriod period) {
  switch (period) {
    case DashboardPeriod.today:
      return l10n.dashboardPeriodToday;
    case DashboardPeriod.week:
      return l10n.dashboardPeriodWeek;
    case DashboardPeriod.month:
      return l10n.dashboardPeriodMonth;
    case DashboardPeriod.year:
      return l10n.dashboardPeriodYear;
    case DashboardPeriod.custom:
      return l10n.reportsCenterCustomRange;
  }
}

String _formatRange(BuildContext context, DateTime from, DateTime? to) {
  final fmt = AppFormatters.mediumDate(context);
  final end = to ?? from;
  return '${fmt.format(from.toLocal())} – ${fmt.format(end.toLocal())}';
}

Future<void> _pickRange(
  BuildContext context,
  ReportsCenterCubit cubit,
  ReportsCenterState state,
) async {
  final now = DateTime.now();
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 1),
    initialDateRange: state.rangeFrom != null
        ? DateTimeRange(
            start: state.rangeFrom!,
            end: state.rangeTo ?? state.rangeFrom!,
          )
        : null,
  );
  if (picked == null) return;
  await cubit.setDateRange(picked.start, picked.end);
}
