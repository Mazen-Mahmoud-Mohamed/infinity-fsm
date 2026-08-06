import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/logger_service.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_voice_config.dart';
import 'package:mobile/features/overtime/domain/services/overtime_voice_record_config.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_voice_draft.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

export 'package:mobile/features/overtime/presentation/cubit/overtime_voice_draft.dart';

/// Fallback when server config is unavailable (5 minutes).
int get kOvertimeVoiceMaxSeconds =>
    OvertimeVoiceConfig.defaultMaxDurationSeconds;

/// Visual sync badge for a voice note card (presentation only).
enum OvertimeVoiceSyncBadge {
  none,
  pendingSync,
  uploading,
  uploaded,
}

/// Compact voice note controls for a single overtime journey stage.
///
/// [readOnly] — play only (admin / after successful upload).
/// Editable mode supports record, play, pause, delete, and re-record.
///
/// Recording / playback / upload behavior is unchanged — this widget only
/// polishes presentation around the existing flows.
class OvertimeVoiceNoteSection extends StatefulWidget {
  const OvertimeVoiceNoteSection({
    super.key,
    this.remoteUrl,
    this.localBytes,
    this.durationSeconds,
    this.maxDurationSeconds = OvertimeVoiceConfig.defaultMaxDurationSeconds,
    this.voiceRecordingQuality = OvertimeVoiceConfig.defaultVoiceQuality,
    this.readOnly = false,
    this.enabled = true,
    this.syncBadge = OvertimeVoiceSyncBadge.none,
    this.compact = false,
    this.onDraftChanged,
  });

  /// Cloudinary / remote HTTPS URL.
  final String? remoteUrl;

  /// Offline pending bytes (or current draft bytes for playback).
  final List<int>? localBytes;

  final double? durationSeconds;

  /// Maximum recording length in seconds (from company settings).
  final int maxDurationSeconds;

  /// Voice quality setting (high / medium / low).
  final String voiceRecordingQuality;
  final bool readOnly;
  final bool enabled;

  /// Uploaded / pending / uploading indicator for timeline & offline UX.
  final OvertimeVoiceSyncBadge syncBadge;

  /// Tighter padding when nested inside a journey stage card.
  final bool compact;

  /// Fired when the technician records, deletes, or re-records.
  final ValueChanged<OvertimeVoiceDraft?>? onDraftChanged;

  @override
  State<OvertimeVoiceNoteSection> createState() =>
      _OvertimeVoiceNoteSectionState();
}

class _OvertimeVoiceNoteSectionState extends State<OvertimeVoiceNoteSection>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _recording = false;
  bool _playing = false;
  bool _busy = false;
  bool _hitMaxLimit = false;
  bool _justFinished = false;
  bool _sourceReady = false;
  double _elapsedSeconds = 0;
  Duration _position = Duration.zero;
  Duration _playerDuration = Duration.zero;
  Timer? _tick;
  String? _localPath;
  List<int>? _bytes;
  double? _durationSeconds;
  int? _recordingMaxSeconds;
  late final AnimationController _pulseController;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  bool get _actionsLocked =>
      !widget.enabled ||
      _busy ||
      widget.syncBadge == OvertimeVoiceSyncBadge.uploading;

  bool get _hasAudio {
    final url = widget.remoteUrl;
    if (url != null &&
        url.isNotEmpty &&
        !url.startsWith('local-') &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return true;
    }
    if (_bytes != null && _bytes!.isNotEmpty) return true;
    if (widget.localBytes != null && widget.localBytes!.isNotEmpty) return true;
    if (_localPath != null && _localPath!.isNotEmpty) return true;
    return false;
  }

  double get _totalSeconds {
    final fromPlayer = _playerDuration.inMilliseconds / 1000.0;
    if (fromPlayer > 0.05) return fromPlayer;
    return (_durationSeconds ?? widget.durationSeconds ?? 0).toDouble();
  }

  double get _maxSeconds =>
      (_recording && _recordingMaxSeconds != null
              ? _recordingMaxSeconds!
              : widget.maxDurationSeconds)
          .toDouble();

  bool get _showLimitWarning =>
      _recording && (_maxSeconds - _elapsedSeconds) <= 30 && _elapsedSeconds > 0;

  OvertimeVoiceSyncBadge get _effectiveBadge {
    if (widget.syncBadge != OvertimeVoiceSyncBadge.none) {
      return widget.syncBadge;
    }
    final url = widget.remoteUrl;
    if (url != null &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return OvertimeVoiceSyncBadge.uploaded;
    }
    return OvertimeVoiceSyncBadge.none;
  }

  @override
  void initState() {
    super.initState();
    _bytes = widget.localBytes;
    _durationSeconds = widget.durationSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing;
      if (playing != _playing) {
        setState(() => _playing = playing);
      }
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
        unawaited(_player.seek(Duration.zero));
        unawaited(_player.pause());
      }
    });
    _positionSub = _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });
    _durationSub = _player.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      setState(() => _playerDuration = dur);
    });
  }

  @override
  void didUpdateWidget(covariant OvertimeVoiceNoteSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localBytes != widget.localBytes) {
      _bytes = widget.localBytes;
    }
    if (oldWidget.durationSeconds != widget.durationSeconds &&
        widget.durationSeconds != null) {
      _durationSeconds = widget.durationSeconds;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    unawaited(_positionSub?.cancel() ?? Future<void>.value());
    unawaited(_durationSub?.cancel() ?? Future<void>.value());
    unawaited(_playerStateSub?.cancel() ?? Future<void>.value());
    _pulseController.dispose();
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    if (widget.readOnly || _actionsLocked || _recording) return;
    final allowed = await _ensureMicPermission();
    if (!allowed) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.overtimeVoicePermissionDenied)),
      );
      return;
    }

    await _player.stop();
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'ot_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _recorder.start(
      OvertimeVoiceRecordConfig.resolve(widget.voiceRecordingQuality),
      path: path,
    );

    setState(() {
      _recording = true;
      _recordingMaxSeconds = widget.maxDurationSeconds;
      _elapsedSeconds = 0;
      _localPath = path;
      _bytes = null;
      _durationSeconds = null;
      _hitMaxLimit = false;
      _justFinished = false;
      _sourceReady = false;
      _position = Duration.zero;
      _playerDuration = Duration.zero;
    });
    unawaited(_pulseController.repeat(reverse: true));

    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || !_recording) {
        timer.cancel();
        return;
      }
      final next = _elapsedSeconds + 1;
      setState(() => _elapsedSeconds = next);
      if (next >= (_recordingMaxSeconds ?? widget.maxDurationSeconds)) {
        await _stopRecording(hitMaxLimit: true);
      }
    });
  }

  Future<void> _stopRecording({bool hitMaxLimit = false}) async {
    if (!_recording) return;
    _tick?.cancel();
    _pulseController
      ..stop()
      ..reset();
    final path = await _recorder.stop();
    if (!mounted) return;

    setState(() {
      _recording = false;
      _recordingMaxSeconds = null;
      _busy = true;
      _hitMaxLimit = hitMaxLimit;
    });

    try {
      final filePath = path ?? _localPath;
      if (filePath == null) {
        setState(() => _busy = false);
        return;
      }
      final file = File(filePath);
      if (!await file.exists()) {
        setState(() => _busy = false);
        return;
      }
      final bytes = await file.readAsBytes();
      final duration =
          _elapsedSeconds.clamp(0, widget.maxDurationSeconds).toDouble();
      final draft = OvertimeVoiceDraft(
        filePath: filePath,
        bytes: bytes,
        durationSeconds: duration,
      );
      setState(() {
        _localPath = filePath;
        _bytes = bytes;
        _durationSeconds = duration;
        _busy = false;
        _justFinished = true;
      });
      widget.onDraftChanged?.call(draft);
    } on Object {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteRecording() async {
    if (widget.readOnly || _actionsLocked) return;
    await _player.stop();
    final path = _localPath;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } on Object {
        // Best-effort cleanup.
      }
    }
    setState(() {
      _localPath = null;
      _bytes = null;
      _durationSeconds = null;
      _elapsedSeconds = 0;
      _playing = false;
      _justFinished = false;
      _hitMaxLimit = false;
      _sourceReady = false;
      _position = Duration.zero;
      _playerDuration = Duration.zero;
    });
    widget.onDraftChanged?.call(null);
  }

  Future<void> _rerecord() async {
    if (widget.readOnly || _actionsLocked) return;
    await _deleteRecording();
    await _startRecording();
  }

  Future<void> _togglePlay() async {
    if (_actionsLocked || _recording) return;
    if (_playing) {
      _debugVoiceLog('pause requested');
      await _player.pause();
      return;
    }

    setState(() => _busy = true);
    try {
      if (!_sourceReady) {
        final remote = widget.remoteUrl;
        if (remote != null &&
            remote.isNotEmpty &&
            (remote.startsWith('http://') || remote.startsWith('https://'))) {
          _debugVoiceLog('setUrl remote=$remote');
          await _player.setUrl(remote);
          _debugVoiceLog(
            'setUrl completed state=${_player.playerState} '
            'duration=${_player.duration}',
          );
        } else if (_localPath != null && await File(_localPath!).exists()) {
          _debugVoiceLog('setFilePath local=$_localPath');
          await _player.setFilePath(_localPath!);
          _debugVoiceLog(
            'setFilePath completed state=${_player.playerState} '
            'duration=${_player.duration}',
          );
        } else {
          final bytes = _bytes ?? widget.localBytes;
          if (bytes == null || bytes.isEmpty) {
            setState(() => _busy = false);
            return;
          }
          final dir = await getTemporaryDirectory();
          final path = p.join(
            dir.path,
            'ot_voice_play_${DateTime.now().millisecondsSinceEpoch}.m4a',
          );
          await File(path).writeAsBytes(bytes, flush: true);
          _localPath = path;
          _debugVoiceLog('setFilePath fromBytes=$path bytes=${bytes.length}');
          await _player.setFilePath(path);
          _debugVoiceLog(
            'setFilePath(fromBytes) completed state=${_player.playerState}',
          );
        }
        _sourceReady = true;
      }
      _debugVoiceLog(
        'play() state=${_player.playerState} position=${_player.position}',
      );
      await _player.play();
      _debugVoiceLog(
        'play() returned state=${_player.playerState} '
        'playing=${_player.playing}',
      );
    } on Object catch (error, stackTrace) {
      _sourceReady = false;
      _logVoicePlaybackError(error, stackTrace);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.overtimeVoicePlaybackFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _debugVoiceLog(String message) {
    if (!kDebugMode) return;
    try {
      getIt<LoggerService>().debug('[OvertimeVoice] $message');
    } on Object {
      debugPrint('[OvertimeVoice] $message');
    }
  }

  void _logVoicePlaybackError(Object error, StackTrace stackTrace) {
    final remote = widget.remoteUrl;
    final message =
        '[OvertimeVoice] playback failed url=$remote local=$_localPath '
        'state=${_player.playerState} error=$error';
    try {
      getIt<LoggerService>().error(message, error, stackTrace);
    } on Object {
      debugPrint(message);
      debugPrint('$error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _seekRelative(double value) async {
    final totalMs = (_totalSeconds * 1000).round().clamp(0, 3600000);
    if (totalMs <= 0) return;
    final target = Duration(milliseconds: (value * totalMs).round());
    await _player.seek(target);
  }

  String _formatDuration(double? seconds) {
    final total = (seconds ?? 0).round().clamp(0, 3600);
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDurationMs(Duration d) {
    return _formatDuration(d.inMilliseconds / 1000.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final semantic = AppThemeColors.of(context);
    final isDesktop = AppBreakpoints.isDesktopOf(context);
    final pad = widget.compact
        ? AppSpacing.sm
        : (isDesktop ? AppSpacing.md : AppSpacing.md);
    final iconSize = isDesktop ? 22.0 : 24.0;
    final minTap = isDesktop ? 40.0 : 48.0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderRow(
                l10n: l10n,
                badge: _effectiveBadge,
                theme: theme,
              ),
              if (!widget.readOnly) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.overtimeVoiceMaxRecordingInfo(
                          OvertimeMediaConfig.minutesFromSeconds(
                            widget.maxDurationSeconds,
                          ),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              if (_recording)
                _RecordingPanel(
                  elapsedLabel: _formatDuration(_elapsedSeconds),
                  maxLabel: _formatDuration(_maxSeconds),
                  pulse: _pulseController,
                  enabled: !_actionsLocked,
                  iconSize: iconSize,
                  minTap: minTap,
                  onStop: () => _stopRecording(),
                  l10n: l10n,
                  isDesktop: isDesktop,
                  showLimitWarning: _showLimitWarning,
                )
              else if (!_hasAudio && !widget.readOnly)
                _IdleRecordButton(
                  onPressed: _actionsLocked ? null : _startRecording,
                  l10n: l10n,
                  isDesktop: isDesktop,
                  minTap: minTap,
                )
              else if (_hasAudio)
                _PlayerPanel(
                  playing: _playing,
                  busy: _busy,
                  locked: _actionsLocked,
                  readOnly: widget.readOnly,
                  justFinished: _justFinished && !widget.readOnly,
                  position: _position,
                  totalSeconds: _totalSeconds,
                  format: _formatDuration,
                  formatMs: _formatDurationMs,
                  iconSize: iconSize,
                  minTap: minTap,
                  isDesktop: isDesktop,
                  l10n: l10n,
                  semantic: semantic,
                  theme: theme,
                  onTogglePlay: _togglePlay,
                  onSeek: _seekRelative,
                  onDelete: _deleteRecording,
                  onRerecord: _rerecord,
                )
              else if (widget.readOnly)
                Text(
                  l10n.overtimeVoiceNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (_hitMaxLimit) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.overtimeVoiceMaxReached,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (!widget.readOnly && !_hasAudio && !_recording) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.overtimeVoiceMaxDurationHint(
                    widget.maxDurationSeconds ~/ 60,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (widget.syncBadge == OvertimeVoiceSyncBadge.uploading) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: semantic.warning,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.overtimeVoiceUploading,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: semantic.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.l10n,
    required this.badge,
    required this.theme,
  });

  final AppLocalizations l10n;
  final OvertimeVoiceSyncBadge badge;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.mic_none_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            l10n.overtimeVoiceNote,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (badge != OvertimeVoiceSyncBadge.none) _SyncChip(badge: badge),
      ],
    );
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip({required this.badge});

  final OvertimeVoiceSyncBadge badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = AppThemeColors.of(context);

    late final Color color;
    late final IconData icon;
    late final String label;

    switch (badge) {
      case OvertimeVoiceSyncBadge.uploaded:
        color = semantic.success;
        icon = Icons.check_circle_rounded;
        label = l10n.overtimeVoiceUploaded;
      case OvertimeVoiceSyncBadge.pendingSync:
        color = semantic.warning;
        icon = Icons.cloud_upload_outlined;
        label = l10n.overtimeVoiceWaitingSync;
      case OvertimeVoiceSyncBadge.uploading:
        color = semantic.warning;
        icon = Icons.cloud_sync_outlined;
        label = l10n.overtimeVoiceUploading;
      case OvertimeVoiceSyncBadge.none:
        return const SizedBox.shrink();
    }

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleRecordButton extends StatelessWidget {
  const _IdleRecordButton({
    required this.onPressed,
    required this.l10n,
    required this.isDesktop,
    required this.minTap,
  });

  final VoidCallback? onPressed;
  final AppLocalizations l10n;
  final bool isDesktop;
  final double minTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: l10n.overtimeVoiceRecord,
      child: SizedBox(
        width: double.infinity,
        height: minTap + (isDesktop ? 4 : 8),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.mic_rounded),
          label: Text(l10n.overtimeVoiceRecord),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: isDesktop ? AppSpacing.sm : AppSpacing.md,
            ),
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordingPanel extends StatelessWidget {
  const _RecordingPanel({
    required this.elapsedLabel,
    required this.maxLabel,
    required this.pulse,
    required this.enabled,
    required this.iconSize,
    required this.minTap,
    required this.onStop,
    required this.l10n,
    required this.isDesktop,
    required this.showLimitWarning,
  });

  final String elapsedLabel;
  final String maxLabel;
  final AnimationController pulse;
  final bool enabled;
  final double iconSize;
  final double minTap;
  final VoidCallback onStop;
  final AppLocalizations l10n;
  final bool isDesktop;
  final bool showLimitWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: pulse,
              builder: (context, child) {
                final t = pulse.value;
                return Container(
                  width: minTap,
                  height: minTap,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: error.withValues(alpha: 0.10 + (t * 0.16)),
                    boxShadow: [
                      BoxShadow(
                        color: error.withValues(alpha: 0.18 + (t * 0.22)),
                        blurRadius: 8 + (t * 10),
                        spreadRadius: t * 2,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Icon(Icons.mic, color: error, size: iconSize + 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.overtimeVoiceRecording,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$elapsedLabel / $maxLabel',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: l10n.overtimeVoiceStop,
              child: Tooltip(
                message: l10n.overtimeVoiceStop,
                child: FilledButton.tonalIcon(
                  onPressed: enabled ? onStop : null,
                  icon: const Icon(Icons.stop_rounded),
                  label: Text(l10n.overtimeVoiceStop),
                  style: FilledButton.styleFrom(
                    foregroundColor: error,
                    minimumSize: Size(isDesktop ? 108 : 96, minTap - 4),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showLimitWarning) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.overtimeVoiceLimitWarning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.playing,
    required this.busy,
    required this.locked,
    required this.readOnly,
    required this.justFinished,
    required this.position,
    required this.totalSeconds,
    required this.format,
    required this.formatMs,
    required this.iconSize,
    required this.minTap,
    required this.isDesktop,
    required this.l10n,
    required this.semantic,
    required this.theme,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onDelete,
    required this.onRerecord,
  });

  final bool playing;
  final bool busy;
  final bool locked;
  final bool readOnly;
  final bool justFinished;
  final Duration position;
  final double totalSeconds;
  final String Function(double?) format;
  final String Function(Duration) formatMs;
  final double iconSize;
  final double minTap;
  final bool isDesktop;
  final AppLocalizations l10n;
  final AppThemeColors semantic;
  final ThemeData theme;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onSeek;
  final VoidCallback onDelete;
  final VoidCallback onRerecord;

  @override
  Widget build(BuildContext context) {
    final total = totalSeconds <= 0 ? 0.001 : totalSeconds;
    final progress =
        (position.inMilliseconds / 1000.0 / total).clamp(0.0, 1.0);
    final accent = playing
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (justFinished && !readOnly) ...[
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 18, color: semantic.success),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.overtimeVoiceRecorded,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: semantic.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Semantics(
              button: true,
              label: playing ? l10n.overtimeVoicePause : l10n.overtimeVoicePlay,
              child: Tooltip(
                message:
                    playing ? l10n.overtimeVoicePause : l10n.overtimeVoicePlay,
                child: Material(
                  color: accent.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: locked || busy ? null : onTogglePlay,
                    child: SizedBox(
                      width: minTap,
                      height: minTap,
                      child: busy
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: iconSize + 2,
                              color: theme.colorScheme.primary,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: isDesktop ? 4 : 3,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: isDesktop ? 7 : 8,
                      ),
                      overlayShape: RoundSliderOverlayShape(
                        overlayRadius: isDesktop ? 14 : 16,
                      ),
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor:
                          theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      thumbColor: theme.colorScheme.primary,
                      overlayColor:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: progress.isFinite ? progress : 0,
                      onChanged: locked || busy
                          ? null
                          : (v) {
                              onSeek(v);
                            },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Text(
                          formatMs(position),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          format(totalSeconds),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!readOnly) ...[
              const SizedBox(width: AppSpacing.xs),
              Semantics(
                button: true,
                label: l10n.overtimeVoiceRerecord,
                child: Tooltip(
                  message: l10n.overtimeVoiceRerecord,
                  child: IconButton(
                    onPressed: locked || busy ? null : onRerecord,
                    iconSize: iconSize,
                    constraints: BoxConstraints(
                      minWidth: minTap,
                      minHeight: minTap,
                    ),
                    icon: const Icon(Icons.mic_none_rounded),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: l10n.overtimeVoiceDelete,
                child: Tooltip(
                  message: l10n.overtimeVoiceDelete,
                  child: IconButton(
                    onPressed: locked || busy ? null : onDelete,
                    iconSize: iconSize,
                    constraints: BoxConstraints(
                      minWidth: minTap,
                      minHeight: minTap,
                    ),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        // Keyboard focus affordance on desktop: focusable play control above.
        if (isDesktop)
          Focus(
            descendantsAreFocusable: true,
            child: Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (_) {
                      if (!locked && !busy) onTogglePlay();
                      return null;
                    },
                  ),
                },
                child: const SizedBox.shrink(),
              ),
            ),
          ),
      ],
    );
  }
}
