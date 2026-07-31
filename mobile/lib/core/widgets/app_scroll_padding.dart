import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';

/// Fixed bottom chrome that scrollable content must clear.
///
/// Heights are the **action chrome itself** (button row / FAB), excluding
/// system safe-area — [AppScrollPadding] adds [MediaQuery.viewPadding]
/// separately so SafeArea is never hard-coded per page.
enum AppBottomChrome {
  /// System inset + comfort gap only (default for plain forms / lists).
  system,

  /// Sticky primary actions (Save / Approve / Reject) outside the scroll view.
  stickyActions,

  /// [FloatingActionButton] clearance.
  fab,

  /// Sticky actions while a shell [NavigationBar] is also visible.
  stickyActionsAndNav,
}

extension AppBottomChromeHeight on AppBottomChrome {
  /// Reserved height for the chrome, excluding system safe-area.
  double get reservedHeight => switch (this) {
        AppBottomChrome.system => 0,
        AppBottomChrome.stickyActions => 72,
        AppBottomChrome.fab => 88,
        AppBottomChrome.stickyActionsAndNav => 152,
      };
}

/// Shared bottom-aware padding for every scrollable page.
///
/// Bottom inset =
/// `base.bottom` + `viewPadding.bottom` + chrome reserve + comfort spacing
/// + any keyboard inset not already consumed by [Scaffold] resize.
abstract final class AppScrollPadding {
  static const double comfort = AppSpacing.md;

  static EdgeInsets resolve(
    BuildContext context, {
    EdgeInsets base = const EdgeInsets.all(AppSpacing.md),
    AppBottomChrome chrome = AppBottomChrome.system,
    double extra = comfort,
  }) {
    final data = MediaQuery.of(context);
    final systemBottom = data.viewPadding.bottom;
    // Scaffold usually shrinks the body for the keyboard. If insets remain
    // larger than padding (nested scaffolds / resize disabled), clear them.
    final keyboardClearance =
        (data.viewInsets.bottom - data.padding.bottom).clamp(0.0, double.infinity);

    return EdgeInsets.fromLTRB(
      base.left,
      base.top,
      base.right,
      base.bottom +
          systemBottom +
          chrome.reservedHeight +
          extra +
          keyboardClearance,
    );
  }
}

/// [ListView] that always leaves room for system / sticky / FAB chrome.
class AppBottomSafeListView extends StatelessWidget {
  const AppBottomSafeListView({
    super.key,
    required this.children,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.primary,
    this.basePadding = const EdgeInsets.all(AppSpacing.md),
    this.chrome = AppBottomChrome.system,
    this.extra = AppScrollPadding.comfort,
  });

  final List<Widget> children;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool? primary;
  final EdgeInsets basePadding;
  final AppBottomChrome chrome;
  final double extra;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      primary: primary,
      padding: AppScrollPadding.resolve(
        context,
        base: basePadding,
        chrome: chrome,
        extra: extra,
      ),
      children: children,
    );
  }
}

/// [SingleChildScrollView] with the same bottom-safe padding contract.
class AppBottomSafeScrollView extends StatelessWidget {
  const AppBottomSafeScrollView({
    super.key,
    required this.child,
    this.controller,
    this.physics,
    this.basePadding = const EdgeInsets.all(AppSpacing.md),
    this.chrome = AppBottomChrome.system,
    this.extra = AppScrollPadding.comfort,
  });

  final Widget child;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsets basePadding;
  final AppBottomChrome chrome;
  final double extra;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      physics: physics,
      padding: AppScrollPadding.resolve(
        context,
        base: basePadding,
        chrome: chrome,
        extra: extra,
      ),
      child: child,
    );
  }
}
