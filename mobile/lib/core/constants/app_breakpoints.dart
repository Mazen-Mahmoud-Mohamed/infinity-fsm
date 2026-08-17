import 'package:flutter/widgets.dart';

/// Shared layout breakpoints for Infinity FSM responsive UI.
///
/// Phone: 0–600 · Tablet: 600–900 · Desktop: 900+
class AppBreakpoints {
  AppBreakpoints._();

  static const double phoneMax = 600;
  static const double tabletMax = 900;

  /// Dashboard stacked layout (single-column charts, mobile table cards).
  static const double dashboardCompactMax = 768;

  /// Readable content width for list / form pages.
  static const double contentMax = 840;

  /// Wider dashboard / settings shell.
  static const double contentWideMax = 1520;

  /// Centered auth card max width.
  static const double authCardMax = 440;

  /// Desktop login panel max width.
  static const double authShellMax = 960;

  static bool isPhone(double width) => width < phoneMax;

  static bool isTablet(double width) =>
      width >= phoneMax && width < tabletMax;

  static bool isDesktop(double width) => width >= tabletMax;

  static bool isDashboardCompact(double width) => width <= dashboardCompactMax;

  static bool isDashboardCompactOf(BuildContext context) =>
      isDashboardCompact(MediaQuery.sizeOf(context).width);

  static bool isPhoneOf(BuildContext context) =>
      isPhone(MediaQuery.sizeOf(context).width);

  static bool isTabletOf(BuildContext context) =>
      isTablet(MediaQuery.sizeOf(context).width);

  static bool isDesktopOf(BuildContext context) =>
      isDesktop(MediaQuery.sizeOf(context).width);

  /// Columns for card grids (1 / 2 / 3).
  static int gridColumns(double width, {int desktop = 3, int tablet = 2}) {
    if (width >= tabletMax) return desktop;
    if (width >= phoneMax) return tablet;
    return 1;
  }

  static double pagePadding(double width) =>
      isPhone(width) ? 16 : 24;

  static double contentMaxWidth(double width, {double desktop = contentMax}) {
    if (width >= tabletMax) return desktop;
    if (width >= phoneMax) return contentMax;
    return double.infinity;
  }
}
