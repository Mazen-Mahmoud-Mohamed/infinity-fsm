import 'package:flutter/material.dart';

/// Shared shimmer pulse for a skeleton subtree.
///
/// Owns a single [AnimationController]. Descendants read the animation via
/// [SkeletonAnimation.of]. When reduced motion / disable-animations is on,
/// no ticker runs and bones render statically.
class SkeletonScope extends StatefulWidget {
  const SkeletonScope({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final Duration duration;

  /// Active controllers across the tree (tests).
  @visibleForTesting
  static int debugActiveControllerCount = 0;

  @visibleForTesting
  static void resetDebugActiveControllerCount() {
    debugActiveControllerCount = 0;
  }

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  bool _animate = true;
  bool _depsReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.maybeOf(context);
    final disable = mq?.disableAnimations ?? false;
    final reduce =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .reduceMotion;
    final shouldAnimate = !disable && !reduce;

    if (_depsReady && shouldAnimate == _animate && _controller != null) {
      return;
    }
    _depsReady = true;
    _animate = shouldAnimate;
    _syncController();
  }

  void _syncController() {
    if (_animate) {
      if (_controller == null) {
        _controller = AnimationController(
          vsync: this,
          duration: widget.duration,
        )..repeat(reverse: true);
        SkeletonScope.debugActiveControllerCount++;
      } else if (!_controller!.isAnimating) {
        _controller!.repeat(reverse: true);
      }
    } else {
      _disposeController();
    }
  }

  void _disposeController() {
    final c = _controller;
    if (c == null) return;
    c.dispose();
    _controller = null;
    if (SkeletonScope.debugActiveControllerCount > 0) {
      SkeletonScope.debugActiveControllerCount--;
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.06),
      scheme.surfaceContainerHighest,
    );
    final highlight = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.10),
      scheme.surfaceContainerHighest,
    );

    return SkeletonAnimation(
      animation: _controller,
      baseColor: base,
      highlightColor: highlight,
      child: widget.child,
    );
  }
}

/// Inherited animation + bone colors for skeleton descendants.
class SkeletonAnimation extends InheritedWidget {
  const SkeletonAnimation({
    super.key,
    required this.animation,
    required this.baseColor,
    required this.highlightColor,
    required super.child,
  });

  /// Null when reduced motion — paint [baseColor] only.
  final Animation<double>? animation;
  final Color baseColor;
  final Color highlightColor;

  static SkeletonAnimation? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SkeletonAnimation>();
  }

  static SkeletonAnimation of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'SkeletonBox requires an ancestor SkeletonScope');
    return scope!;
  }

  @override
  bool updateShouldNotify(SkeletonAnimation oldWidget) {
    return animation != oldWidget.animation ||
        baseColor != oldWidget.baseColor ||
        highlightColor != oldWidget.highlightColor;
  }
}
