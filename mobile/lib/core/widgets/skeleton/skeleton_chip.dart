import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/widgets/skeleton/skeleton_box.dart';

/// Compact chip-shaped bone (period filters, status chips).
class SkeletonChip extends StatelessWidget {
  const SkeletonChip({
    super.key,
    this.width = 72,
    this.height = 32,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(AppRadius.full),
    );
  }
}
