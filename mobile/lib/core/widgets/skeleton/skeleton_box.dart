import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/widgets/skeleton/skeleton_scope.dart';

/// Rounded rectangular bone. Listens to the nearest [SkeletonScope] animation.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final scope = SkeletonAnimation.maybeOf(context);
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.sm);

    Widget bone(Color color) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
        ),
        child: SizedBox(width: width, height: height),
      );
    }

    if (scope?.animation == null) {
      final color = scope?.baseColor ??
          Color.alphaBlend(
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
            Theme.of(context).colorScheme.surfaceContainerHighest,
          );
      return bone(color);
    }

    return AnimatedBuilder(
      animation: scope!.animation!,
      builder: (context, _) {
        final color = Color.lerp(
          scope.baseColor,
          scope.highlightColor,
          scope.animation!.value,
        )!;
        return bone(color);
      },
    );
  }
}
