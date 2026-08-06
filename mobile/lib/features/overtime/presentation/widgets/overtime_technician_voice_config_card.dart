import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/settings/presentation/widgets/overtime_settings_helpers.dart';

/// Read-only company voice settings for technicians.
class OvertimeTechnicianVoiceConfigCard extends StatelessWidget {
  const OvertimeTechnicianVoiceConfigCard({
    super.key,
    required this.durationMinutes,
    required this.quality,
    required this.uploadPolicy,
  });

  final int durationMinutes;
  final String quality;
  final String uploadPolicy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.overtimeVoiceSettingsInfoTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              label: l10n.settingsOvertimeVoiceMaxDurationTitle,
              value: l10n.settingsOvertimeVoiceDurationMinutes(durationMinutes),
            ),
            _InfoRow(
              label: l10n.settingsOvertimeVoiceQualityTitle,
              value: voiceQualityLabel(l10n, quality),
            ),
            _InfoRow(
              label: l10n.settingsOvertimeUploadPolicyTitle,
              value: uploadPolicyLabel(l10n, uploadPolicy),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
