import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_data_table.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_table_cell.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_formatters.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_status_badge.dart';

/// Desktop table for overtime admin sessions.
class OvertimeAdminDesktopTable extends StatelessWidget {
  const OvertimeAdminDesktopTable({
    super.key,
    required this.sessions,
    required this.dateFormat,
    required this.scrollController,
    this.loadingMore = false,
  });

  final List<OvertimeSession> sessions;
  final DateFormat dateFormat;
  final ScrollController scrollController;
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return AppDesktopDataTable(
          controller: scrollController,
          loadingMore: loadingMore,
          expandVertically: true,
          columnMinWidth: 128,
          columns: [
            DataColumn(
              label: Text(
                l10n.workOrderTechnician,
                key: const Key('overtime-desktop-col-technician'),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.labelType,
                key: const Key('overtime-desktop-col-type'),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.reportsCenterStatusFilter,
                key: const Key('overtime-desktop-col-status'),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.overtimePerDiem,
                key: const Key('overtime-desktop-col-per-diem'),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.labelStart,
                key: const Key('overtime-desktop-col-start'),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.labelEnd,
                key: const Key('overtime-desktop-col-end'),
              ),
            ),
            DataColumn(
              label: Text(
                l10n.overtimeEligible,
                key: const Key('overtime-desktop-col-overtime-hours'),
              ),
            ),
          ],
          rows: [
            for (final session in sessions)
              DataRow(
                onSelectChanged: (_) => context.push(
                  RoutePaths.overtimeAdminDetail(session.id),
                ),
                cells: [
                  DataCell(
                    AppDesktopTableCell(
                      session.technician?.displayName ??
                          l10n.workOrderTechnician,
                    ),
                  ),
                  DataCell(
                    AppDesktopTableCell(
                      overtimeTypeLabel(l10n, session.type),
                    ),
                  ),
                  DataCell(OvertimeStatusBadge(status: session.status)),
                  DataCell(
                    _OvertimePerDiemBadge(isOvernight: session.isOvernight),
                  ),
                  DataCell(
                    AppDesktopTableCell(
                      dateFormat.format(session.startAt.toLocal()),
                    ),
                  ),
                  DataCell(
                    AppDesktopTableCell(
                      session.endAt == null
                          ? '—'
                          : dateFormat.format(session.endAt!.toLocal()),
                    ),
                  ),
                  DataCell(
                    AppDesktopTableCell(
                      OvertimeFormatters.durationFromMinutes(
                        session.eligibleOvertimeMinutes,
                        l10n,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _OvertimePerDiemBadge extends StatelessWidget {
  const _OvertimePerDiemBadge({required this.isOvernight});

  final bool isOvernight;

  Color _color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = AppThemeColors.of(context);
    return isOvernight ? semantic.success : colors.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _color(context);
    final label = isOvernight ? l10n.yes : l10n.no;

    return Container(
      key: Key('overtime-per-diem-$label'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
