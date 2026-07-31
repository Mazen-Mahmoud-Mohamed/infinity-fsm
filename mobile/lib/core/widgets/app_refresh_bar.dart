import 'package:flutter/material.dart';

/// Thin top progress bar for background refresh. Does not blank the page.
class AppRefreshBar extends StatelessWidget {
  const AppRefreshBar({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return const LinearProgressIndicator(minHeight: 2);
  }
}
