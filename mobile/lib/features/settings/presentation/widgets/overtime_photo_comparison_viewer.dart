import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';

enum OvertimePhotoComparisonMode { original, compressed, split }

/// Fullscreen photo comparison viewer with zoom and split-slider support.
class OvertimePhotoComparisonViewer extends StatefulWidget {
  const OvertimePhotoComparisonViewer({
    super.key,
    required this.mode,
    required this.originalBytes,
    required this.compressedBytes,
    this.initialSplitRatio = 0.5,
  });

  final OvertimePhotoComparisonMode mode;
  final Uint8List originalBytes;
  final Uint8List compressedBytes;
  final double initialSplitRatio;

  static Future<void> show(
    BuildContext context, {
    required OvertimePhotoComparisonMode mode,
    required Uint8List originalBytes,
    required Uint8List compressedBytes,
    double initialSplitRatio = 0.5,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        opaque: true,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: OvertimePhotoComparisonViewer(
              mode: mode,
              originalBytes: originalBytes,
              compressedBytes: compressedBytes,
              initialSplitRatio: initialSplitRatio,
            ),
          );
        },
      ),
    );
  }

  @override
  State<OvertimePhotoComparisonViewer> createState() =>
      _OvertimePhotoComparisonViewerState();
}

class _OvertimePhotoComparisonViewerState
    extends State<OvertimePhotoComparisonViewer> {
  late double _splitRatio;
  final TransformationController _transformController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _splitRatio = widget.initialSplitRatio.clamp(0.05, 0.95);
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  String _title(AppLocalizations l10n) {
    return switch (widget.mode) {
      OvertimePhotoComparisonMode.original =>
        l10n.settingsOvertimePhotoTestOriginal,
      OvertimePhotoComparisonMode.compressed =>
        l10n.settingsOvertimePhotoTestCompressed,
      OvertimePhotoComparisonMode.split => l10n.settingsOvertimePhotoTestSplit,
    };
  }

  void _handleDoubleTap() {
    if (_transformController.value.getMaxScaleOnAxis() > 1.01) {
      _transformController.value = Matrix4.identity();
      return;
    }

    final details = _doubleTapDetails;
    if (details == null) return;

    const scale = 2.5;
    final position = details.localPosition;
    _transformController.value = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (scale - 1),
        -position.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  Widget _memoryImage(Uint8List bytes) {
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, _) {
        if (frame == null) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
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
          size: 40,
        ),
      ),
    );
  }

  Widget _splitComparison() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final splitX = maxW * _splitRatio;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            final x = details.localPosition.dx.clamp(0.0, maxW);
            setState(() => _splitRatio = (x / maxW).clamp(0.05, 0.95));
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: _memoryImage(widget.originalBytes)),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: splitX,
                child: ClipRect(child: _memoryImage(widget.compressedBytes)),
              ),
              Positioned(
                left: splitX - 1.5,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Positioned(
                left: splitX - 18,
                top: 0,
                bottom: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _singleImage(Uint8List bytes) {
    return _memoryImage(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bytes = switch (widget.mode) {
      OvertimePhotoComparisonMode.original => widget.originalBytes,
      OvertimePhotoComparisonMode.compressed => widget.compressedBytes,
      OvertimePhotoComparisonMode.split => widget.originalBytes,
    };

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_title(l10n)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector(
                      onDoubleTapDown: (details) => _doubleTapDetails = details,
                      onDoubleTap: _handleDoubleTap,
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 1,
                        maxScale: 5,
                        panEnabled:
                            widget.mode != OvertimePhotoComparisonMode.split,
                        scaleEnabled: true,
                        child: widget.mode == OvertimePhotoComparisonMode.split
                            ? _splitComparison()
                            : _singleImage(bytes),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.mode == OvertimePhotoComparisonMode.split) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.settingsOvertimePhotoTestSplitHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
