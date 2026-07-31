import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';

class AttendanceStatusBadge extends StatelessWidget {
  const AttendanceStatusBadge({super.key, required this.status});

  final AttendanceStatus status;

  Color _color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = AppThemeColors.of(context);
    switch (status) {
      case AttendanceStatus.notStarted:
        return semantic.info;
      case AttendanceStatus.clockedIn:
        return semantic.success;
      case AttendanceStatus.onBreak:
        return semantic.warning;
      case AttendanceStatus.clockedOut:
        return colors.primary;
    }
  }

  IconData get _icon {
    switch (status) {
      case AttendanceStatus.notStarted:
        return Icons.schedule_outlined;
      case AttendanceStatus.clockedIn:
        return Icons.check_circle;
      case AttendanceStatus.onBreak:
        return Icons.pause_circle_filled;
      case AttendanceStatus.clockedOut:
        return Icons.logout;
    }
  }

  String _label(AppLocalizations l10n) {
    switch (status) {
      case AttendanceStatus.notStarted:
        return l10n.attendanceStatusNotStarted;
      case AttendanceStatus.clockedIn:
        return l10n.attendanceStatusWorking;
      case AttendanceStatus.onBreak:
        return l10n.attendanceStatusOnBreak;
      case AttendanceStatus.clockedOut:
        return l10n.attendanceStatusClockedOut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            _label(l10n),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
