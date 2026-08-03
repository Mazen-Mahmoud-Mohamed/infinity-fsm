import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';

/// Max content width for settings detail pages on desktop.
const double kSettingsContentMax = 1120;

/// Shared control height for Settings actions (desktop + mobile).
const double kSettingsControlHeight = 44;

/// Centers and width-caps settings page content for phone / tablet / desktop.
class SettingsPageBody extends StatelessWidget {
  const SettingsPageBody({
    super.key,
    required this.children,
    this.maxWidth = kSettingsContentMax,
    this.padding,
    this.embedded = false,
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsets? padding;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);
    final hPad = embedded
        ? (isDesktop ? AppSpacing.lg : AppSpacing.md)
        : (isDesktop ? AppSpacing.lg : AppBreakpoints.pagePadding(width));
    final vPad = isDesktop ? AppSpacing.lg : AppSpacing.md;

    final list = Scrollbar(
      thumbVisibility: isDesktop,
      child: ListView(
        padding: AppScrollPadding.resolve(
          context,
          base: padding ??
              EdgeInsets.fromLTRB(hPad, vPad, hPad, AppSpacing.xl),
          chrome: AppBottomChrome.system,
        ),
        children: children,
      ),
    );

    // Embedded panels already sit inside a framed hub — avoid double gutters.
    if (embedded) return list;

    return AppPageFrame(
      maxWidth: maxWidth,
      child: list,
    );
  }
}

/// Two-column grid that collapses to one column on phones.
class SettingsResponsiveRow extends StatelessWidget {
  const SettingsResponsiveRow({
    super.key,
    required this.left,
    required this.right,
    this.spacing = AppSpacing.lg,
    this.breakpoint = AppBreakpoints.tabletMax,
  });

  final Widget left;
  final Widget right;
  final double spacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            SizedBox(width: spacing),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = AppBreakpoints.isDesktopOf(context);

    return Card(
      margin: margin ?? EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: isDesktop ? 0 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: isDesktop
            ? const EdgeInsets.all(AppSpacing.lg)
            : padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    IconTheme(
                      data: IconThemeData(
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                      child: leading!,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? AppSpacing.lg : AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class SettingsInfoRow extends StatelessWidget {
  const SettingsInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.selectable = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final labelWidth = width >= AppBreakpoints.tabletMax
        ? 168.0
        : (width >= AppBreakpoints.phoneMax ? 140.0 : 118.0);
    final valueStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
      height: 1.35,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                icon,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: selectable
                ? SelectableText(value, style: valueStyle)
                : Text(value, style: valueStyle),
          ),
        ],
      ),
    );
  }
}

/// Uniform-height action row for Settings buttons.
class SettingsActionBar extends StatelessWidget {
  const SettingsActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final child in children)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kSettingsControlHeight),
            child: child,
          ),
      ],
    );
  }
}
