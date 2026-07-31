import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';

class ClockActionButtons extends StatelessWidget {
  const ClockActionButtons({
    super.key,
    required this.status,
    required this.isBusy,
    required this.onClockIn,
    required this.onClockOut,
    required this.onStartBreak,
    required this.onEndBreak,
  });

  final AttendanceStatus status;
  final bool isBusy;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;
  final VoidCallback onStartBreak;
  final VoidCallback onEndBreak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case AttendanceStatus.notStarted:
        return _PrimaryActionButton(
          label: l10n.attendanceClockIn,
          icon: Icons.login,
          isBusy: isBusy,
          onPressed: onClockIn,
        );
      case AttendanceStatus.clockedIn:
        return Row(
          children: [
            Expanded(
              child: _SecondaryActionButton(
                label: l10n.attendanceStartBreak,
                icon: Icons.pause_circle_outline,
                isBusy: isBusy,
                onPressed: onStartBreak,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _PrimaryActionButton(
                label: l10n.attendanceClockOut,
                icon: Icons.logout,
                isBusy: isBusy,
                onPressed: onClockOut,
              ),
            ),
          ],
        );
      case AttendanceStatus.onBreak:
        return _PrimaryActionButton(
          label: l10n.attendanceEndBreak,
          icon: Icons.play_circle_outline,
          isBusy: isBusy,
          onPressed: onEndBreak,
        );
      case AttendanceStatus.clockedOut:
        return const _CompletedNotice();
    }
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isBusy ? null : onPressed,
      icon: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isBusy ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

class _CompletedNotice extends StatelessWidget {
  const _CompletedNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Text(
          l10n.attendanceShiftCompleted,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
    );
  }
}
