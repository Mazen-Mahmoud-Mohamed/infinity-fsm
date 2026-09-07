import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/skeleton/skeleton_box.dart';

/// Circular bone (icons / avatars).
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({
    super.key,
    this.size = 34,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}
