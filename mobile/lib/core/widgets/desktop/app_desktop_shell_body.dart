import 'package:flutter/material.dart';

/// Bounds shell branch content below [AppDesktopTopBar].
///
/// Strips inherited top view padding so module pages do not get a duplicate
/// inset below the global shell top bar.
class AppDesktopShellBody extends StatelessWidget {
  const AppDesktopShellBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: SizedBox.expand(child: child),
    );
  }
}
