import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_data_table.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_record.dart';
import 'package:mobile/features/attendance/presentation/utils/attendance_admin_labels.dart';
import 'package:mobile/features/attendance/presentation/widgets/attendance_status_badge.dart';

/// Desktop table for attendance admin records.
class AttendanceAdminDesktopTable extends StatelessWidget {
  const AttendanceAdminDesktopTable({
    super.key,
    required this.records,
    required this.timeFormat,
    required this.scrollController,
    this.loadingMore = false,
  });

  final List<AttendanceRecord> records;
  final DateFormat timeFormat;
  final ScrollController scrollController;
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dash = l10n.valueNotSet;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: AppDesktopDataTable(
        controller: scrollController,
        loadingMore: loadingMore,
        columns: [
          DataColumn(label: Text(l10n.labelName)),
          DataColumn(label: Text(l10n.roleLabel)),
          DataColumn(label: Text(l10n.reportsCenterStatusFilter)),
          DataColumn(label: Text(l10n.attendanceClockIn)),
          DataColumn(label: Text(l10n.attendanceClockOut)),
          DataColumn(label: Text(l10n.attendanceWorkingHours)),
        ],
        rows: [
          for (final record in records)
            DataRow(
              onSelectChanged: (_) => context.push(
                RoutePaths.attendanceAdminDetail(record.id),
              ),
              cells: [
                DataCell(
                  Text(
                    record.employee?.displayName ?? l10n.workOrderTechnician,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(
                  Text(
                    attendanceRoleLabel(
                      l10n,
                      record.employee?.primaryRole,
                    ),
                  ),
                ),
                DataCell(
                  AttendanceStatusBadge(
                    status: record.status,
                    useManagementLabels: true,
                  ),
                ),
                DataCell(
                  Text(
                    record.clockIn == null
                        ? dash
                        : timeFormat.format(record.clockIn!.at.toLocal()),
                  ),
                ),
                DataCell(
                  Text(
                    record.clockOut == null
                        ? dash
                        : timeFormat.format(record.clockOut!.at.toLocal()),
                  ),
                ),
                DataCell(
                  Text(
                    DurationFormatter.fromMinutes(
                      record.workingMinutes,
                      l10n,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
