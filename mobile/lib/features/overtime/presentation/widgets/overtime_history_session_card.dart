import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_technician_presentation.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_status_badge.dart';

/// Technician overtime history list item.
class OvertimeHistorySessionCard extends StatelessWidget {
  const OvertimeHistorySessionCard({
    super.key,
    required this.session,
    required this.pendingSync,
    required this.dateFormat,
    required this.l10n,
  });

  final OvertimeSession session;
  final bool pendingSync;
  final DateFormat dateFormat;
  final AppLocalizations l10n;

  String? get _rejectionReason {
    if (session.status != OvertimeStatus.rejected) {
      return null;
    }
    final reason = session.rejectionReason?.trim();
    if (reason == null || reason.isEmpty) {
      return null;
    }
    return reason;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rejectionReason = _rejectionReason;

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
          Text(
            dateFormat.format(session.startAt.toLocal()),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            overtimeTechnicianTypeLabel(l10n, session.type),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          OvertimeStatusBadge(
            status: session.status,
            pendingSync: pendingSync,
          ),
          if (rejectionReason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.overtimeRejectionReason,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              rejectionReason,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
