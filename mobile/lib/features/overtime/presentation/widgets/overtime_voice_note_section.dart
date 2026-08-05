import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_voice_draft.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

export 'package:mobile/features/overtime/presentation/cubit/overtime_voice_draft.dart';

/// Max voice note length for overtime journey stages.
const int kOvertimeVoiceMaxSeconds = 120;

/// Compact voice note controls for a single overtime journey stage.
///
/// [readOnly] — play only (admin / after successful upload).
/// Editable mode supports record, play, pause, delete, and re-record.
class OvertimeVoiceNoteSection extends StatefulWidget {
  const OvertimeVoiceNoteSection({
    super.key,
    this.remoteUrl,
    this.localBytes,
    this.durationSeconds,
    this.readOnly = false,
    this.enabled = true,
    this.onDraftChanged,
  });

  /// Cloudinary / remote HTTPS URL.
  final String? remoteUrl;

  /// Offline pending bytes (or current draft bytes for playback).
  final List<int>? localBytes;

  final double? durationSeconds;
  final bool readOnly;
  final bool enabled;

  /// Fired when the technician records, deletes, or re-records.
  final ValueChanged<OvertimeVoiceDraft?>? onDraftChanged;

  @override
  State<OvertimeVoiceNoteSection> createState() =>
      _OvertimeVoiceNoteSectionState();
}

class _OvertimeVoiceNoteSectionState extends State<OvertimeVoiceNoteSection> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _recording = false;
  bool _playing = false;
  bool _busy = false;
  double _elapsedSeconds = 0;
  Timer? _tick;
  String? _localPath;
  List<int>? _bytes;
  double? _durationSeconds;

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

  double? get _displayDuration =>
      _durationSeconds ?? widget.durationSeconds;

  @override
  void initState() {
    super.initState();
    _bytes = widget.localBytes;
    _durationSeconds = widget.durationSeconds;
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing;
      if (playing != _playing) {
        setState(() => _playing = playing);
      }
      if (state.processingState == ProcessingState.completed) {
        setState(() => _playing = false);
      }
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
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    if (widget.readOnly || !widget.enabled || _busy || _recording) return;
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
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );

    setState(() {
      _recording = true;
      _elapsedSeconds = 0;
      _localPath = path;
      _bytes = null;
      _durationSeconds = null;
    });

    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || !_recording) {
        timer.cancel();
        return;
      }
      final next = _elapsedSeconds + 1;
      setState(() => _elapsedSeconds = next);
      if (next >= kOvertimeVoiceMaxSeconds) {
        await _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    _tick?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;

    setState(() {
      _recording = false;
      _busy = true;
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
      final duration = _elapsedSeconds.clamp(0, kOvertimeVoiceMaxSeconds).toDouble();
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
      });
      widget.onDraftChanged?.call(draft);
    } on Object {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteRecording() async {
    if (widget.readOnly || !widget.enabled) return;
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
    });
    widget.onDraftChanged?.call(null);
  }

  Future<void> _togglePlay() async {
    if (_busy || _recording) return;
    if (_playing) {
      await _player.pause();
      return;
    }

    setState(() => _busy = true);
    try {
      final remote = widget.remoteUrl;
      if (remote != null &&
          remote.isNotEmpty &&
          (remote.startsWith('http://') || remote.startsWith('https://'))) {
        await _player.setUrl(remote);
      } else if (_localPath != null && await File(_localPath!).exists()) {
        await _player.setFilePath(_localPath!);
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
        await _player.setFilePath(path);
      }
      await _player.play();
    } on Object {
      // Ignore playback errors; UI stays idle.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatDuration(double? seconds) {
    final total = (seconds ?? 0).round().clamp(0, 3600);
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.overtimeVoiceNote,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_recording) ...[
              FilledButton.tonalIcon(
                onPressed: widget.enabled ? _stopRecording : null,
                icon: const Icon(Icons.stop),
                label: Text(
                  '${l10n.overtimeVoiceStop} ${_formatDuration(_elapsedSeconds)}',
                ),
              ),
            ] else if (!_hasAudio && !widget.readOnly) ...[
              OutlinedButton.icon(
                onPressed: widget.enabled && !_busy ? _startRecording : null,
                icon: const Icon(Icons.mic),
                label: Text(l10n.overtimeVoiceRecord),
              ),
            ] else if (_hasAudio) ...[
              IconButton.filledTonal(
                tooltip: _playing ? l10n.overtimeVoicePause : l10n.overtimeVoicePlay,
                onPressed: widget.enabled && !_busy ? _togglePlay : null,
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
              Text(
                _formatDuration(
                  _recording ? _elapsedSeconds : _displayDuration,
                ),
                style: theme.textTheme.bodySmall,
              ),
              if (!widget.readOnly) ...[
                IconButton(
                  tooltip: l10n.overtimeVoiceDelete,
                  onPressed: widget.enabled && !_busy ? _deleteRecording : null,
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                ),
                IconButton(
                  tooltip: l10n.overtimeVoiceRerecord,
                  onPressed: widget.enabled && !_busy
                      ? () async {
                          await _deleteRecording();
                          await _startRecording();
                        }
                      : null,
                  icon: const Icon(Icons.mic_none),
                ),
              ],
            ],
            if (_busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.overtimeVoiceMaxDurationHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
