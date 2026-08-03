import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_maps_launcher.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_fullscreen_image.dart';

enum _SyncBadge { synced, pending, failed, offline }

/// Vertical journey timeline — v2 four stages, or legacy start/end.
class OvertimeJourneyTimeline extends StatelessWidget {
  const OvertimeJourneyTimeline({
    super.key,
    required this.session,
    this.compact = false,
    this.pendingActions = const [],
    this.isOffline = false,
  });

  final OvertimeSession session;
  final bool compact;

  /// Queued offline actions for this device — used to render per-stage
  /// sync badges (pending / failed / offline).
  final List<PendingOvertimeAction> pendingActions;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stages = session.isV2Workflow
        ? OvertimeCheckpointStage.ordered
        : const [
            OvertimeCheckpointStage.startJourney,
            OvertimeCheckpointStage.endJourney,
          ];

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
            checkpoint: _checkpointFor(session, stages[i]),
            isNext: session.isRunning &&
                session.effectiveNextCheckpoint == stages[i],
            compact: compact,
            title: _stageTitle(l10n, stages[i], legacy: !session.isV2Workflow),
            syncBadge: _syncBadgeFor(stages[i]),
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
      ],
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
    required this.checkpoint,
    required this.isNext,
    required this.compact,
    required this.title,
    this.syncBadge,
  });

  static const double _indicatorSize = 28;

  final OvertimeCheckpointStage stage;
  final OvertimeCheckpoint? checkpoint;
  final bool isNext;
  final bool compact;
  final String title;
  final _SyncBadge? syncBadge;

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
                    // 1) Info  2) Actions  3) Interactive map  4) Selfie
                    const SizedBox(height: AppSpacing.md),
                    _CheckpointMapActions(
                      gps: checkpoint!.gps,
                      label: title,
                      address: checkpoint!.address,
                    ),
                    if (!compact &&
                        checkpoint!.photoUrl != null &&
                        checkpoint!.photoUrl!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: AspectRatio(
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
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _coords(GpsSnapshot gps) {
    return '${gps.latitude.toStringAsFixed(5)}, ${gps.longitude.toStringAsFixed(5)}';
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

/// Show Map (interactive embedded preview) + Open Live Location (Google Maps).
class _CheckpointMapActions extends StatefulWidget {
  const _CheckpointMapActions({
    required this.gps,
    required this.label,
    this.address,
  });

  final GpsSnapshot gps;
  final String label;
  final String? address;

  @override
  State<_CheckpointMapActions> createState() => _CheckpointMapActionsState();
}

class _CheckpointMapActionsState extends State<_CheckpointMapActions> {
  bool _expanded = false;
  bool _markerSelected = false;

  bool get _hasValidCoordinates {
    final lat = widget.gps.latitude;
    final lng = widget.gps.longitude;
    return lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  Future<void> _openLiveLocation() async {
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
      latitude: widget.gps.latitude,
      longitude: widget.gps.longitude,
      label: (widget.address?.trim().isNotEmpty == true)
          ? widget.address!.trim()
          : widget.label,
    );
    if (!mounted) {
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
    final theme = Theme.of(context);
    final canOpen = _hasValidCoordinates;
    final mapLabel = _expanded ? l10n.overtimeHideMap : l10n.overtimeShowMap;
    final liveLabel = l10n.overtimeOpenLiveLocation;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 12,
    );

    final showMapButton = OutlinedButton.icon(
      onPressed: () => setState(() => _expanded = !_expanded),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: buttonPadding,
        shape: buttonShape,
        alignment: Alignment.center,
      ),
      icon: Icon(
        _expanded ? Icons.map : Icons.map_outlined,
        size: 20,
      ),
      label: Text(
        mapLabel,
        textAlign: TextAlign.center,
        softWrap: true,
      ),
    );

    final liveLocationButton = Tooltip(
      message: canOpen
          ? liveLabel
          : l10n.overtimeLocationUnavailable,
      child: FilledButton.tonalIcon(
        onPressed: canOpen ? _openLiveLocation : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: buttonPadding,
          shape: buttonShape,
          alignment: Alignment.center,
        ),
        icon: const Icon(Icons.location_on_outlined, size: 20),
        label: Text(
          liveLabel,
          textAlign: TextAlign.center,
          softWrap: true,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Side-by-side only when both full labels fit comfortably.
            const minSideBySideWidth = 420.0;
            final stackVertically = constraints.maxWidth < minSideBySideWidth;

            if (stackVertically) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  showMapButton,
                  const SizedBox(height: AppSpacing.sm),
                  liveLocationButton,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: showMapButton),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: liveLocationButton),
              ],
            );
          },
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          if (!_hasValidCoordinates)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                l10n.overtimeLocationUnavailable,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            // Real interactive FlutterMap — same interaction model as legacy OT map.
            // Do not wrap with IgnorePointer / AbsorbPointer / EagerGestureRecognizer.
            _InteractiveCheckpointMap(
              gps: widget.gps,
              markerSelected: _markerSelected,
              onMarkerTap: () =>
                  setState(() => _markerSelected = !_markerSelected),
              onMapTap: () {
                if (_markerSelected) {
                  setState(() => _markerSelected = false);
                }
              },
            ),
        ],
      ],
    );
  }
}

/// Interactive FlutterMap — pan, zoom, pinch, double-tap, marker tap.
class _InteractiveCheckpointMap extends StatefulWidget {
  const _InteractiveCheckpointMap({
    required this.gps,
    required this.markerSelected,
    required this.onMarkerTap,
    required this.onMapTap,
  });

  final GpsSnapshot gps;
  final bool markerSelected;
  final VoidCallback onMarkerTap;
  final VoidCallback onMapTap;

  @override
  State<_InteractiveCheckpointMap> createState() =>
      _InteractiveCheckpointMapState();
}

class _InteractiveCheckpointMapState extends State<_InteractiveCheckpointMap> {
  static const String _tileUserAgent = 'com.infinitytech.fsm.mobile';

  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final point = LatLng(widget.gps.latitude, widget.gps.longitude);
    final pinColor = theme.colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: point,
              initialZoom: 16,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, _) => widget.onMapTap(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                fallbackUrl: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                userAgentPackageName: _tileUserAgent,
                maxNativeZoom: 19,
                maxZoom: 20,
                keepBuffer: 2,
                panBuffer: 1,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: widget.onMarkerTap,
                      child: Icon(
                        Icons.location_on,
                        size: widget.markerSelected ? 44 : 36,
                        color: pinColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
