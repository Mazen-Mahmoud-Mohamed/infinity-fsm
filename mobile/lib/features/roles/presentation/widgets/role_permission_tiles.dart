import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_rbac.dart';

/// Presentation-only permission row for Roles & Permissions screens.
///
/// Localized title + clamped description only (never the group name).
/// Desktop: light hover highlight + tooltip. Keyboard focus also shows tooltip.
class RolePermissionTile extends StatefulWidget {
  const RolePermissionTile({
    super.key,
    required this.permissionKey,
    this.selected,
    this.onChanged,
    this.enabled = true,
    this.showCheckbox = true,
  });

  final String permissionKey;
  final bool? selected;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;
  final bool showCheckbox;

  @override
  State<RolePermissionTile> createState() => _RolePermissionTileState();
}

class _RolePermissionTileState extends State<RolePermissionTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = localizePermissionKey(l10n, widget.permissionKey);
    final description =
        localizePermissionDescription(l10n, widget.permissionKey);
    final highlight = _hovered || _focused;

    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final descriptionStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.35,
    );

    Widget row = Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xs,
        end: AppSpacing.md,
        top: AppSpacing.sm + 2,
        bottom: AppSpacing.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showCheckbox)
            Checkbox(
              value: widget.selected ?? false,
              onChanged: widget.enabled ? widget.onChanged : null,
              visualDensity: VisualDensity.standard,
              materialTapTargetSize: MaterialTapTargetSize.padded,
            )
          else
            const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: titleStyle),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: descriptionStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    row = MouseRegion(
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        color: highlight
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : Colors.transparent,
        child: row,
      ),
    );

    // Focusable wrapper so keyboard focus shows highlight + tooltip.
    row = Focus(
      canRequestFocus: true,
      onFocusChange: (value) {
        if (_focused != value) setState(() => _focused = value);
      },
      child: row,
    );

    if (description.isEmpty) {
      return Semantics(
        label: name,
        checked: widget.showCheckbox ? (widget.selected ?? false) : null,
        child: row,
      );
    }

    return Semantics(
      label: '$name. $description',
      checked: widget.showCheckbox ? (widget.selected ?? false) : null,
      child: Tooltip(
        message: description,
        waitDuration: const Duration(milliseconds: 350),
        showDuration: const Duration(seconds: 4),
        preferBelow: true,
        child: row,
      ),
    );
  }
}

/// Group card with bold title, secondary description, and permission children.
class RolePermissionGroupCard extends StatelessWidget {
  const RolePermissionGroupCard({
    super.key,
    required this.module,
    required this.count,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String module;
  final int count;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final groupName = localizePermissionGroup(l10n, module);
    final groupDescription =
        localizePermissionGroupDescription(l10n, module);

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: isDesktop ? 19 : 16,
      height: 1.25,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.only(
          bottom: AppSpacing.sm,
        ),
        title: Text(
          '$groupName ($count)',
          style: titleStyle,
        ),
        subtitle: groupDescription.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  groupDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.md,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
