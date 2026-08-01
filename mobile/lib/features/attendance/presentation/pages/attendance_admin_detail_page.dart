import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_split_view.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_event.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_admin_detail_cubit.dart';
import 'package:mobile/features/attendance/presentation/utils/attendance_admin_labels.dart';
import 'package:mobile/features/attendance/presentation/widgets/attendance_status_badge.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_fullscreen_image.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_location_map.dart';

class AttendanceAdminDetailPage extends StatelessWidget {
  const AttendanceAdminDetailPage({super.key, required this.attendanceId});

  final String attendanceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AttendanceAdminDetailCubit>(param1: attendanceId)..load(),
      child: const _AttendanceAdminDetailView(),
    );
  }
}

class _AttendanceAdminDetailView extends StatelessWidget {
  const _AttendanceAdminDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDateTime(context);
    final timeFormat = AppFormatters.jm(context);
    final dash = l10n.valueNotSet;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.attendanceDetails)),
      body: BlocBuilder<AttendanceAdminDetailCubit, AttendanceAdminDetailState>(
        builder: (context, state) {
          if (state.status == AttendanceAdminDetailStatus.loading &&
              state.detail == null) {
            return AppLoader(message: l10n.attendanceDetailsLoading);
          }

          if (state.status == AttendanceAdminDetailStatus.failure ||
              state.detail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message != null
                          ? localizeAppMessage(l10n, state.message)
                          : l10n.attendanceDetailsLoadFailed,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<AttendanceAdminDetailCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final detail = state.detail!;
          final record = detail.attendance;
          final employee = record.employee;
          final clockIn = record.clockIn;
          final clockOut = record.clockOut;
          final selfieUrl = clockIn?.selfieUrl ?? clockOut?.selfieUrl;
          final deviceId = clockIn?.deviceId ?? clockOut?.deviceId;
          final source = clockIn?.source ?? clockOut?.source;
          final startGps = clockIn?.gps ?? clockOut?.gps;
          final endGps = clockOut?.gps;

          final isDesktop = AppBreakpoints.isDesktopOf(context);

          final leftSections = <Widget>[
            _SectionCard(
              title: l10n.attendanceEmployeeInfo,
              trailing: AttendanceStatusBadge(
                status: record.status,
                useManagementLabels: true,
              ),
              children: [
                if (employee?.avatarUrl != null &&
                    employee!.avatarUrl!.isNotEmpty) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ClipOval(
                      child: AppCachedNetworkImage(
                        imageUrl: employee.avatarUrl!,
                        width: 64,
                        height: 64,
                        memCacheWidth: 128,
                        memCacheHeight: 128,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _DetailRow(
                  label: l10n.labelName,
                  value: employee?.displayName ?? dash,
                ),
                _DetailRow(
                  label: l10n.email,
                  value: employee?.email ?? dash,
                ),
                _DetailRow(
                  label: l10n.roleLabel,
                  value: attendanceRoleLabel(
                    l10n,
                    employee?.primaryRole,
                  ),
                ),
                _DetailRow(
                  label: l10n.attendanceDate,
                  value: record.date,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionCard(
              title: l10n.attendanceSessionInfo,
              children: [
                _DetailRow(
                  label: l10n.attendanceClockIn,
                  value: clockIn == null
                      ? dash
                      : dateFormat.format(clockIn.at.toLocal()),
                ),
                _DetailRow(
                  label: l10n.attendanceClockOut,
                  value: clockOut == null
                      ? dash
                      : dateFormat.format(clockOut.at.toLocal()),
                ),
                _DetailRow(
                  label: l10n.attendanceWorkingHours,
                  value: DurationFormatter.fromMinutes(
                    record.workingMinutes,
                    l10n,
                  ),
                ),
                _DetailRow(
                  label: l10n.attendanceBreaks,
                  value:
                      '${record.breakCount} · ${DurationFormatter.fromMinutes(record.breakMinutes, l10n)}',
                ),
                _DetailRow(
                  label: l10n.attendanceOvertimeHours,
                  value: dash,
                ),
                _DetailRow(
                  label: l10n.attendanceLastUpdated,
                  value: record.updatedAt == null
                      ? dash
                      : dateFormat.format(record.updatedAt!.toLocal()),
                ),
              ],
            ),
          ];

          final rightSections = <Widget>[
            if (startGps != null) ...[
              OvertimeLocationSection(
                startGps: startGps,
                endGps: endGps,
                startAddress: startGps.fullAddress,
                endAddress: endGps?.fullAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _SectionCard(
              title: l10n.attendanceSelfie,
              children: [
                if (selfieUrl == null || selfieUrl.isEmpty)
                  Text(dash)
                else
                  _SelfiePhotoGrid(imageUrl: selfieUrl, label: l10n.attendanceSelfie),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionCard(
              title: l10n.attendanceDeviceInfo,
              children: [
                _DetailRow(
                  label: l10n.attendanceDevice,
                  value: (deviceId == null || deviceId.isEmpty)
                      ? dash
                      : deviceId,
                ),
                _DetailRow(
                  label: l10n.attendanceSyncSource,
                  value: (source == null || source.isEmpty) ? dash : source,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionCard(
              title: l10n.attendanceTimeline,
              children: [
                if (detail.events.isEmpty)
                  Text(l10n.attendanceTimelineEmpty)
                else
                  ...detail.events.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _eventIcon(event.type),
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _eventLabel(l10n, event.type),
                                  style:
                                      Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  timeFormat.format(event.at.toLocal()),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                if ((event.gps.fullAddress ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  Text(
                                    attendanceAddressSnippet(
                                      event.gps.fullAddress,
                                    ),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ];

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context
                      .read<AttendanceAdminDetailCubit>()
                      .load(silent: true),
                  child: AppBottomSafeListView(
                    basePadding: EdgeInsets.all(
                      isDesktop ? AppSpacing.xl : AppSpacing.lg,
                    ),
                    chrome: AppBottomChrome.system,
                    children: [
                      if (isDesktop)
                        AppDesktopSplitView(
                          start: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: leftSections,
                          ),
                          end: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: rightSections,
                          ),
                        )
                      else
                        ...leftSections,
                      if (!isDesktop) ...[
                        const SizedBox(height: AppSpacing.lg),
                        ...rightSections,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _eventIcon(AttendanceEventType type) {
    switch (type) {
      case AttendanceEventType.clockIn:
        return Icons.login;
      case AttendanceEventType.clockOut:
        return Icons.logout;
      case AttendanceEventType.breakStart:
        return Icons.pause_circle_outline;
      case AttendanceEventType.breakEnd:
        return Icons.play_circle_outline;
    }
  }

  String _eventLabel(AppLocalizations l10n, AttendanceEventType type) {
    switch (type) {
      case AttendanceEventType.clockIn:
        return l10n.attendanceEventClockedIn;
      case AttendanceEventType.clockOut:
        return l10n.attendanceEventClockedOut;
      case AttendanceEventType.breakStart:
        return l10n.attendanceEventBreakStarted;
      case AttendanceEventType.breakEnd:
        return l10n.attendanceEventBreakEnded;
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _SelfiePhotoGrid extends StatelessWidget {
  const _SelfiePhotoGrid({required this.imageUrl, required this.label});

  final String imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= AppBreakpoints.tabletMax ? 2 : 1;
    final tileWidth = crossAxisCount == 1
        ? double.infinity
        : (width - AppSpacing.lg * 2 - AppSpacing.md * 2) / 2;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        SizedBox(
          width: crossAxisCount == 1 ? double.infinity : tileWidth - AppSpacing.sm,
          child: _PhotoTile(label: label, imageUrl: imageUrl),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.label, required this.imageUrl});

  final String label;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openOvertimeFullscreenImage(
        context,
        imageUrl: imageUrl,
        title: label,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: AppCachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            memCacheWidth: 800,
          ),
        ),
      ),
    );
  }
}
