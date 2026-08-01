import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_record.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_admin_cubit.dart';
import 'package:mobile/features/attendance/presentation/utils/attendance_admin_labels.dart';
import 'package:mobile/features/attendance/presentation/widgets/attendance_status_badge.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/utils/dashboard_period_range.dart';

class AttendanceAdminPage extends StatelessWidget {
  const AttendanceAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AttendanceAdminCubit>()..loadFirstPage(),
      child: const _AttendanceAdminView(),
    );
  }
}

class _AttendanceAdminView extends StatefulWidget {
  const _AttendanceAdminView();

  @override
  State<_AttendanceAdminView> createState() => _AttendanceAdminViewState();
}

class _AttendanceAdminViewState extends State<_AttendanceAdminView> {
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
      context.read<AttendanceAdminCubit>().loadMore();
    }
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final cubit = context.read<AttendanceAdminCubit>();
    final state = cubit.state;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: state.customFrom ?? DateTime(now.year, now.month, 1),
        end: state.customTo ?? now,
      ),
    );
    if (range == null) return;
    await cubit.setCustomRange(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timeFormat = AppFormatters.jm(context);
    final dateTimeFormat = AppFormatters.mediumDateTime(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.attendanceManagement)),
      body: Column(
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
                hintText: l10n.attendanceSearchEmployee,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<AttendanceAdminCubit>().search('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) =>
                  context.read<AttendanceAdminCubit>().search(value),
            ),
          ),
          BlocBuilder<AttendanceAdminCubit, AttendanceAdminState>(
            buildWhen: (previous, current) =>
                previous.period != current.period ||
                previous.customFrom != current.customFrom ||
                previous.customTo != current.customTo,
            builder: (context, state) {
              final range = DashboardPeriodRange.resolveLocal(
                period: state.period,
                customFrom: state.customFrom,
                customTo: state.customTo,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: l10n.dashboardPeriodToday,
                            selected: state.period == DashboardPeriod.today,
                            onSelected: () => context
                                .read<AttendanceAdminCubit>()
                                .setPeriod(DashboardPeriod.today),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FilterChip(
                            label: l10n.dashboardPeriodWeek,
                            selected: state.period == DashboardPeriod.week,
                            onSelected: () => context
                                .read<AttendanceAdminCubit>()
                                .setPeriod(DashboardPeriod.week),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FilterChip(
                            label: l10n.dashboardPeriodMonth,
                            selected: state.period == DashboardPeriod.month,
                            onSelected: () => context
                                .read<AttendanceAdminCubit>()
                                .setPeriod(DashboardPeriod.month),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FilterChip(
                            label: l10n.dashboardPeriodYear,
                            selected: state.period == DashboardPeriod.year,
                            onSelected: () => context
                                .read<AttendanceAdminCubit>()
                                .setPeriod(DashboardPeriod.year),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FilterChip(
                            label: l10n.dashboardPeriodCustom,
                            selected: state.period == DashboardPeriod.custom,
                            onSelected: () => _pickCustomRange(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DashboardPeriodRange.formatRange(
                        context: context,
                        period: state.period,
                        from: range.from,
                        to: range.to,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<AttendanceAdminCubit, AttendanceAdminState>(
            buildWhen: (previous, current) =>
                previous.filterStatus != current.filterStatus,
            builder: (context, state) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    _FilterChip(
                      label: l10n.workOrderFilterAll,
                      selected: state.filterStatus == null,
                      onSelected: () =>
                          context.read<AttendanceAdminCubit>().setFilter(null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: l10n.attendanceStatusPresent,
                      selected:
                          state.filterStatus == AttendanceStatus.clockedIn,
                      onSelected: () => context
                          .read<AttendanceAdminCubit>()
                          .setFilter(AttendanceStatus.clockedIn),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: l10n.attendanceStatusOnBreak,
                      selected: state.filterStatus == AttendanceStatus.onBreak,
                      onSelected: () => context
                          .read<AttendanceAdminCubit>()
                          .setFilter(AttendanceStatus.onBreak),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: l10n.attendanceStatusCheckedOut,
                      selected:
                          state.filterStatus == AttendanceStatus.clockedOut,
                      onSelected: () => context
                          .read<AttendanceAdminCubit>()
                          .setFilter(AttendanceStatus.clockedOut),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<AttendanceAdminCubit, AttendanceAdminState>(
            buildWhen: (previous, current) =>
                previous.filterRole != current.filterRole,
            builder: (context, state) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    _FilterChip(
                      label: l10n.attendanceRoleAll,
                      selected: state.filterRole == null,
                      onSelected: () =>
                          context.read<AttendanceAdminCubit>().setRole(null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: l10n.usersRoleTechnician,
                      selected: state.filterRole == 'TECHNICIAN',
                      onSelected: () => context
                          .read<AttendanceAdminCubit>()
                          .setRole('TECHNICIAN'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: l10n.usersRoleSupervisor,
                      selected: state.filterRole == 'SUPERVISOR',
                      onSelected: () => context
                          .read<AttendanceAdminCubit>()
                          .setRole('SUPERVISOR'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: l10n.usersRoleAdmin,
                      selected: state.filterRole == 'ADMIN',
                      onSelected: () =>
                          context.read<AttendanceAdminCubit>().setRole('ADMIN'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: BlocBuilder<AttendanceAdminCubit, AttendanceAdminState>(
              builder: (context, state) {
                if (state.status == AttendanceAdminStatus.loading &&
                    state.items.isEmpty) {
                  return AppLoader(message: l10n.attendanceLoading);
                }

                if (state.status == AttendanceAdminStatus.failure &&
                    state.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.message != null
                                ? localizeAppMessage(l10n, state.message)
                                : l10n.attendanceAdminLoadFailed,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton(
                            onPressed: () => context
                                .read<AttendanceAdminCubit>()
                                .loadFirstPage(),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state.items.isEmpty) {
                  return Center(child: Text(l10n.attendanceAdminEmpty));
                }

                return Column(
                  children: [
                    AppRefreshBar(visible: state.isRefreshing),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => context
                            .read<AttendanceAdminCubit>()
                            .loadFirstPage(),
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: AppScrollPadding.resolve(
                            context,
                            base: const EdgeInsets.all(AppSpacing.lg),
                            chrome: AppBottomChrome.system,
                          ),
                          itemCount: state.items.length +
                              (state.status ==
                                      AttendanceAdminStatus.loadingMore
                                  ? 1
                                  : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final record = state.items[index];
                            return _AdminAttendanceCard(
                              record: record,
                              timeFormat: timeFormat,
                              dateTimeFormat: dateTimeFormat,
                              l10n: l10n,
                              onTap: () => context.push(
                                RoutePaths.attendanceAdminDetail(record.id),
                              ),
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

class _AdminAttendanceCard extends StatelessWidget {
  const _AdminAttendanceCard({
    required this.record,
    required this.timeFormat,
    required this.dateTimeFormat,
    required this.l10n,
    required this.onTap,
  });

  final AttendanceRecord record;
  final DateFormat timeFormat;
  final DateFormat dateTimeFormat;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employee = record.employee;
    final avatarUrl = employee?.avatarUrl;
    final selfieUrl = record.clockIn?.selfieUrl ?? record.clockOut?.selfieUrl;
    final address = record.clockIn?.gps.fullAddress ??
        record.clockOut?.gps.fullAddress;
    final deviceId = record.clockIn?.deviceId ?? record.clockOut?.deviceId;
    final source = record.clockIn?.source ?? record.clockOut?.source;
    final dash = l10n.valueNotSet;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? AppCachedNetworkImage(
                              imageUrl: avatarUrl,
                              width: 44,
                              height: 44,
                              memCacheWidth: 88,
                              memCacheHeight: 88,
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.person_outline,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee?.displayName ?? l10n.workOrderTechnician,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            attendanceRoleLabel(
                              l10n,
                              employee?.primaryRole,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AttendanceStatusBadge(
                      status: record.status,
                      useManagementLabels: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoLine(
                  label: l10n.attendanceClockIn,
                  value: record.clockIn == null
                      ? dash
                      : timeFormat.format(record.clockIn!.at.toLocal()),
                ),
                _InfoLine(
                  label: l10n.attendanceClockOut,
                  value: record.clockOut == null
                      ? dash
                      : timeFormat.format(record.clockOut!.at.toLocal()),
                ),
                _InfoLine(
                  label: l10n.attendanceWorkingHours,
                  value: DurationFormatter.fromMinutes(
                    record.workingMinutes,
                    l10n,
                  ),
                ),
                _InfoLine(
                  label: l10n.attendanceOvertimeHours,
                  value: dash,
                ),
                _InfoLine(
                  label: l10n.attendanceLocation,
                  value: attendanceAddressSnippet(address, fallback: dash),
                ),
                _InfoLine(
                  label: l10n.attendanceDevice,
                  value: (deviceId == null || deviceId.isEmpty) ? dash : deviceId,
                ),
                _InfoLine(
                  label: l10n.attendanceSyncSource,
                  value: (source == null || source.isEmpty) ? dash : source,
                ),
                _InfoLine(
                  label: l10n.attendanceLastUpdated,
                  value: record.updatedAt == null
                      ? dash
                      : dateTimeFormat.format(record.updatedAt!.toLocal()),
                ),
                if (selfieUrl != null && selfieUrl.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppCachedNetworkImage(
                        imageUrl: selfieUrl,
                        width: 56,
                        height: 56,
                        memCacheWidth: 112,
                        memCacheHeight: 112,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
