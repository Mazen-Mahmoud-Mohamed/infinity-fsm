import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_media_estimates.dart';
import 'package:mobile/features/overtime/domain/services/overtime_photo_compressor.dart';
import 'package:mobile/features/overtime/domain/services/overtime_voice_record_config.dart';
import 'package:mobile/features/settings/presentation/widgets/overtime_settings_helpers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Administrator-only preview lab (no persistence, no uploads).
class OvertimeSettingsConfigLab extends StatefulWidget {
  const OvertimeSettingsConfigLab({
    super.key,
    required this.durationMinutes,
    required this.quality,
    required this.maxPhotoSize,
  });

  final int durationMinutes;
  final String quality;
  final Object maxPhotoSize;

  @override
  State<OvertimeSettingsConfigLab> createState() =>
      _OvertimeSettingsConfigLabState();
}

class _OvertimeSettingsConfigLabState extends State<OvertimeSettingsConfigLab> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _recording = false;
  bool _playing = false;
  bool _busy = false;
  int _elapsed = 0;
  Timer? _tick;
  String? _voicePath;
  int? _voiceBytes;
  int? _voiceDurationSec;

  List<int>? _originalPhoto;
  List<int>? _compressedPhoto;
  img.Image? _decodedOriginal;
  bool _photoBusy = false;
  _PhotoViewMode _photoView = _PhotoViewMode.split;

  @override
  void dispose() {
    _tick?.cancel();
    _player.dispose();
    _recorder.dispose();
    _deleteVoiceFile();
    super.dispose();
  }

  Future<void> _deleteVoiceFile() async {
    final path = _voicePath;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } on Object {
        // Best-effort temp cleanup.
      }
    }
  }

  int get _maxSeconds =>
      OvertimeMediaConfig.secondsFromMinutes(widget.durationMinutes);

  RecordConfig get _recordConfig =>
      OvertimeVoiceRecordConfig.resolve(widget.quality);

  Future<void> _startVoiceTest() async {
    if (_busy || _recording) return;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;

    await _deleteVoiceFile();
    await _player.stop();
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/overtime_settings_voice_test_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(_recordConfig, path: path);
    setState(() {
      _recording = true;
      _elapsed = 0;
      _voicePath = path;
      _voiceBytes = null;
      _voiceDurationSec = null;
      _playing = false;
    });

    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_recording || !mounted) {
        timer.cancel();
        return;
      }
      final next = _elapsed + 1;
      setState(() => _elapsed = next);
      if (next >= _maxSeconds) {
        await _stopVoiceTest();
      }
    });
  }

  Future<void> _stopVoiceTest() async {
    if (!_recording) return;
    _tick?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;
    final filePath = path ?? _voicePath;
    var bytes = 0;
    if (filePath != null && await File(filePath).exists()) {
      bytes = await File(filePath).readAsBytes().then((b) => b.length);
    }
    setState(() {
      _recording = false;
      _voicePath = filePath;
      _voiceBytes = bytes;
      _voiceDurationSec = _elapsed.clamp(0, _maxSeconds);
    });
  }

  Future<void> _playVoiceTest() async {
    final path = _voicePath;
    if (path == null || _playing) return;
    setState(() => _busy = true);
    try {
      await _player.setFilePath(path);
      await _player.play();
      setState(() => _playing = true);
      await _player.playerStateStream.firstWhere((s) => !s.playing);
      if (mounted) setState(() => _playing = false);
    } on Object {
      if (mounted) setState(() => _playing = false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteVoiceTest() async {
    await _player.stop();
    await _deleteVoiceFile();
    if (!mounted) return;
    setState(() {
      _voicePath = null;
      _voiceBytes = null;
      _voiceDurationSec = null;
      _elapsed = 0;
      _playing = false;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 95,
      );
      if (picked == null) return;
      final original = await picked.readAsBytes();
      final compressed = await OvertimePhotoCompressor.compressToPolicy(
        original,
        maxPhotoSize: widget.maxPhotoSize,
      );
      final decoded = img.decodeImage(original);
      if (!mounted) return;
      setState(() {
        _originalPhoto = original;
        _compressedPhoto = compressed;
        _decodedOriginal = decoded;
      });
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  void _clearPhotoPreview() {
    setState(() {
      _originalPhoto = null;
      _compressedPhoto = null;
      _decodedOriginal = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final estVoiceKb = OvertimeMediaEstimates.estimatedMaxVoiceKb(
      widget.durationMinutes,
      widget.quality,
    );
    final photoMb = OvertimeMediaEstimates.estimatedPhotoMb(widget.maxPhotoSize);
    final totalMb = OvertimeMediaEstimates.estimatedTotalUploadMb(
      durationMinutes: widget.durationMinutes,
      quality: widget.quality,
      maxPhotoSize: widget.maxPhotoSize,
    );
    final config = _recordConfig;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.settingsOvertimeConfigTestingTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.settingsOvertimeConfigTestingSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.settingsOvertimeVoiceTestTitle,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: _recording || _busy ? null : _startVoiceTest,
              icon: const Icon(Icons.mic_rounded),
              label: Text(l10n.settingsOvertimeVoiceTestRecord),
            ),
            if (_recording)
              FilledButton.tonalIcon(
                onPressed: _stopVoiceTest,
                icon: const Icon(Icons.stop_rounded),
                label: Text(l10n.overtimeVoiceStop),
              ),
            if (_voicePath != null) ...[
              OutlinedButton.icon(
                onPressed: _busy ? null : _playVoiceTest,
                icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(l10n.settingsOvertimeVoiceTestPlay),
              ),
              OutlinedButton.icon(
                onPressed: _deleteVoiceTest,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.settingsOvertimeVoiceTestDelete),
              ),
              OutlinedButton.icon(
                onPressed: _recording ? null : _startVoiceTest,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.settingsOvertimeVoiceTestRecordAgain),
              ),
            ],
          ],
        ),
        if (_recording || _voicePath != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.settingsOvertimeVoiceTestTimer(
              _formatMmSs(_elapsed),
              _formatMmSs(_maxSeconds),
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (_voiceBytes != null) ...[
          const SizedBox(height: AppSpacing.md),
          _MetricTile(
            label: l10n.settingsOvertimeVoiceTestDuration,
            value: l10n.settingsOvertimeVoiceDurationMinutes(
              ((_voiceDurationSec ?? 0) / 60).ceil().clamp(1, widget.durationMinutes),
            ),
          ),
          _MetricTile(
            label: l10n.settingsOvertimeVoiceTestEstimatedSize,
            value: formatEstimatedSize(l10n, estVoiceKb),
          ),
          _MetricTile(
            label: l10n.settingsOvertimeVoiceTestActualSize,
            value: formatBytes(l10n, _voiceBytes!),
          ),
          _MetricTile(
            label: l10n.settingsOvertimeVoiceQualityTitle,
            value: voiceQualityLabel(l10n, widget.quality),
          ),
          _MetricTile(
            label: l10n.settingsOvertimeVoiceTestEncoding,
            value: 'AAC-LC',
          ),
          _MetricTile(
            label: l10n.settingsOvertimeVoiceTestBitrate,
            value: l10n.settingsOvertimeVoiceTestBitrateKbps(config.bitRate ~/ 1000),
          ),
          _MetricTile(
            label: l10n.settingsOvertimeVoiceTestSampleRate,
            value: l10n.settingsOvertimeVoiceTestSampleRateKhz(
              config.sampleRate ~/ 1000,
            ),
          ),
        ],
        const Divider(height: AppSpacing.xl),
        Text(
          l10n.settingsOvertimePhotoTestTitle,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: _photoBusy
                  ? null
                  : () => _pickPhoto(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l10n.settingsOvertimePhotoTestCamera),
            ),
            OutlinedButton.icon(
              onPressed: _photoBusy
                  ? null
                  : () => _pickPhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.settingsOvertimePhotoTestGallery),
            ),
          ],
        ),
        if (_photoBusy) ...[
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (_originalPhoto != null && _compressedPhoto != null) ...[
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<_PhotoViewMode>(
            segments: [
              ButtonSegment(
                value: _PhotoViewMode.original,
                label: Text(l10n.settingsOvertimePhotoTestOriginal),
              ),
              ButtonSegment(
                value: _PhotoViewMode.compressed,
                label: Text(l10n.settingsOvertimePhotoTestCompressed),
              ),
              ButtonSegment(
                value: _PhotoViewMode.split,
                label: Text(l10n.settingsOvertimePhotoTestSplit),
              ),
            ],
            selected: {_photoView},
            onSelectionChanged: (s) => setState(() => _photoView = s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPhotoComparison(context, l10n),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              OutlinedButton(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                child: Text(l10n.settingsOvertimePhotoTestChooseAnother),
              ),
              OutlinedButton(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                child: Text(l10n.settingsOvertimePhotoTestRetest),
              ),
              TextButton(
                onPressed: _clearPhotoPreview,
                child: Text(l10n.settingsOvertimePhotoTestDeletePreview),
              ),
            ],
          ),
        ],
        const Divider(height: AppSpacing.xl),
        Text(
          l10n.settingsOvertimePerformanceInfoTitle,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MetricTile(
          label: l10n.settingsOvertimePerformanceVoiceMaxDuration,
          value: l10n.settingsOvertimeVoiceDurationMinutes(widget.durationMinutes),
        ),
        _MetricTile(
          label: l10n.settingsOvertimePerformanceVoiceMaxSize,
          value: formatEstimatedSize(l10n, estVoiceKb),
        ),
        _MetricTile(
          label: l10n.settingsOvertimePerformancePhotoMaxSize,
          value: l10n.settingsOvertimePerformancePhotoAverageMb(photoMb),
        ),
        _MetricTile(
          label: l10n.settingsOvertimePerformanceTotalUpload,
          value: l10n.settingsOvertimeEstimateTotalMb(totalMb.toStringAsFixed(0)),
        ),
      ],
    );
  }

  Widget _buildPhotoComparison(BuildContext context, AppLocalizations l10n) {
    final original = _originalPhoto!;
    final compressed = _compressedPhoto!;
    final decoded = _decodedOriginal;
    final ratio = original.isEmpty
        ? 0
        : ((1 - (compressed.length / original.length)) * 100).round();

    Widget panel({
      required String title,
      required List<int> bytes,
      int? width,
      int? height,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: InteractiveViewer(
                    child: Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.settingsOvertimePhotoTestResolution(
              width ?? decoded?.width ?? 0,
              height ?? decoded?.height ?? 0,
            )),
            Text(formatBytes(l10n, bytes.length)),
            if (width != null && height != null)
              Text('${width}x$height'),
          ],
        ),
      );
    }

    final compDecoded = img.decodeImage(Uint8List.fromList(compressed));

    switch (_photoView) {
      case _PhotoViewMode.original:
        return panel(
          title: l10n.settingsOvertimePhotoTestOriginal,
          bytes: original,
          width: decoded?.width,
          height: decoded?.height,
        );
      case _PhotoViewMode.compressed:
        return panel(
          title: l10n.settingsOvertimePhotoTestCompressed,
          bytes: compressed,
          width: compDecoded?.width,
          height: compDecoded?.height,
        );
      case _PhotoViewMode.split:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                panel(
                  title: l10n.settingsOvertimePhotoTestOriginal,
                  bytes: original,
                  width: decoded?.width,
                  height: decoded?.height,
                ),
                const SizedBox(width: AppSpacing.md),
                panel(
                  title: l10n.settingsOvertimePhotoTestCompressed,
                  bytes: compressed,
                  width: compDecoded?.width,
                  height: compDecoded?.height,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.settingsOvertimePhotoTestCompressionRatio(ratio)),
            Text(l10n.settingsOvertimePhotoTestEstimatedUpload(
              formatBytes(l10n, compressed.length),
            )),
          ],
        );
    }
  }

  String _formatMmSs(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

enum _PhotoViewMode { original, compressed, split }

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
