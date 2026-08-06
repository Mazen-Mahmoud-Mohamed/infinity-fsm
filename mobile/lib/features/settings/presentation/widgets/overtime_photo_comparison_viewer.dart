import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';

enum OvertimePhotoComparisonMode { original, compressed, split }

/// Fullscreen photo comparison viewer with tabs, zoom, and responsive compare modes.
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
    extends State<OvertimePhotoComparisonViewer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  late double _splitRatio;
  final TransformationController _originalTransform =
      TransformationController();
  final TransformationController _compressedTransform =
      TransformationController();
  final TransformationController _splitTransform = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.mode.index;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    _pageController = PageController(initialPage: initialIndex);
    _splitRatio = widget.initialSplitRatio.clamp(0.05, 0.95);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_pageController.hasClients &&
        _pageController.page?.round() != _tabController.index) {
      _pageController.jumpToPage(_tabController.index);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pageController.dispose();
    _originalTransform.dispose();
    _compressedTransform.dispose();
    _splitTransform.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TransformationController controller) {
    if (controller.value.getMaxScaleOnAxis() > 1.01) {
      controller.value = Matrix4.identity();
      return;
    }
    final details = _doubleTapDetails;
    if (details == null) return;
    const scale = 2.5;
    final position = details.localPosition;
    controller.value = Matrix4.identity()
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
      alignment: Alignment.center,
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

  Widget _zoomableImage({
    required Uint8List bytes,
    required TransformationController controller,
  }) {
    return GestureDetector(
      onDoubleTapDown: (details) {
        _doubleTapDetails = details;
      },
      onDoubleTap: () => _handleDoubleTap(controller),
      child: InteractiveViewer(
        transformationController: controller,
        minScale: 1,
        maxScale: 5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: _memoryImage(bytes),
            );
          },
        ),
      ),
    );
  }

  Widget _splitComparison({required bool allowZoom}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final splitX = maxW * _splitRatio;

        Widget stack = Stack(
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
        );

        stack = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            final x = details.localPosition.dx.clamp(0.0, maxW);
            setState(() => _splitRatio = (x / maxW).clamp(0.05, 0.95));
          },
          child: SizedBox(width: maxW, height: maxH, child: stack),
        );

        if (!allowZoom) return stack;

        return GestureDetector(
          onDoubleTapDown: (details) {
            _doubleTapDetails = details;
          },
          onDoubleTap: () => _handleDoubleTap(_splitTransform),
          child: InteractiveViewer(
            transformationController: _splitTransform,
            minScale: 1,
            maxScale: 5,
            panEnabled: false,
            child: stack,
          ),
        );
      },
    );
  }

  Widget _stageFrame({required Widget child}) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isPhone = AppBreakpoints.isPhoneOf(context);
    final useCompactTabs = isPhone;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.settingsOvertimePhotoTestTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(useCompactTabs ? 72 : 52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelPadding: EdgeInsets.symmetric(
                horizontal: useCompactTabs ? 2 : 8,
              ),
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: theme.textTheme.labelLarge,
              tabs: [
                Tab(
                  height: useCompactTabs ? 56 : 46,
                  icon: useCompactTabs
                      ? const Icon(Icons.photo_outlined, size: 18)
                      : null,
                  text: useCompactTabs
                      ? l10n.settingsOvertimePhotoTestOriginalShort
                      : l10n.settingsOvertimePhotoTestOriginal,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                ),
                Tab(
                  height: useCompactTabs ? 56 : 46,
                  icon: useCompactTabs
                      ? const Icon(Icons.compress_rounded, size: 18)
                      : null,
                  text: useCompactTabs
                      ? l10n.settingsOvertimePhotoTestCompressedShort
                      : l10n.settingsOvertimePhotoTestCompressed,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                ),
                Tab(
                  height: useCompactTabs ? 56 : 46,
                  icon: useCompactTabs
                      ? const Icon(Icons.compare_arrows_rounded, size: 18)
                      : null,
                  text: useCompactTabs
                      ? l10n.settingsOvertimePhotoTestCompareShort
                      : l10n.settingsOvertimePhotoTestCompare,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: _stageFrame(
                  child: isPhone
                      ? PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            if (_tabController.index != index) {
                              _tabController.animateTo(index);
                            }
                          },
                          children: [
                            _zoomableImage(
                              bytes: widget.originalBytes,
                              controller: _originalTransform,
                            ),
                            _zoomableImage(
                              bytes: widget.compressedBytes,
                              controller: _compressedTransform,
                            ),
                            _splitComparison(allowZoom: true),
                          ],
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _zoomableImage(
                              bytes: widget.originalBytes,
                              controller: _originalTransform,
                            ),
                            _zoomableImage(
                              bytes: widget.compressedBytes,
                              controller: _compressedTransform,
                            ),
                            _splitComparison(allowZoom: true),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _tabController.index == 2
                    ? (isPhone
                          ? l10n.settingsOvertimePhotoTestFullscreenSwipeHint
                          : l10n.settingsOvertimePhotoTestSplitHint)
                    : (isPhone
                          ? l10n.settingsOvertimePhotoTestFullscreenSwipeHint
                          : l10n.settingsOvertimePhotoTestOpenFullscreen),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
