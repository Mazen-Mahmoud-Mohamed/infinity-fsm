import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_page_header.dart';

/// Standard desktop page scaffold: header, optional toolbar, scrollable body.
class AppDesktopPageLayout extends StatelessWidget {
  const AppDesktopPageLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    @Deprecated('Use actions instead') this.headerTrailing,
    this.toolbar,
    required this.body,
    this.isRefreshing = false,
    this.maxWidth = AppBreakpoints.contentWideMax,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? actions;
  final Widget? headerTrailing;
  final Widget? toolbar;
  final Widget body;
  final bool isRefreshing;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDesktopListPageHeader(
          title: title,
          subtitle: subtitle,
          actions: actions ?? headerTrailing,
          toolbar: toolbar,
          isRefreshing: isRefreshing,
        ),
        Expanded(
          child: AppPageFrame(
            maxWidth: maxWidth,
            padding: padding ?? EdgeInsets.zero,
            child: body,
          ),
        ),
      ],
    );
  }
}

/// Full-width desktop list page: title → actions → toolbar → expanded body.
class AppDesktopListPage extends StatelessWidget {
  const AppDesktopListPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    @Deprecated('Use actions instead') this.trailing,
    this.toolbar,
    required this.body,
    this.isRefreshing = false,
  });

  final String title;
  final String? subtitle;
  final Widget? actions;
  @Deprecated('Use actions instead')
  final Widget? trailing;
  final Widget? toolbar;
  final Widget body;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDesktopListPageHeader(
          title: title,
          subtitle: subtitle,
          actions: actions ?? trailing,
          toolbar: toolbar,
          isRefreshing: isRefreshing,
        ),
        Expanded(child: body),
      ],
    );
  }
}

/// Title + action row + toolbar band directly below the global shell top bar.
class AppDesktopListPageHeader extends StatelessWidget {
  const AppDesktopListPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    @Deprecated('Use actions instead') this.trailing,
    this.toolbar,
    this.isRefreshing = false,
    this.compactSpacing = false,
  });

  final String title;
  final String? subtitle;
  final Widget? actions;
  final Widget? trailing;
  final Widget? toolbar;
  final bool isRefreshing;
  /// Tighter vertical rhythm for list pages (Work Orders, Overtime).
  final bool compactSpacing;

  EdgeInsets get _pageInsets => compactSpacing
      ? const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xs,
        )
      : _defaultPageInsets;

  static const EdgeInsets _defaultPageInsets = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.md,
    AppSpacing.lg,
    AppSpacing.sm,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppRefreshBar(visible: isRefreshing),
        Padding(
          padding: _pageInsets,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDesktopPageHeader(
                title: title,
                subtitle: subtitle,
              ),
              if ((actions ?? trailing) != null) ...[
                SizedBox(
                  height: compactSpacing ? AppSpacing.xs : AppSpacing.sm,
                ),
                (actions ?? trailing)!,
              ],
              if (toolbar != null) ...[
                SizedBox(
                  height: compactSpacing ? AppSpacing.sm : AppSpacing.md,
                ),
                toolbar!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Returns true when module pages should hide the mobile-style [AppBar].
bool hideModuleAppBarOnDesktop(BuildContext context) =>
    AppBreakpoints.isDesktopOf(context);
