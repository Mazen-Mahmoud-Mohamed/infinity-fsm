import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
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

class _OvertimeSettingsConfigLabState extends State<OvertimeSettingsConfigLab>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  late final AnimationController _waveController;

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
  img.Image? _decodedCompressed;
  bool _photoBusy = false;
  _PhotoViewMode _photoView = _PhotoViewMode.split;
  double _splitRatio = 0.5;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _waveController.dispose();
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
    _waveController.repeat(reverse: true);

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
    _waveController.stop();
  }

  Future<void> _playVoiceTest() async {
    final path = _voicePath;
    if (path == null || _playing) return;
    setState(() => _busy = true);
    try {
      await _player.setFilePath(path);
      await _player.play();
      setState(() => _playing = true);
      _waveController.repeat(reverse: true);
      await _player.playerStateStream.firstWhere((s) => !s.playing);
      if (mounted) setState(() => _playing = false);
    } on Object {
      if (mounted) setState(() => _playing = false);
    } finally {
      _waveController.stop();
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
    _waveController.stop();
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
      final decodedOriginal = img.decodeImage(original);
      final decodedCompressed = img.decodeImage(Uint8List.fromList(compressed));
      if (!mounted) return;
      setState(() {
        _originalPhoto = original;
        _compressedPhoto = compressed;
        _decodedOriginal = decodedOriginal;
        _decodedCompressed = decodedCompressed;
        _splitRatio = 0.5;
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
      _decodedCompressed = null;
      _splitRatio = 0.5;
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
    final photoMb = OvertimeMediaEstimates.estimatedPhotoMb(
      widget.maxPhotoSize,
    );
    final totalMb = OvertimeMediaEstimates.estimatedTotalUploadMb(
      durationMinutes: widget.durationMinutes,
      quality: widget.quality,
      maxPhotoSize: widget.maxPhotoSize,
    );
    final imageKb = (photoMb * 1024).toInt();
    final voiceKb = estVoiceKb;
    final uploadPerSessionKb = voiceKb + imageKb;
    // Conservative estimate: assume 1 completed session per technician per day.
    final uploadPerTechnicianKb = uploadPerSessionKb;
    final dailyUsageKb = uploadPerTechnicianKb;
    final monthlyUsageKb = dailyUsageKb * 30;
    final estimatedCloudinaryStorageKb = monthlyUsageKb;
    final estimatedBandwidthKb = monthlyUsageKb;
    final estimatedCompressionPercent =
        _originalPhoto != null &&
            _compressedPhoto != null &&
            _originalPhoto!.isNotEmpty
        ? ((1 - (_compressedPhoto!.length / _originalPhoto!.length)) * 100)
              .round()
        : () {
            // Static estimate based on the configured maxPhotoSize vs default "original" cap.
            final originalMb = OvertimeMediaEstimates.estimatedPhotoMb(
              OvertimeMediaConfig.maxPhotoSizeOriginal,
            );
            if (originalMb <= 0) return 0;
            return ((1 - (photoMb / originalMb)) * 100).round().clamp(0, 100);
          }();
    final config = _recordConfig;
    final voiceStateIcon = _recording
        ? Icons.fiber_manual_record_rounded
        : _playing
        ? Icons.equalizer_rounded
        : _voiceBytes != null
        ? Icons.check_circle_rounded
        : Icons.pause_circle_outline_rounded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.settingsOvertimeVoiceTestTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _recording
                ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
                : _playing
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _recording
                  ? theme.colorScheme.error
                  : _playing
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  voiceStateIcon,
                  key: ValueKey<String>(
                    'voice_state_${voiceStateIcon.codePoint}',
                  ),
                  color: _recording
                      ? theme.colorScheme.error
                      : _playing
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.settingsOvertimeVoiceTestTimer(
                    _formatMmSs(_elapsed),
                    _formatMmSs(_maxSeconds),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_recording || _playing)
                _RecordingWaveform(controller: _waveController),
            ],
          ),
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
                icon: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
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
        if (_voiceBytes != null) ...[
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= AppBreakpoints.tabletMax
                  ? 2
                  : 1;
              final durationMin = l10n.settingsOvertimeVoiceDurationMinutes(
                ((_voiceDurationSec ?? 0) / 60).ceil().clamp(
                  1,
                  widget.durationMinutes,
                ),
              );

              final items = [
                _EnterpriseStatCard(
                  label: l10n.settingsOvertimeVoiceTestDuration,
                  value: durationMin,
                  icon: Icons.timer_rounded,
                ),
                _EnterpriseStatCard(
                  label: l10n.settingsOvertimeVoiceTestEstimatedSize,
                  value: formatEstimatedSize(l10n, estVoiceKb),
                  icon: Icons.calculate_rounded,
                ),
                _EnterpriseStatCard(
                  label: l10n.settingsOvertimeVoiceTestActualSize,
                  value: formatBytes(l10n, _voiceBytes!),
                  icon: Icons.file_present_rounded,
                ),
                _EnterpriseStatCard(
                  label: l10n.settingsOvertimeVoiceQualityTitle,
                  value: voiceQualityLabel(l10n, widget.quality),
                  icon: Icons.mic_none_rounded,
                ),
                _EnterpriseStatCard(
                  label: l10n.settingsOvertimeVoiceTestEncoding,
                  value: 'AAC-LC • Mono',
                  icon: Icons.audiotrack_rounded,
                ),
                _EnterpriseStatCard(
                  label: l10n.settingsOvertimeVoiceTestBitrate,
                  value: l10n.settingsOvertimeVoiceTestBitrateKbps(
                    config.bitRate ~/ 1000,
                  ),
                  icon: Icons.speed_rounded,
                ),
                _EnterpriseStatCard(
                  label: l10n.settingsOvertimeVoiceTestSampleRate,
                  value: l10n.settingsOvertimeVoiceTestSampleRateKhz(
                    config.sampleRate ~/ 1000,
                  ),
                  icon: Icons.speed_rounded,
                ),
              ];

              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: columns == 2 ? 1.75 : 2.15,
                children: items,
              );
            },
          ),
        ],
        const Divider(height: AppSpacing.xl),
        Text(
          l10n.settingsOvertimePhotoTestTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= AppBreakpoints.tabletMax
                ? 2
                : 1;
            final items = [
              _EnterpriseStatCard(
                label: l10n.settingsOvertimePerformanceVoiceMaxDuration,
                value: l10n.settingsOvertimeVoiceDurationMinutes(
                  widget.durationMinutes,
                ),
                icon: Icons.timer_rounded,
              ),
              _EnterpriseStatCard(
                label: l10n.settingsOvertimePerformanceVoiceMaxSize,
                value: formatEstimatedSize(l10n, estVoiceKb),
                icon: Icons.mic_none_rounded,
              ),
              _EnterpriseStatCard(
                label: l10n.settingsOvertimePerformancePhotoMaxSize,
                value: l10n.settingsOvertimePerformancePhotoAverageMb(photoMb),
                icon: Icons.photo_size_select_actual_rounded,
              ),
              _EnterpriseStatCard(
                label: l10n.settingsOvertimePerformanceTotalUpload,
                value: l10n.settingsOvertimeEstimateTotalMb(
                  totalMb.toStringAsFixed(0),
                ),
                icon: Icons.cloud_upload_rounded,
              ),
              _EnterpriseStatCard(
                label: l10n.settingsOvertimePerformanceCompression,
                value: '$estimatedCompressionPercent%',
                icon: Icons.compress_rounded,
                progress: estimatedCompressionPercent / 100,
              ),
            ];

            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: columns == 2 ? 2.2 : 2.6,
              children: items,
            );
          },
        ),
        const Divider(height: AppSpacing.xl),
        Text(
          l10n.settingsOvertimeStorageCalculatorTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= AppBreakpoints.tabletMax
                ? 2
                : 1;

            final items = [
              _EnterpriseStatCard(
                label: l10n.settingsOvertimeStorageEstimatedVoiceSize,
                value: formatEstimatedSize(l10n, voiceKb),
                icon: Icons.mic_none_rounded,
                progress: _progressFromKb(voiceKb, capKb: 1024 * 20),
              ),
              _EnterpriseStatCard(
                label: l10n.settingsOvertimeStorageEstimatedImageSize,
                value: formatEstimatedSize(l10n, imageKb),
                icon: Icons.photo_size_select_actual_rounded,
                progress: _progressFromKb(imageKb, capKb: 1024 * 20),
              ),
              _EnterpriseStatCard(
                label: l10n.settingsOvertimeStorageEstimatedUploadPerSession,
                value: formatEstimatedSize(l10n, uploadPerSessionKb),
                icon: Icons.cloud_upload_rounded,
                progress: _progressFromKb(uploadPerSessionKb, capKb: 1024 * 40),
              ),
              _EnterpriseStatCard(
                label: l10n.settingsOvertimeStorageEstimatedUploadPerTechnician,
                value: formatEstimatedSize(l10n, uploadPerTechnicianKb),
                icon: Icons.person_rounded,
                progress: _progressFromKb(
                  uploadPerTechnicianKb,
                  capKb: 1024 * 40,
                ),
              ),
              _EnterpriseStatCard(
                label: l10n.settingsOvertimeStorageEstimatedDailyUsage,
                value: formatEstimatedSize(l10n, dailyUsageKb),
                icon: Icons.calendar_today_rounded,
                progress: _progressFromKb(dailyUsageKb, capKb: 1024 * 80),
              ),
              _EnterpriseStatCard(
                label: l10n.settingsOvertimeStorageEstimatedMonthlyUsage,
                value: formatEstimatedSize(l10n, monthlyUsageKb),
                icon: Icons.calendar_view_month_rounded,
                progress: _progressFromKb(monthlyUsageKb, capKb: 1024 * 1200),
              ),
              _EnterpriseStatCard(
                label: l10n.settingsOvertimeStorageEstimatedCloudinaryStorage,
                value: formatEstimatedSize(l10n, estimatedCloudinaryStorageKb),
                icon: Icons.cloud_circle_rounded,
                progress: _progressFromKb(
                  estimatedCloudinaryStorageKb,
                  capKb: 1024 * 1200,
                ),
              ),
              _EnterpriseStatCard(
                label: l10n.settingsOvertimeStorageEstimatedBandwidth,
                value: formatEstimatedSize(l10n, estimatedBandwidthKb),
                icon: Icons.speed_rounded,
                progress: _progressFromKb(
                  estimatedBandwidthKb,
                  capKb: 1024 * 1200,
                ),
              ),
            ];

            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: columns == 2 ? 2.2 : 2.6,
              children: items,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhotoComparison(BuildContext context, AppLocalizations l10n) {
    final originalBytes = _originalPhoto!;
    final compressedBytes = _compressedPhoto!;

    final decodedOriginal = _decodedOriginal;
    final decodedCompressed = _decodedCompressed;

    final ratio = originalBytes.isEmpty
        ? 0
        : ((1 - (compressedBytes.length / originalBytes.length)) * 100).round();

    int pickWidth(img.Image? decoded) => decoded?.width ?? 0;
    int pickHeight(img.Image? decoded) => decoded?.height ?? 0;

    final originalWidth = pickWidth(decodedOriginal);
    final originalHeight = pickHeight(decodedOriginal);

    Widget memoryPreview(Uint8List bytes) {
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, _) {
          if (frame == null) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return child;
        },
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }

    // Used for split view: original is "before", compressed is "after".
    Widget buildBeforeAfterSlider({required bool allowGesture}) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final clampedRatio = _splitRatio.clamp(0.0, 1.0);
          final splitX = maxW * clampedRatio;

          Widget stackContent() {
            return Stack(
              children: [
                Positioned.fill(
                  child: memoryPreview(Uint8List.fromList(originalBytes)),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: splitX,
                  child: ClipRect(
                    child: memoryPreview(Uint8List.fromList(compressedBytes)),
                  ),
                ),
                // Split handle line.
                Positioned(
                  left: splitX - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            );
          }

          final zoomableChild = InteractiveViewer(
            // Slider drag should remain responsive; pan/drag is disabled.
            panEnabled: false,
            child: stackContent(),
          );

          if (!allowGesture) {
            return zoomableChild;
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (d) {
              final x = d.localPosition.dx.clamp(0.0, maxW);
              final next = x / maxW;
              if ((next - _splitRatio).abs() < 0.01) return;
              setState(() => _splitRatio = next);
            },
            child: zoomableChild,
          );
        },
      );
    }

    Widget photoFrame({required Widget child}) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
        ),
      );
    }

    Future<void> fullscreenPreview() {
      // Keep the fullscreen preview simple: reuse current view mode content.
      final isSplit = _photoView == _PhotoViewMode.split;
      final showBeforeAfter = isSplit;

      return showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            _photoView == _PhotoViewMode.original
                ? l10n.settingsOvertimePhotoTestOriginal
                : _photoView == _PhotoViewMode.compressed
                ? l10n.settingsOvertimePhotoTestCompressed
                : l10n.settingsOvertimePhotoTestSplit,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showBeforeAfter)
                  photoFrame(
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final maxW = constraints.maxWidth;
                        final splitX = maxW * _splitRatio.clamp(0.0, 1.0);
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: InteractiveViewer(
                                child: memoryPreview(
                                  Uint8List.fromList(originalBytes),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: splitX,
                              child: ClipRect(
                                child: InteractiveViewer(
                                  child: memoryPreview(
                                    Uint8List.fromList(compressedBytes),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                else
                  photoFrame(
                    child: InteractiveViewer(
                      child: memoryPreview(
                        Uint8List.fromList(
                          _photoView == _PhotoViewMode.original
                              ? originalBytes
                              : compressedBytes,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget imageSection() {
      final child = switch (_photoView) {
        _PhotoViewMode.original => InteractiveViewer(
          child: memoryPreview(Uint8List.fromList(originalBytes)),
        ),
        _PhotoViewMode.compressed => InteractiveViewer(
          child: memoryPreview(Uint8List.fromList(compressedBytes)),
        ),
        _PhotoViewMode.split => buildBeforeAfterSlider(allowGesture: true),
      };

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          photoFrame(child: child),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.fullscreen_outlined),
              onPressed: fullscreenPreview,
              tooltip: l10n.settingsOvertimePhotoTestSplit,
            ),
          ),
        ],
      );
    }

    final widthToShow = originalWidth > 0
        ? originalWidth
        : decodedCompressed?.width ?? 0;
    final heightToShow = originalHeight > 0
        ? originalHeight
        : decodedCompressed?.height ?? 0;

    final estimatedCloudinaryUsageBytes = compressedBytes.length;
    final estimatedUploadTimeSeconds =
        (estimatedCloudinaryUsageBytes / (2 * 1024 * 1024)).ceil();

    String fmtUploadTime(int seconds) {
      if (seconds < 60) return '~ $seconds s';
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '~ ${m}m ${s.toString().padLeft(2, '0')}s';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        imageSection(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.settingsOvertimePhotoTestResolution(widthToShow, heightToShow),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _MetricTile(
          label: l10n.settingsOvertimePhotoTestOriginalSize,
          value: formatBytes(l10n, originalBytes.length),
        ),
        _MetricTile(
          label: l10n.settingsOvertimePhotoTestCompressedSize,
          value: formatBytes(l10n, compressedBytes.length),
        ),
        _MetricTile(
          label: l10n.settingsOvertimePhotoTestCompressionRatio(ratio),
          value: '',
        ),
        _MetricTile(
          label: l10n.settingsOvertimePhotoTestEstimatedUpload(
            formatBytes(l10n, compressedBytes.length),
          ),
          value: '',
        ),
        _MetricTile(
          label: l10n.settingsOvertimePhotoTestEstimatedCloudinaryUsage,
          value: formatBytes(l10n, estimatedCloudinaryUsageBytes),
        ),
        _MetricTile(
          label: l10n.settingsOvertimePhotoTestEstimatedUploadTime,
          value: fmtUploadTime(estimatedUploadTimeSeconds),
        ),
      ],
    );
  }

  String _formatMmSs(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double _progressFromKb(int kb, {required int capKb}) {
    if (capKb <= 0) return 0;
    return (kb / capKb).clamp(0, 1).toDouble();
  }
}

enum _PhotoViewMode { original, compressed, split }

class _RecordingWaveform extends StatelessWidget {
  const _RecordingWaveform({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 38,
      height: 18,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          double bar(int i) => 4 + (math.sin((t * 2 * math.pi) + i) + 1) * 5;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              4,
              (i) => Container(
                width: 5,
                height: bar(i),
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EnterpriseStatCard extends StatelessWidget {
  const _EnterpriseStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.progress,
  });

  final String label;
  final String value;
  final IconData icon;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cardTheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cardTheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: cardTheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cardTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                value,
                key: ValueKey<String>(value),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 280),
                tween: Tween<double>(begin: 0, end: progress!.clamp(0, 1)),
                builder: (context, p, _) => LinearProgressIndicator(
                  value: p,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
