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

/// Playback / availability UI state for [OvertimeVoiceNoteSection].
enum OvertimeVoiceUiState {
  loading,
  ready,
  playing,
  paused,
  unavailable,
}

/// Returns true when [url] is a usable remote HTTP(S) audio URL.
bool isOvertimeVoiceRemoteUrlValid(String? url) {
  if (url == null) return false;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('local-')) return false;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return false;
  if (!uri.hasScheme) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  if (uri.host.isEmpty) return false;
  return true;
}

/// Optional factory hooks for tests (injection without DI framework).
@visibleForTesting
AudioPlayer Function()? debugOvertimeAudioPlayerFactory;

@visibleForTesting
AudioRecorder Function()? debugOvertimeAudioRecorderFactory;

/// Compact voice note controls for a single overtime journey stage.
///
/// [readOnly] — play only (admin / after successful upload).
/// Editable mode supports record, play, pause, delete, and re-record.
///
/// Recording / playback / upload behavior is unchanged — this widget only
/// polishes presentation around the existing flows.
///
/// Failures (invalid URL, player init, playback) stay inside this widget as
/// [OvertimeVoiceUiState.unavailable] and must never blank the parent page.
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
  AudioRecorder? _recorder;
  AudioPlayer? _player;

  bool _recording = false;
  bool _playing = false;
  bool _busy = false;
  bool _hitMaxLimit = false;
  bool _justFinished = false;
  bool _sourceReady = false;
  bool _disposed = false;
  OvertimeVoiceUiState _uiState = OvertimeVoiceUiState.ready;
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
      _uiState == OvertimeVoiceUiState.unavailable ||
      widget.syncBadge == OvertimeVoiceSyncBadge.uploading;

  bool get _hasAudio {
    if (isOvertimeVoiceRemoteUrlValid(widget.remoteUrl)) return true;
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
    if (isOvertimeVoiceRemoteUrlValid(widget.remoteUrl)) {
      return OvertimeVoiceSyncBadge.uploaded;
    }
    return OvertimeVoiceSyncBadge.none;
  }

  OvertimeVoiceUiState get _resolvedUiState {
    if (_uiState == OvertimeVoiceUiState.unavailable) {
      return OvertimeVoiceUiState.unavailable;
    }
    if (_busy && !_playing && !_recording) {
      return OvertimeVoiceUiState.loading;
    }
    if (_playing) return OvertimeVoiceUiState.playing;
    if (_hasAudio) return OvertimeVoiceUiState.paused;
    return OvertimeVoiceUiState.ready;
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
    // Read-only admin cards with a non-usable remote URL → unavailable UI,
    // never attempt player construction for a known-bad source.
    if (widget.readOnly &&
        !_hasLocalPlayableSource() &&
        widget.remoteUrl != null &&
        widget.remoteUrl!.trim().isNotEmpty &&
        !isOvertimeVoiceRemoteUrlValid(widget.remoteUrl)) {
      _uiState = OvertimeVoiceUiState.unavailable;
    }
  }

  bool _hasLocalPlayableSource() {
    if (_bytes != null && _bytes!.isNotEmpty) return true;
    if (widget.localBytes != null && widget.localBytes!.isNotEmpty) return true;
    if (_localPath != null && _localPath!.isNotEmpty) return true;
    return false;
  }

  AudioPlayer? _ensurePlayer() {
    if (_disposed || _uiState == OvertimeVoiceUiState.unavailable) {
      return null;
    }
    if (_player != null) return _player;
    try {
      final factory = debugOvertimeAudioPlayerFactory;
      final player = factory != null ? factory() : AudioPlayer();
      _player = player;
      _playerStateSub = player.playerStateStream.listen(
        (state) {
          if (!mounted || _disposed) return;
          final playing = state.playing;
          if (playing != _playing) {
            setState(() => _playing = playing);
          }
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _playing = false;
              _position = Duration.zero;
            });
            unawaited(_safePlayerOp(() => player.seek(Duration.zero)));
            unawaited(_safePlayerOp(player.pause));
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _markUnavailable(error, stackTrace);
        },
      );
      _positionSub = player.positionStream.listen(
        (pos) {
          if (!mounted || _disposed) return;
          setState(() => _position = pos);
        },
        onError: (Object error, StackTrace stackTrace) {
          _markUnavailable(error, stackTrace);
        },
      );
      _durationSub = player.durationStream.listen(
        (dur) {
          if (!mounted || _disposed || dur == null) return;
          setState(() => _playerDuration = dur);
        },
        onError: (Object error, StackTrace stackTrace) {
          _markUnavailable(error, stackTrace);
        },
      );
      return player;
    } on Object catch (error, stackTrace) {
      _markUnavailable(error, stackTrace);
      return null;
    }
  }

  AudioRecorder? _ensureRecorder() {
    if (_disposed || widget.readOnly) return null;
    if (_recorder != null) return _recorder;
    try {
      final factory = debugOvertimeAudioRecorderFactory;
      _recorder = factory != null ? factory() : AudioRecorder();
      return _recorder;
    } on Object catch (error, stackTrace) {
      _markUnavailable(error, stackTrace);
      return null;
    }
  }

  void _markUnavailable(Object error, StackTrace stackTrace) {
    _logVoicePlaybackError(error, stackTrace);
    if (_disposed) return;
    _sourceReady = false;
    if (!mounted) {
      _uiState = OvertimeVoiceUiState.unavailable;
      return;
    }
    setState(() {
      _uiState = OvertimeVoiceUiState.unavailable;
      _playing = false;
      _busy = false;
      _recording = false;
    });
  }

  Future<void> _safePlayerOp(Future<void> Function() op) async {
    try {
      await op();
    } on Object {
      // Best-effort; never escape to the parent page.
    }
  }

  @override
  void didUpdateWidget(covariant OvertimeVoiceNoteSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hadExternalAudio = _hasExternalAudio(
      remoteUrl: oldWidget.remoteUrl,
      localBytes: oldWidget.localBytes,
    );
    final hasExternalAudio = _hasExternalAudio(
      remoteUrl: widget.remoteUrl,
      localBytes: widget.localBytes,
    );

    if (oldWidget.localBytes != widget.localBytes) {
      _bytes = widget.localBytes;
    }
    if (oldWidget.durationSeconds != widget.durationSeconds &&
        widget.durationSeconds != null) {
      _durationSeconds = widget.durationSeconds;
    }

    if (widget.readOnly &&
        !_hasLocalPlayableSource() &&
        widget.remoteUrl != null &&
        widget.remoteUrl!.trim().isNotEmpty &&
        !isOvertimeVoiceRemoteUrlValid(widget.remoteUrl)) {
      _uiState = OvertimeVoiceUiState.unavailable;
    } else if (_uiState == OvertimeVoiceUiState.unavailable &&
        (isOvertimeVoiceRemoteUrlValid(widget.remoteUrl) ||
            _hasLocalPlayableSource())) {
      // New valid source arrived — allow retry.
      _uiState = OvertimeVoiceUiState.ready;
    }

    // Parent cleared the draft (e.g. after advancing a stage). Drop local UI
    // state so the active recorder looks empty — without deleting files.
    if (!widget.readOnly &&
        hadExternalAudio &&
        !hasExternalAudio &&
        !_recording) {
      unawaited(_resetActiveRecorderUi());
    } else if (oldWidget.remoteUrl != widget.remoteUrl ||
        oldWidget.localBytes != widget.localBytes) {
      _sourceReady = false;
    }
  }

  bool _hasExternalAudio({
    required String? remoteUrl,
    required List<int>? localBytes,
  }) {
    if (isOvertimeVoiceRemoteUrlValid(remoteUrl)) return true;
    return localBytes != null && localBytes.isNotEmpty;
  }

  /// Clears playback/recording presentation for a fresh stage.
  /// Does not delete files or notify [onDraftChanged].
  Future<void> _resetActiveRecorderUi() async {
    _tick?.cancel();
    _tick = null;
    if (_pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..value = 0;
    }
    final player = _player;
    if (player != null) {
      await _safePlayerOp(player.stop);
    }
    if (!mounted || _disposed) return;
    setState(() {
      _localPath = null;
      _bytes = null;
      _durationSeconds = null;
      _elapsedSeconds = 0;
      _recording = false;
      _playing = false;
      _busy = false;
      _justFinished = false;
      _hitMaxLimit = false;
      _sourceReady = false;
      _position = Duration.zero;
      _playerDuration = Duration.zero;
      _recordingMaxSeconds = null;
      if (_uiState != OvertimeVoiceUiState.unavailable) {
        _uiState = OvertimeVoiceUiState.ready;
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    unawaited(_positionSub?.cancel() ?? Future<void>.value());
    unawaited(_durationSub?.cancel() ?? Future<void>.value());
    unawaited(_playerStateSub?.cancel() ?? Future<void>.value());
    _pulseController.dispose();
    final recorder = _recorder;
    final player = _player;
    _recorder = null;
    _player = null;
    if (recorder != null) {
      unawaited(() async {
        try {
          await recorder.dispose();
        } on Object {
          // Ignore dispose races.
        }
      }());
    }
    if (player != null) {
      unawaited(() async {
        try {
          await player.dispose();
        } on Object {
          // Ignore dispose races.
        }
      }());
    }
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

    final recorder = _ensureRecorder();
    if (recorder == null) return;

    final player = _ensurePlayer();
    if (player != null) {
      await _safePlayerOp(player.stop);
    }
    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'ot_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    try {
      await recorder.start(
        OvertimeVoiceRecordConfig.resolve(widget.voiceRecordingQuality),
        path: path,
      );
    } on Object catch (error, stackTrace) {
      _markUnavailable(error, stackTrace);
      return;
    }

    if (!mounted || _disposed) return;
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
      if (!mounted || !_recording || _disposed) {
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
    final recorder = _recorder;
    String? path;
    try {
      path = await recorder?.stop();
    } on Object catch (error, stackTrace) {
      _markUnavailable(error, stackTrace);
      return;
    }
    if (!mounted || _disposed) return;

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
    final player = _player;
    if (player != null) {
      await _safePlayerOp(player.stop);
    }
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
    if (!mounted || _disposed) return;
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
      final player = _player;
      if (player != null) {
        await _safePlayerOp(player.pause);
      }
      return;
    }

    if (widget.readOnly &&
        !_hasLocalPlayableSource() &&
        !isOvertimeVoiceRemoteUrlValid(widget.remoteUrl)) {
      _markUnavailable(
        StateError('Invalid voice note URL: ${widget.remoteUrl}'),
        StackTrace.current,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final player = _ensurePlayer();
      if (player == null) {
        return;
      }
      if (!_sourceReady) {
        final remote = widget.remoteUrl;
        if (isOvertimeVoiceRemoteUrlValid(remote)) {
          _debugVoiceLog('setUrl remote=$remote');
          await player.setUrl(remote!.trim());
          _debugVoiceLog(
            'setUrl completed state=${player.playerState} '
            'duration=${player.duration}',
          );
        } else if (_localPath != null && await File(_localPath!).exists()) {
          _debugVoiceLog('setFilePath local=$_localPath');
          await player.setFilePath(_localPath!);
          _debugVoiceLog(
            'setFilePath completed state=${player.playerState} '
            'duration=${player.duration}',
          );
        } else {
          final bytes = _bytes ?? widget.localBytes;
          if (bytes == null || bytes.isEmpty) {
            _markUnavailable(
              StateError('No playable voice note source'),
              StackTrace.current,
            );
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
          await player.setFilePath(path);
          _debugVoiceLog(
            'setFilePath(fromBytes) completed state=${player.playerState}',
          );
        }
        _sourceReady = true;
      }
      if (_disposed || !mounted) return;
      _debugVoiceLog(
        'play() state=${player.playerState} position=${player.position}',
      );
      await player.play();
      _debugVoiceLog(
        'play() returned state=${player.playerState} '
        'playing=${player.playing}',
      );
    } on Object catch (error, stackTrace) {
      _sourceReady = false;
      _markUnavailable(error, stackTrace);
      if (mounted && !_disposed) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.overtimeVoicePlaybackFailed)),
        );
      }
    } finally {
      if (mounted && !_disposed) setState(() => _busy = false);
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
        'state=${_player?.playerState} error=$error';
    try {
      getIt<LoggerService>().error(message, error, stackTrace);
    } on Object {
      debugPrint(message);
      debugPrint('$error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _seekRelative(double value) async {
    final player = _player;
    if (player == null) return;
    final totalMs = (_totalSeconds * 1000).round().clamp(0, 3600000);
    if (totalMs <= 0) return;
    final target = Duration(milliseconds: (value * totalMs).round());
    await _safePlayerOp(() => player.seek(target));
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
        ? AppSpacing.md
        : (isDesktop ? AppSpacing.lg : AppSpacing.md);
    const iconSize = 24.0;
    const minTap = 48.0;
    final uiState = _resolvedUiState;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderBlock(
                l10n: l10n,
                badge: _effectiveBadge,
                theme: theme,
              ),
              if (!widget.readOnly) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.overtimeVoiceMaxRecordingInfo(
                    OvertimeMediaConfig.minutesFromSeconds(
                      widget.maxDurationSeconds,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: uiState == OvertimeVoiceUiState.unavailable
                    ? _UnavailablePanel(
                        key: const ValueKey('unavailable'),
                        message: l10n.overtimeVoiceUnavailable,
                        theme: theme,
                      )
                    : _recording
                    ? _RecordingPanel(
                        key: const ValueKey('recording'),
                        elapsedLabel: _formatDuration(_elapsedSeconds),
                        maxLabel: _formatDuration(_maxSeconds),
                        progress: (_elapsedSeconds / _maxSeconds).clamp(
                          0.0,
                          1.0,
                        ),
                        pulse: _pulseController,
                        enabled: !_actionsLocked,
                        iconSize: iconSize,
                        minTap: minTap,
                        onStop: () => _stopRecording(),
                        l10n: l10n,
                        showLimitWarning: _showLimitWarning,
                      )
                    : !_hasAudio && !widget.readOnly
                    ? _IdleRecordButton(
                        key: const ValueKey('idle'),
                        onPressed: _actionsLocked ? null : _startRecording,
                        l10n: l10n,
                        minTap: minTap,
                      )
                    : _hasAudio
                    ? _PlayerPanel(
                        key: const ValueKey('player'),
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
                        l10n: l10n,
                        semantic: semantic,
                        theme: theme,
                        onTogglePlay: _togglePlay,
                        onSeek: _seekRelative,
                        onDelete: _deleteRecording,
                        onRerecord: _rerecord,
                      )
                    : widget.readOnly
                    ? Text(
                        key: const ValueKey('empty'),
                        l10n.overtimeVoiceNote,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('none')),
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
                const SizedBox(height: AppSpacing.sm),
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
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
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

class _UnavailablePanel extends StatelessWidget {
  const _UnavailablePanel({
    super.key,
    required this.message,
    required this.theme,
  });

  final String message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.mic_off_outlined,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({
    required this.l10n,
    required this.badge,
    required this.theme,
  });

  final AppLocalizations l10n;
  final OvertimeVoiceSyncBadge badge;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none_rounded,
              size: 22,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.overtimeVoiceNote,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (badge != OvertimeVoiceSyncBadge.none) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _SyncChip(badge: badge),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
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
    super.key,
    required this.onPressed,
    required this.l10n,
    required this.minTap,
  });

  final VoidCallback? onPressed;
  final AppLocalizations l10n;
  final double minTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: l10n.overtimeVoiceRecord,
      child: SizedBox(
        width: double.infinity,
        height: minTap + 8,
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: const Icon(Icons.mic_rounded, size: 22),
          label: Text(l10n.overtimeVoiceRecord),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordingPanel extends StatelessWidget {
  const _RecordingPanel({
    super.key,
    required this.elapsedLabel,
    required this.maxLabel,
    required this.progress,
    required this.pulse,
    required this.enabled,
    required this.iconSize,
    required this.minTap,
    required this.onStop,
    required this.l10n,
    required this.showLimitWarning,
  });

  final String elapsedLabel;
  final String maxLabel;
  final double progress;
  final AnimationController pulse;
  final bool enabled;
  final double iconSize;
  final double minTap;
  final VoidCallback onStop;
  final AppLocalizations l10n;
  final bool showLimitWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              final t = pulse.value;
              return Container(
                width: minTap + 16,
                height: minTap + 16,
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
            child: Icon(Icons.mic, color: error, size: iconSize + 4),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.overtimeVoiceRecording,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: error,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.isFinite ? progress : 0,
            minHeight: 8,
            backgroundColor: theme.colorScheme.outlineVariant.withValues(
              alpha: 0.35,
            ),
            color: error,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$elapsedLabel / $maxLabel',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        if (showLimitWarning) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.overtimeVoiceLimitWarning,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Semantics(
            button: true,
            label: l10n.overtimeVoiceStop,
            child: Tooltip(
              message: l10n.overtimeVoiceStop,
              child: FilledButton.tonalIcon(
                onPressed: enabled ? onStop : null,
                icon: const Icon(Icons.stop_rounded, size: 22),
                label: Text(l10n.overtimeVoiceStop),
                style: FilledButton.styleFrom(
                  foregroundColor: error,
                  minimumSize: Size(140, minTap),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.minTap,
    required this.iconSize,
    this.color,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double minTap;
  final double iconSize;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: filled
              ? effectiveColor.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: minTap,
              height: minTap,
              child: Icon(icon, size: iconSize, color: effectiveColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    super.key,
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
    final progress = (position.inMilliseconds / 1000.0 / total).clamp(0.0, 1.0);
    final playLabel = playing
        ? l10n.overtimeVoicePause
        : l10n.overtimeVoicePlay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (justFinished && !readOnly) ...[
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: semantic.success,
              ),
              const SizedBox(width: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.md),
        ],
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.outlineVariant.withValues(
              alpha: 0.5,
            ),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
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
        Text(
          '${formatMs(position)} / ${format(totalSeconds)}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            if (!readOnly)
              _ControlButton(
                icon: Icons.delete_outline_rounded,
                label: l10n.overtimeVoiceDelete,
                onPressed: locked || busy ? null : onDelete,
                minTap: minTap,
                iconSize: iconSize,
                color: theme.colorScheme.error,
              ),
            if (!readOnly)
              _ControlButton(
                icon: Icons.mic_none_rounded,
                label: l10n.overtimeVoiceRerecord,
                onPressed: locked || busy ? null : onRerecord,
                minTap: minTap,
                iconSize: iconSize,
                filled: true,
              ),
            Semantics(
              button: true,
              label: playLabel,
              child: Tooltip(
                message: playLabel,
                child: Material(
                  color: theme.colorScheme.primaryContainer,
                  shape: const CircleBorder(),
                  elevation: 0,
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
                              size: iconSize,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
