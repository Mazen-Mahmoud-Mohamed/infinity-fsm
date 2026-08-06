import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_maps_launcher.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_fullscreen_image.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_voice_note_section.dart';

enum _SyncBadge { synced, pending, failed, offline }

/// Presentation-only link between Journey Timeline stages and Journey Overview.
///
/// Desktop Overtime Details uses this so timeline taps focus the map and
/// marker taps highlight the matching timeline card. No business logic.
class OvertimeJourneyFocus extends ChangeNotifier {
  OvertimeCheckpointStage? _stage;
  int _generation = 0;
  bool _fromMap = false;

  OvertimeCheckpointStage? get stage => _stage;
  int get generation => _generation;

  /// True when the latest selection came from a map marker tap.
  bool get fromMap => _fromMap;

  void selectFromTimeline(OvertimeCheckpointStage stage) {
    _stage = stage;
    _fromMap = false;
    _generation++;
    notifyListeners();
  }

  void selectFromMap(OvertimeCheckpointStage stage) {
    _stage = stage;
    _fromMap = true;
    _generation++;
    notifyListeners();
  }

  void clear() {
    if (_stage == null) {
      return;
    }
    _stage = null;
    _fromMap = false;
    _generation++;
    notifyListeners();
  }
}

/// Vertical journey timeline — v2 four stages, or legacy start/end.
class OvertimeJourneyTimeline extends StatelessWidget {
  const OvertimeJourneyTimeline({
    super.key,
    required this.session,
    this.maxDurationSeconds = OvertimeMediaConfig.defaultMaxDurationSeconds,
    this.voiceRecordingQuality = OvertimeMediaConfig.defaultVoiceQuality,
    this.compact = false,
    this.pendingActions = const [],
    this.isOffline = false,
    this.includeJourneyOverview = true,
    this.focus,
    this.desktopCompactPhotos = false,
    this.onPendingVoiceChanged,
    this.isSyncing = false,
    this.showOpenLiveLocation = true,
  });

  final OvertimeSession session;
  final int maxDurationSeconds;
  final String voiceRecordingQuality;
  final bool compact;

  /// Queued offline actions for this device — used to render per-stage
  /// sync badges (pending / failed / offline).
  final List<PendingOvertimeAction> pendingActions;
  final bool isOffline;

  /// When false, the Journey Overview map is omitted so a parent layout can
  /// place it full-width (desktop Overtime Details).
  final bool includeJourneyOverview;

  /// Optional desktop focus controller for timeline ↔ map interaction.
  final OvertimeJourneyFocus? focus;

  /// Desktop Overtime Details: shorter checkpoint photos (lightbox unchanged).
  final bool desktopCompactPhotos;

  /// When set, technician may edit voice on stages still waiting for sync.
  final void Function(
    OvertimeCheckpointStage stage,
    OvertimeVoiceDraft? draft,
  )? onPendingVoiceChanged;

  /// True while the offline overtime queue is actively uploading.
  final bool isSyncing;

  /// Supervisors/admins review locations; technicians do not need this action.
  final bool showOpenLiveLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stages = session.isV2Workflow
        ? OvertimeCheckpointStage.ordered
        : const [
            OvertimeCheckpointStage.startJourney,
            OvertimeCheckpointStage.endJourney,
          ];

    final legacy = !session.isV2Workflow;
    final focusListenable = focus;

    Widget buildTimeline() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (session.requiresManualReview) ...[
            _ManualReviewChip(reason: session.reviewReason),
            const SizedBox(height: AppSpacing.md),
          ],
          for (var i = 0; i < stages.length; i++) ...[
            _TimelineStageTile(
              stage: stages[i],
              maxDurationSeconds: maxDurationSeconds,
              voiceRecordingQuality: voiceRecordingQuality,
              checkpoint: _checkpointFor(session, stages[i]),
              isNext: session.isRunning &&
                  session.effectiveNextCheckpoint == stages[i],
              compact: compact,
              title: _stageTitle(l10n, stages[i], legacy: legacy),
              syncBadge: _syncBadgeFor(stages[i]),
              highlighted: focusListenable?.stage == stages[i],
              desktopCompactPhotos: desktopCompactPhotos,
              pendingAction: _pendingFor(stages[i]),
              isSyncing: isSyncing,
              showOpenLiveLocation: showOpenLiveLocation,
              onPendingVoiceChanged: onPendingVoiceChanged == null
                  ? null
                  : (draft) => onPendingVoiceChanged!(stages[i], draft),
              onSelect: focusListenable == null
                  ? null
                  : () {
                      final checkpoint = _checkpointFor(session, stages[i]);
                      if (checkpoint == null) {
                        return;
                      }
                      focusListenable.selectFromTimeline(stages[i]);
                    },
            ),
            if (i < stages.length - 1)
              Padding(
                // Align connector to the center of the 28px indicator.
                padding: const EdgeInsetsDirectional.only(start: 13),
                child: SizedBox(
                  height: AppSpacing.md,
                  child: VerticalDivider(
                    width: 2,
                    thickness: 2,
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
          if (includeJourneyOverview)
            OvertimeJourneyOverview(
              session: session,
              mapHeight: OvertimeJourneyOverview.compactMapHeight,
              focus: focusListenable,
            ),
        ],
      );
    }

    if (focusListenable == null) {
      return buildTimeline();
    }

    return ListenableBuilder(
      listenable: focusListenable,
      builder: (context, _) => buildTimeline(),
    );
  }

  _SyncBadge? _syncBadgeFor(OvertimeCheckpointStage stage) {
    final checkpoint = _checkpointFor(session, stage);
    if (checkpoint == null) {
      return null;
    }
    PendingOvertimeAction? pending;
    for (final action in pendingActions) {
      if (action.checkpointStage == stage) {
        pending = action;
        break;
      }
    }
    if (pending == null) {
      return _SyncBadge.synced;
    }
    if (isOffline) {
      return _SyncBadge.offline;
    }
    if (pending.lastError != null && pending.lastError!.isNotEmpty) {
      return _SyncBadge.failed;
    }
    return _SyncBadge.pending;
  }

  PendingOvertimeAction? _pendingFor(OvertimeCheckpointStage stage) {
    for (final action in pendingActions) {
      if (action.checkpointStage == stage) {
        return action;
      }
    }
    return null;
  }

  static OvertimeCheckpoint? _checkpointFor(
    OvertimeSession session,
    OvertimeCheckpointStage stage,
  ) {
    if (session.isV2Workflow) {
      return session.checkpoints?.forStage(stage);
    }
    // Legacy: map start/end fields into checkpoint shape for display.
    if (stage == OvertimeCheckpointStage.startJourney) {
      return OvertimeCheckpoint(
        at: session.startAt,
        gps: session.startGps,
        photoUrl: session.startPhotoUrl,
        address: session.startAddress,
        deviceId: session.startDeviceId,
      );
    }
    if (stage == OvertimeCheckpointStage.endJourney && session.endAt != null) {
      return OvertimeCheckpoint(
        at: session.endAt!,
        gps: session.endGps ?? session.startGps,
        photoUrl: session.endPhotoUrl,
        address: session.endAddress,
        deviceId: session.endDeviceId,
      );
    }
    return null;
  }

  static String _stageTitle(
    AppLocalizations l10n,
    OvertimeCheckpointStage stage, {
    required bool legacy,
  }) {
    if (legacy) {
      switch (stage) {
        case OvertimeCheckpointStage.startJourney:
          return l10n.labelStart;
        case OvertimeCheckpointStage.endJourney:
          return l10n.labelEnd;
        default:
          break;
      }
    }
    switch (stage) {
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
}

/// Journey Overview map — markers, polyline, popups, and legend.
///
/// Used inline after the timeline on mobile/tablet, or full-width below the
/// desktop split on Overtime Details.
class OvertimeJourneyOverview extends StatelessWidget {
  const OvertimeJourneyOverview({
    super.key,
    required this.session,
    this.mapHeight = compactMapHeight,
    this.topSpacing = AppSpacing.lg,
    this.focus,
  });

  /// Default height when nested under the timeline (phone / tablet stack).
  static const double compactMapHeight = 280;

  /// Desktop full-width map height.
  static const double desktopMapHeight = 560;

  /// Tighter top gap when overview sits under the desktop split.
  static const double desktopTopSpacing = AppSpacing.sm;

  final OvertimeSession session;
  final double mapHeight;
  final double topSpacing;
  final OvertimeJourneyFocus? focus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stages = session.isV2Workflow
        ? OvertimeCheckpointStage.ordered
        : const [
            OvertimeCheckpointStage.startJourney,
            OvertimeCheckpointStage.endJourney,
          ];
    final legacy = !session.isV2Workflow;
    final points = _JourneyOverviewCard.pointsFor(
      session: session,
      stages: stages,
      l10n: l10n,
      legacy: legacy,
    );
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: _JourneyOverviewCard(
        points: points,
        legendStages: stages,
        legacy: legacy,
        mapHeight: mapHeight,
        focus: focus,
      ),
    );
  }
}

class _ManualReviewChip extends StatelessWidget {
  const _ManualReviewChip({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.onErrorContainer, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              reason?.isNotEmpty == true
                  ? reason!
                  : l10n.overtimeRequiresManualReview,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncBadgeChip extends StatelessWidget {
  const _SyncBadgeChip({required this.badge});

  final _SyncBadge badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color, icon) = switch (badge) {
      _SyncBadge.synced => (
          l10n.overtimeSyncSynced,
          colorScheme.primary,
          Icons.cloud_done_outlined,
        ),
      _SyncBadge.pending => (
          l10n.overtimeSyncPending,
          colorScheme.tertiary,
          Icons.cloud_upload_outlined,
        ),
      _SyncBadge.failed => (
          l10n.overtimeSyncFailed,
          colorScheme.error,
          Icons.error_outline,
        ),
      _SyncBadge.offline => (
          l10n.overtimeSyncOffline,
          colorScheme.outline,
          Icons.cloud_off_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _TimelineStageTile extends StatelessWidget {
  const _TimelineStageTile({
    required this.stage,
    required this.maxDurationSeconds,
    required this.voiceRecordingQuality,
    required this.checkpoint,
    required this.isNext,
    required this.compact,
    required this.title,
    this.syncBadge,
    this.highlighted = false,
    this.desktopCompactPhotos = false,
    this.pendingAction,
    this.isSyncing = false,
    this.showOpenLiveLocation = true,
    this.onPendingVoiceChanged,
    this.onSelect,
  });

  static const double _indicatorSize = 28;
  static const double _desktopPhotoHeight = 200;

  final OvertimeCheckpointStage stage;
  final int maxDurationSeconds;
  final String voiceRecordingQuality;
  final OvertimeCheckpoint? checkpoint;
  final bool isNext;
  final bool compact;
  final String title;
  final _SyncBadge? syncBadge;
  final bool highlighted;
  final bool desktopCompactPhotos;
  final PendingOvertimeAction? pendingAction;
  final bool isSyncing;
  final bool showOpenLiveLocation;
  final ValueChanged<OvertimeVoiceDraft?>? onPendingVoiceChanged;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final completed = checkpoint != null;
    final colorScheme = theme.colorScheme;
    final statusColor = completed
        ? colorScheme.primary
        : (isNext ? colorScheme.tertiary : colorScheme.outlineVariant);
    final statusLabel = completed
        ? l10n.overtimeCheckpointCompleted
        : (isNext
            ? l10n.overtimeCheckpointNext
            : l10n.overtimeCheckpointPending);

    final photo = (!compact &&
            checkpoint != null &&
            checkpoint!.photoUrl != null &&
            checkpoint!.photoUrl!.isNotEmpty)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: desktopCompactPhotos
                ? SizedBox(
                    height: _desktopPhotoHeight,
                    width: double.infinity,
                    child: InkWell(
                      onTap: () => openOvertimeFullscreenImage(
                        context,
                        imageUrl: checkpoint!.photoUrl!,
                        title: title,
                      ),
                      child: AppCachedNetworkImage(
                        imageUrl: checkpoint!.photoUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 800,
                      ),
                    ),
                  )
                : AspectRatio(
                    aspectRatio: 16 / 9,
                    child: InkWell(
                      onTap: () => openOvertimeFullscreenImage(
                        context,
                        imageUrl: checkpoint!.photoUrl!,
                        title: title,
                      ),
                      child: AppCachedNetworkImage(
                        imageUrl: checkpoint!.photoUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 800,
                      ),
                    ),
                  ),
          )
        : null;

    // Do NOT use IntrinsicHeight + Expanded here — that breaks inside ListView
    // (unbounded height) and blanks the entire detail scroll body.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _indicatorSize,
          height: _indicatorSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor.withValues(alpha: 0.15),
            border: Border.all(color: statusColor, width: 1.5),
          ),
          child: Icon(
            completed
                ? Icons.check
                : (isNext
                    ? Icons.radio_button_checked
                    : Icons.circle_outlined),
            color: statusColor,
            size: 14,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            elevation: highlighted ? 1 : null,
            color: highlighted
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: highlighted
                    ? colorScheme.primary.withValues(alpha: 0.55)
                    : colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: highlighted ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: onSelect,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(title, style: theme.textTheme.titleSmall),
                            if (syncBadge != null)
                              _SyncBadgeChip(badge: syncBadge!),
                            Text(
                              statusLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        if (checkpoint != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            AppFormatters.mediumDateTime(context)
                                .format(checkpoint!.at.toLocal()),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            checkpoint!.address?.isNotEmpty == true
                                ? checkpoint!.address!
                                : _coords(checkpoint!.gps),
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (checkpoint!.address?.isNotEmpty == true) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _coords(checkpoint!.gps),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          _CheckpointMetaChip(
                            label: l10n.overtimeGpsAccuracy,
                            value:
                                '${checkpoint!.gps.accuracy.toStringAsFixed(0)} m',
                          ),
                          if (checkpoint!.deviceId != null &&
                              checkpoint!.deviceId!.isNotEmpty)
                            _CheckpointMetaChip(
                              label: l10n.overtimeDeviceId,
                              value: checkpoint!.deviceId!,
                            ),
                          if (checkpoint!.batteryLevel != null)
                            _CheckpointMetaChip(
                              label: l10n.overtimeBatteryLevel,
                              value: '${checkpoint!.batteryLevel}%',
                            ),
                          if (checkpoint!.networkStatus != null &&
                              checkpoint!.networkStatus!.isNotEmpty)
                            _CheckpointMetaChip(
                              label: l10n.overtimeNetworkStatus,
                              value: checkpoint!.networkStatus!,
                            ),
                          if (checkpoint!.notes != null &&
                              checkpoint!.notes!.isNotEmpty)
                            _CheckpointMetaChip(
                              label: l10n.overtimeNotes,
                              value: checkpoint!.notes!,
                            ),
                          if (_shouldShowVoiceSection(
                            checkpoint: checkpoint!,
                            pendingAction: pendingAction,
                            canEdit: onPendingVoiceChanged != null &&
                                pendingAction != null,
                          )) ...[
                            const SizedBox(height: AppSpacing.md),
                            OvertimeVoiceNoteSection(
                              key: ValueKey(
                                'overtime-timeline-voice-${stage.apiValue}',
                              ),
                              maxDurationSeconds: maxDurationSeconds,
                              voiceRecordingQuality: voiceRecordingQuality,
                              remoteUrl: _remoteVoiceUrl(checkpoint!.voiceNote),
                              localBytes: pendingAction?.voiceBytes.isNotEmpty ==
                                      true
                                  ? pendingAction!.voiceBytes
                                  : null,
                              durationSeconds:
                                  checkpoint!.voiceNote?.duration ??
                                      pendingAction?.voiceDurationSeconds,
                              readOnly: !(onPendingVoiceChanged != null &&
                                  pendingAction != null &&
                                  _remoteVoiceUrl(checkpoint!.voiceNote) ==
                                      null),
                              compact: true,
                              syncBadge: _voiceSyncBadge(
                                checkpoint: checkpoint!,
                                pendingAction: pendingAction,
                                isSyncing: isSyncing,
                              ),
                              onDraftChanged: onPendingVoiceChanged,
                            ),
                          ],
                          if (photo != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            photo,
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                if (checkpoint != null && showOpenLiveLocation)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: _OpenLiveLocationButton(
                      gps: checkpoint!.gps,
                      label: title,
                      address: checkpoint!.address,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _coords(GpsSnapshot gps) {
    return '${gps.latitude.toStringAsFixed(5)}, ${gps.longitude.toStringAsFixed(5)}';
  }

  static String? _remoteVoiceUrl(OvertimeVoiceNote? note) {
    final url = note?.url;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return null;
  }

  static OvertimeVoiceSyncBadge _voiceSyncBadge({
    required OvertimeCheckpoint checkpoint,
    required PendingOvertimeAction? pendingAction,
    required bool isSyncing,
  }) {
    if (_remoteVoiceUrl(checkpoint.voiceNote) != null) {
      return OvertimeVoiceSyncBadge.uploaded;
    }
    final hasPendingVoice = pendingAction != null &&
        (pendingAction.voiceBytes.isNotEmpty ||
            checkpoint.voiceNote?.url == 'local-pending');
    if (!hasPendingVoice && checkpoint.voiceNote == null) {
      return OvertimeVoiceSyncBadge.none;
    }
    if (hasPendingVoice || checkpoint.voiceNote?.url == 'local-pending') {
      return isSyncing
          ? OvertimeVoiceSyncBadge.uploading
          : OvertimeVoiceSyncBadge.pendingSync;
    }
    return OvertimeVoiceSyncBadge.none;
  }

  static bool _shouldShowVoiceSection({
    required OvertimeCheckpoint checkpoint,
    required PendingOvertimeAction? pendingAction,
    required bool canEdit,
  }) {
    if (canEdit) return true;
    if (_remoteVoiceUrl(checkpoint.voiceNote) != null) return true;
    if (pendingAction != null && pendingAction.voiceBytes.isNotEmpty) {
      return true;
    }
    if (checkpoint.voiceNote != null &&
        checkpoint.voiceNote!.url == 'local-pending') {
      return true;
    }
    return false;
  }
}

class _CheckpointMetaChip extends StatelessWidget {
  const _CheckpointMetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: value,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact ✔ ● ○ progress strip for the current journey.
class OvertimeJourneyProgressStrip extends StatelessWidget {
  const OvertimeJourneyProgressStrip({super.key, required this.session});

  final OvertimeSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stages = session.isV2Workflow
        ? OvertimeCheckpointStage.ordered
        : const [
            OvertimeCheckpointStage.startJourney,
            OvertimeCheckpointStage.endJourney,
          ];
    final next = session.isRunning ? session.effectiveNextCheckpoint : null;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final stage in stages)
          _ProgressGlyph(
            label: OvertimeJourneyTimeline._stageTitle(
              l10n,
              stage,
              legacy: !session.isV2Workflow,
            ),
            completed: session.isV2Workflow
                ? session.checkpoints?.forStage(stage) != null
                : (stage == OvertimeCheckpointStage.startJourney ||
                    (stage == OvertimeCheckpointStage.endJourney &&
                        session.endAt != null)),
            isCurrent: next == stage,
            colorScheme: theme.colorScheme,
            textTheme: theme.textTheme,
          ),
      ],
    );
  }
}

/// Completed-checkpoint count helper used by the journey header (e.g. "2/4").
int overtimeCompletedCheckpointCount(OvertimeSession session) {
  if (!session.isV2Workflow) {
    var count = 1; // startJourney always recorded.
    if (session.endAt != null) count += 1;
    return count;
  }
  final checkpoints = session.checkpoints;
  if (checkpoints == null) {
    return 0;
  }
  return OvertimeCheckpointStage.ordered
      .where((stage) => checkpoints.forStage(stage) != null)
      .length;
}

int overtimeTotalCheckpointCount(OvertimeSession session) {
  return session.isV2Workflow ? OvertimeCheckpointStage.ordered.length : 2;
}

class _ProgressGlyph extends StatelessWidget {
  const _ProgressGlyph({
    required this.label,
    required this.completed,
    required this.isCurrent,
    required this.colorScheme,
    required this.textTheme,
  });

  final String label;
  final bool completed;
  final bool isCurrent;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final glyph = completed
        ? '✔'
        : (isCurrent ? '●' : '○');
    final color = completed
        ? colorScheme.primary
        : (isCurrent ? colorScheme.tertiary : colorScheme.outline);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$glyph $label',
        style: textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

/// Open Live Location only — embedded per-stage maps were removed in favor of
/// a single Journey Overview map after the timeline.
class _OpenLiveLocationButton extends StatelessWidget {
  const _OpenLiveLocationButton({
    required this.gps,
    required this.label,
    this.address,
  });

  final GpsSnapshot gps;
  final String label;
  final String? address;

  bool get _hasValidCoordinates {
    final lat = gps.latitude;
    final lng = gps.longitude;
    return lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  Future<void> _openLiveLocation(BuildContext context) async {
    if (!_hasValidCoordinates) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.overtimeLocationUnavailable),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final opened = await OvertimeMapsLauncher.openCoordinates(
      latitude: gps.latitude,
      longitude: gps.longitude,
      label: (address?.trim().isNotEmpty == true) ? address!.trim() : label,
    );
    if (!context.mounted) {
      return;
    }
    if (!opened) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.overtimeUnableOpenGoogleMaps),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canOpen = _hasValidCoordinates;
    final liveLabel = l10n.overtimeOpenLiveLocation;

    return SizedBox(
      width: double.infinity,
      child: Tooltip(
        message: canOpen ? liveLabel : l10n.overtimeLocationUnavailable,
        child: FilledButton.tonalIcon(
          onPressed: canOpen ? () => _openLiveLocation(context) : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
          ),
          icon: const Icon(Icons.location_on_outlined, size: 20),
          label: Text(
            liveLabel,
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
      ),
    );
  }
}

class _JourneyMapPoint {
  const _JourneyMapPoint({
    required this.stage,
    required this.title,
    required this.checkpoint,
    required this.color,
  });

  final OvertimeCheckpointStage stage;
  final String title;
  final OvertimeCheckpoint checkpoint;
  final Color color;

  LatLng get latLng =>
      LatLng(checkpoint.gps.latitude, checkpoint.gps.longitude);

  bool get hasValidCoordinates {
    final lat = checkpoint.gps.latitude;
    final lng = checkpoint.gps.longitude;
    return lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }
}

/// Single journey map shown after the last timeline stage.
class _JourneyOverviewCard extends StatefulWidget {
  const _JourneyOverviewCard({
    required this.points,
    required this.legendStages,
    required this.legacy,
    this.mapHeight = OvertimeJourneyOverview.compactMapHeight,
    this.focus,
  });

  final List<_JourneyMapPoint> points;
  final List<OvertimeCheckpointStage> legendStages;
  final bool legacy;
  final double mapHeight;
  final OvertimeJourneyFocus? focus;

  static const Color startColor = Color(0xFF16A34A);
  static const Color arrivedColor = Color(0xFF2563EB);
  static const Color finishedColor = Color(0xFF9333EA);
  static const Color endColor = Color(0xFFDC2626);
  static const Color routeColor = Color(0xFF64748B);

  static Color colorFor(OvertimeCheckpointStage stage) {
    switch (stage) {
      case OvertimeCheckpointStage.startJourney:
        return startColor;
      case OvertimeCheckpointStage.arrivedAtWorkSite:
        return arrivedColor;
      case OvertimeCheckpointStage.finishedWork:
        return finishedColor;
      case OvertimeCheckpointStage.endJourney:
        return endColor;
    }
  }

  static List<_JourneyMapPoint> pointsFor({
    required OvertimeSession session,
    required List<OvertimeCheckpointStage> stages,
    required AppLocalizations l10n,
    required bool legacy,
  }) {
    final points = <_JourneyMapPoint>[];
    for (final stage in stages) {
      final checkpoint =
          OvertimeJourneyTimeline._checkpointFor(session, stage);
      if (checkpoint == null) {
        continue;
      }
      final point = _JourneyMapPoint(
        stage: stage,
        title: OvertimeJourneyTimeline._stageTitle(
          l10n,
          stage,
          legacy: legacy,
        ),
        checkpoint: checkpoint,
        color: colorFor(stage),
      );
      if (point.hasValidCoordinates) {
        points.add(point);
      }
    }
    return points;
  }

  @override
  State<_JourneyOverviewCard> createState() => _JourneyOverviewCardState();
}

class _JourneyOverviewCardState extends State<_JourneyOverviewCard>
    with SingleTickerProviderStateMixin {
  static const String _tileUserAgent = 'com.infinitytech.fsm.mobile';
  static const double _markerSize = 30;
  static const double _markerSelectedSize = 34;

  final MapController _mapController = MapController();
  int? _selectedIndex;
  bool _didFitCamera = false;
  int _lastFocusGeneration = -1;
  AnimationController? _cameraAnim;

  @override
  void initState() {
    super.initState();
    widget.focus?.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focus?.removeListener(_onFocusChanged);
    _cameraAnim?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _JourneyOverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focus != widget.focus) {
      oldWidget.focus?.removeListener(_onFocusChanged);
      widget.focus?.addListener(_onFocusChanged);
      _lastFocusGeneration = -1;
    }
    if (!_samePoints(oldWidget.points, widget.points) ||
        oldWidget.mapHeight != widget.mapHeight) {
      _didFitCamera = false;
      _selectedIndex = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitCamera();
        }
      });
    }
  }

  void _onFocusChanged() {
    final focus = widget.focus;
    if (focus == null || !mounted) {
      return;
    }
    if (focus.generation == _lastFocusGeneration) {
      return;
    }
    _lastFocusGeneration = focus.generation;
    final stage = focus.stage;
    if (stage == null) {
      if (_selectedIndex != null) {
        setState(() => _selectedIndex = null);
      }
      return;
    }
    final index = widget.points.indexWhere((p) => p.stage == stage);
    if (index < 0) {
      return;
    }
    setState(() => _selectedIndex = index);
    if (!focus.fromMap) {
      _animateToPoint(widget.points[index].latLng);
    }
  }

  bool _samePoints(List<_JourneyMapPoint> a, List<_JourneyMapPoint> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].stage != b[i].stage ||
          a[i].checkpoint.gps.latitude != b[i].checkpoint.gps.latitude ||
          a[i].checkpoint.gps.longitude != b[i].checkpoint.gps.longitude) {
        return false;
      }
    }
    return true;
  }

  void _fitCamera() {
    if (_didFitCamera || widget.points.isEmpty) {
      return;
    }
    _didFitCamera = true;
    final points = widget.points.map((p) => p.latLng).toList(growable: false);
    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    final isTallMap = widget.mapHeight >= 500;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.fromLTRB(
          isTallMap ? 72 : 48,
          isTallMap ? 80 : 56,
          isTallMap ? 72 : 48,
          isTallMap ? 72 : 48,
        ),
        maxZoom: 15.5,
        minZoom: 11,
      ),
    );
  }

  void _animateToPoint(LatLng target, {double zoom = 16}) {
    LatLng startCenter;
    double startZoom;
    try {
      startCenter = _mapController.camera.center;
      startZoom = _mapController.camera.zoom;
    } catch (_) {
      _mapController.move(target, zoom);
      return;
    }

    _cameraAnim?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _cameraAnim = controller;
    controller.addListener(() {
      if (!mounted) {
        return;
      }
      final t = Curves.easeInOutCubic.transform(controller.value);
      final lat =
          startCenter.latitude + (target.latitude - startCenter.latitude) * t;
      final lng =
          startCenter.longitude + (target.longitude - startCenter.longitude) * t;
      final z = startZoom + (zoom - startZoom) * t;
      _mapController.move(LatLng(lat, lng), z);
    });
    controller.forward();
  }

  void _selectMarker(int index) {
    final point = widget.points[index];
    final already = _selectedIndex == index;
    setState(() => _selectedIndex = already ? null : index);
    final focus = widget.focus;
    if (focus == null) {
      return;
    }
    if (already) {
      focus.clear();
    } else {
      focus.selectFromMap(point.stage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final points = widget.points;
    final center = points.length == 1
        ? points.first.latLng
        : LatLng(
            points.map((p) => p.latLng.latitude).reduce((a, b) => a + b) /
                points.length,
            points.map((p) => p.latLng.longitude).reduce((a, b) => a + b) /
                points.length,
          );
    final selected =
        _selectedIndex != null && _selectedIndex! < points.length
            ? points[_selectedIndex!]
            : null;
    final routeColor =
        _JourneyOverviewCard.routeColor.withValues(alpha: 0.72);

    final legend = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final stage in widget.legendStages)
          _JourneyLegendChip(
            color: _JourneyOverviewCard.colorFor(stage),
            label: OvertimeJourneyTimeline._stageTitle(
              l10n,
              stage,
              legacy: widget.legacy,
            ),
          ),
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.overtimeJourneyOverview,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            legend,
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                height: widget.mapHeight,
                width: double.infinity,
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: points.length == 1 ? 15 : 12,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                          onMapReady: () {
                            _fitCamera();
                            _onFocusChanged();
                          },
                          onTap: (_, _) {
                            if (_selectedIndex != null) {
                              setState(() => _selectedIndex = null);
                              widget.focus?.clear();
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            fallbackUrl:
                                'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                            userAgentPackageName: _tileUserAgent,
                            maxNativeZoom: 19,
                            maxZoom: 20,
                            keepBuffer: 2,
                            panBuffer: 1,
                          ),
                          if (points.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: points
                                      .map((p) => p.latLng)
                                      .toList(growable: false),
                                  color: routeColor,
                                  strokeWidth: 4.5,
                                  strokeCap: StrokeCap.round,
                                  strokeJoin: StrokeJoin.round,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              for (var i = 0; i < points.length; i++)
                                Marker(
                                  point: points[i].latLng,
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.topCenter,
                                  child: GestureDetector(
                                    onTap: () => _selectMarker(i),
                                    child: Icon(
                                      Icons.location_on,
                                      size: _selectedIndex == i
                                          ? _markerSelectedSize
                                          : _markerSize,
                                      color: points[i].color,
                                      shadows: const [
                                        Shadow(
                                          color: Color(0x73000000),
                                          blurRadius: 5,
                                          offset: Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SimpleAttributionWidget(
                            source: Text(
                              'OpenStreetMap',
                              style: theme.textTheme.labelSmall,
                            ),
                            alignment: Alignment.bottomRight,
                            backgroundColor: theme.colorScheme.surface
                                .withValues(alpha: 0.85),
                          ),
                        ],
                      ),
                      if (selected != null)
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 12,
                          child: _JourneyMarkerPopup(
                            point: selected,
                            onClose: () {
                              setState(() => _selectedIndex = null);
                              widget.focus?.clear();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyMarkerPopup extends StatelessWidget {
  const _JourneyMarkerPopup({
    required this.point,
    required this.onClose,
  });

  final _JourneyMapPoint point;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final checkpoint = point.checkpoint;
    final address = checkpoint.address?.trim();
    final rows = <(String, String)>[
      (
        l10n.overtimeGpsAccuracy,
        '${checkpoint.gps.accuracy.toStringAsFixed(0)} m',
      ),
      if (checkpoint.batteryLevel != null)
        (l10n.overtimeBatteryLevel, '${checkpoint.batteryLevel}%'),
      if (checkpoint.networkStatus != null &&
          checkpoint.networkStatus!.isNotEmpty)
        (l10n.overtimeNetworkStatus, checkpoint.networkStatus!),
      (
        l10n.overtimeLocation,
        (address != null && address.isNotEmpty)
            ? address
            : '${checkpoint.gps.latitude.toStringAsFixed(5)}, ${checkpoint.gps.longitude.toStringAsFixed(5)}',
      ),
    ];

    return Material(
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place, color: point.color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    point.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.mediumDateTime(context)
                        .format(checkpoint.at.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final row in rows) ...[
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${row.$1}: ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: row.$2,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      maxLines: row.$1 == l10n.overtimeLocation ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyLegendChip extends StatelessWidget {
  const _JourneyLegendChip({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
