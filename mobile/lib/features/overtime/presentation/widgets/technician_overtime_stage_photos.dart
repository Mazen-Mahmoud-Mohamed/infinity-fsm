import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_fullscreen_image.dart';

class TechnicianStagePhotoEntry {
  TechnicianStagePhotoEntry({
    required this.label,
    this.networkUrl,
    this.localBytes,
  }) : assert(
          (networkUrl != null && networkUrl.isNotEmpty) ||
              (localBytes != null && localBytes.isNotEmpty),
        );

  final String label;
  final String? networkUrl;
  final Uint8List? localBytes;
}

/// Presentation-only photos for the technician overtime screen.
///
/// Shows uploaded checkpoint photos without GPS, address, or sync metadata.
class TechnicianOvertimeStagePhotos extends StatelessWidget {
  const TechnicianOvertimeStagePhotos({
    super.key,
    required this.session,
    this.pendingActions = const [],
  });

  final OvertimeSession session;
  final List<PendingOvertimeAction> pendingActions;

  static List<TechnicianStagePhotoEntry> collectEntries(
    OvertimeSession session,
    List<PendingOvertimeAction> pendingActions,
    AppLocalizations l10n,
  ) {
    final legacy = !session.isV2Workflow;
    final stages = session.isV2Workflow
        ? OvertimeCheckpointStage.ordered
        : const [
            OvertimeCheckpointStage.startJourney,
            OvertimeCheckpointStage.endJourney,
          ];

    final entries = <TechnicianStagePhotoEntry>[];
    for (final stage in stages) {
      final checkpoint = _checkpointFor(session, stage);
      final pending = _pendingFor(pendingActions, stage);
      final label = _stageTitle(l10n, stage, legacy: legacy);
      final networkUrl = checkpoint?.photoUrl;
      if (networkUrl != null && networkUrl.isNotEmpty) {
        entries.add(
          TechnicianStagePhotoEntry(label: label, networkUrl: networkUrl),
        );
        continue;
      }
      final bytes = pending?.photoBytes;
      if (bytes != null && bytes.isNotEmpty) {
        entries.add(
          TechnicianStagePhotoEntry(
            label: label,
            localBytes: Uint8List.fromList(bytes),
          ),
        );
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = collectEntries(session, pendingActions, l10n);
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.overtimeImages, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in entries) ...[
          _TechnicianPhotoTile(entry: entry),
          if (entry != entries.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  static OvertimeCheckpoint? _checkpointFor(
    OvertimeSession session,
    OvertimeCheckpointStage stage,
  ) {
    if (session.isV2Workflow) {
      return session.checkpoints?.forStage(stage);
    }
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

  static PendingOvertimeAction? _pendingFor(
    List<PendingOvertimeAction> pendingActions,
    OvertimeCheckpointStage stage,
  ) {
    for (final action in pendingActions) {
      if (action.checkpointStage == stage) {
        return action;
      }
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

class _TechnicianPhotoTile extends StatelessWidget {
  const _TechnicianPhotoTile({required this.entry});

  final TechnicianStagePhotoEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final networkUrl = entry.networkUrl;
    final localBytes = entry.localBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(entry.label, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: InkWell(
              onTap: () {
                if (networkUrl != null && networkUrl.isNotEmpty) {
                  openOvertimeFullscreenImage(
                    context,
                    imageUrl: networkUrl,
                    title: entry.label,
                  );
                  return;
                }
                if (localBytes != null && localBytes.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _LocalFullscreenImagePage(
                        bytes: localBytes,
                        title: entry.label,
                      ),
                    ),
                  );
                }
              },
              child: networkUrl != null && networkUrl.isNotEmpty
                  ? AppCachedNetworkImage(
                      imageUrl: networkUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                    )
                  : Image.memory(
                      localBytes!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocalFullscreenImagePage extends StatelessWidget {
  const _LocalFullscreenImagePage({
    required this.bytes,
    required this.title,
  });

  final Uint8List bytes;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
