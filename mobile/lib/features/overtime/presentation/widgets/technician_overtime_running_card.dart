import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/attendance/presentation/widgets/working_timer.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_state.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_voice_note_section.dart';
import 'package:mobile/features/overtime/presentation/widgets/technician_overtime_stage_photos.dart';

/// Simplified running-session card for technicians — action-focused only.
class TechnicianOvertimeRunningCard extends StatelessWidget {
  const TechnicianOvertimeRunningCard({
    super.key,
    required this.session,
    required this.isBusy,
    required this.busyAction,
    required this.onAdvance,
    this.pendingActions = const [],
  });

  final OvertimeSession session;
  final bool isBusy;
  final OvertimeBusyAction? busyAction;
  final VoidCallback onAdvance;
  final List<PendingOvertimeAction> pendingActions;

  @override
  Widget build(BuildContext context) {
    final next = session.effectiveNextCheckpoint;
    return TechnicianOvertimeRunningContent(
      session: session,
      nextStage: next,
      isBusy: isBusy,
      busyAction: busyAction,
      onAdvance: onAdvance,
      pendingActions: pendingActions,
      elapsedSeconds: 0,
      voiceMaxDurationSeconds: context.select(
        (OvertimeCubit cubit) => cubit.state.voiceMaxDurationSeconds,
      ),
      voiceRecordingQuality: context.select(
        (OvertimeCubit cubit) => cubit.state.voiceRecordingQuality,
      ),
      voiceDraft: context.read<OvertimeCubit>().state.voiceDraft,
      onNotesChanged: context.read<OvertimeCubit>().updateNotesDraft,
      onVoiceDraftChanged: context.read<OvertimeCubit>().updateVoiceDraft,
      liveTimer: BlocSelector<OvertimeCubit, OvertimeState, int>(
        selector: (state) => state.elapsedSeconds,
        builder: (context, seconds) => WorkingTimer(seconds: seconds),
      ),
    );
  }
}

/// Pure presentation widget used by [TechnicianOvertimeRunningCard] and tests.
class TechnicianOvertimeRunningContent extends StatelessWidget {
  const TechnicianOvertimeRunningContent({
    super.key,
    required this.session,
    required this.nextStage,
    required this.isBusy,
    required this.busyAction,
    required this.onAdvance,
    required this.elapsedSeconds,
    required this.voiceMaxDurationSeconds,
    required this.voiceRecordingQuality,
    required this.onNotesChanged,
    required this.onVoiceDraftChanged,
    this.pendingActions = const [],
    this.voiceDraft,
    this.liveTimer,
  });

  final OvertimeSession session;
  final OvertimeCheckpointStage? nextStage;
  final bool isBusy;
  final OvertimeBusyAction? busyAction;
  final VoidCallback onAdvance;
  final int elapsedSeconds;
  final int voiceMaxDurationSeconds;
  final String voiceRecordingQuality;
  final OvertimeVoiceDraft? voiceDraft;
  final List<PendingOvertimeAction> pendingActions;
  final ValueChanged<String> onNotesChanged;
  final ValueChanged<OvertimeVoiceDraft?> onVoiceDraftChanged;

  /// When set, only this subtree rebuilds on the 1 Hz elapsed tick.
  final Widget? liveTimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final actionLabel = _nextActionLabel(l10n, nextStage);
    final isAdvancing =
        busyAction == OvertimeBusyAction.arrivedAtWorkSite ||
        busyAction == OvertimeBusyAction.finishedWork ||
        busyAction == OvertimeBusyAction.end;
    final currentStageTitle = _currentStageTitle(l10n, nextStage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overtimeTypeLabel(l10n, session.type),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MetaRow(
                  label: l10n.overtimeCurrentStage,
                  value: currentStageTitle,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: liveTimer ?? WorkingTimer(seconds: elapsedSeconds),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    l10n.overtimeRunningTimer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: ValueKey('overtime-active-notes-${nextStage?.apiValue ?? 'none'}'),
          enabled: !isBusy,
          maxLines: 2,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: l10n.overtimeNotes,
            hintText: l10n.overtimeNotesOptionalHint,
            border: const OutlineInputBorder(),
          ),
          onChanged: onNotesChanged,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
        const SizedBox(height: AppSpacing.md),
        OvertimeVoiceNoteSection(
          key: ValueKey('overtime-active-voice-${nextStage?.apiValue ?? 'none'}'),
          maxDurationSeconds: voiceMaxDurationSeconds,
          voiceRecordingQuality: voiceRecordingQuality,
          localBytes: voiceDraft?.bytes,
          durationSeconds: voiceDraft?.durationSeconds,
          enabled: !isBusy,
          onDraftChanged: onVoiceDraftChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        TechnicianOvertimeStagePhotos(
          session: session,
          pendingActions: pendingActions,
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: isBusy || nextStage == null ? null : onAdvance,
          icon: isAdvancing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : Icon(_nextActionIcon(nextStage)),
          label: Text(actionLabel),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            textStyle: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }

  static String _currentStageTitle(
    AppLocalizations l10n,
    OvertimeCheckpointStage? next,
  ) {
    if (next == null) {
      return l10n.overtimeStageEndJourney;
    }
    switch (next) {
      case OvertimeCheckpointStage.startJourney:
        return l10n.overtimeStageStartJourney;
      case OvertimeCheckpointStage.arrivedAtWorkSite:
        return l10n.overtimeStageArrivedAtWorkSite;
      case OvertimeCheckpointStage.finishedWork:
        return l10n.overtimeStageFinishedWork;
      case OvertimeCheckpointStage.endJourney:
        return l10n.overtimeStageEndJourney;
    }
  }

  static String _nextActionLabel(
    AppLocalizations l10n,
    OvertimeCheckpointStage? next,
  ) {
    switch (next) {
      case OvertimeCheckpointStage.arrivedAtWorkSite:
        return l10n.overtimeArrivedAtWorkSite;
      case OvertimeCheckpointStage.finishedWork:
        return l10n.overtimeFinishedWork;
      case OvertimeCheckpointStage.endJourney:
        return l10n.overtimeEnd;
      case OvertimeCheckpointStage.startJourney:
      case null:
        return l10n.overtimeEnd;
    }
  }

  static IconData _nextActionIcon(OvertimeCheckpointStage? next) {
    switch (next) {
      case OvertimeCheckpointStage.arrivedAtWorkSite:
        return Icons.location_on_outlined;
      case OvertimeCheckpointStage.finishedWork:
        return Icons.handyman_outlined;
      case OvertimeCheckpointStage.endJourney:
        return Icons.flag_outlined;
      case OvertimeCheckpointStage.startJourney:
      case null:
        return Icons.stop_circle_outlined;
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

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
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
