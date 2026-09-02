import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_constants.dart';

class AppDesktopSidebarItem {
  const AppDesktopSidebarItem({
    required this.branchIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final int branchIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AppDesktopSidebarSection {
  const AppDesktopSidebarSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<AppDesktopSidebarItem> items;
}

/// Grouped desktop navigation sidebar.
class AppDesktopSidebar extends StatelessWidget {
  const AppDesktopSidebar({
    super.key,
    required this.sections,
    required this.selectedBranch,
    required this.onBranchSelected,
    this.collapsed = false,
  });

  final List<AppDesktopSidebarSection> sections;
  final int selectedBranch;
  final ValueChanged<int> onBranchSelected;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = collapsed
        ? AppDesktopConstants.sidebarCollapsedWidth
        : AppDesktopConstants.sidebarWidth;

    return Material(
      color: scheme.surfaceContainerLow,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(
              end: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: SafeArea(
            right: false,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              children: [
                for (final section in sections) ...[
                  if (!collapsed && section.title.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.sm,
                        AppSpacing.sm,
                        AppSpacing.xs,
                      ),
                      child: Text(
                        section.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                      ),
                    ),
                  ],
                  for (final item in section.items)
                    _SidebarTile(
                      item: item,
                      selected: selectedBranch == item.branchIndex,
                      collapsed: collapsed,
                      onTap: () => onBranchSelected(item.branchIndex),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final AppDesktopSidebarItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final bg = selected
        ? scheme.primaryContainer.withValues(alpha: 0.55)
        : _hovered
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.8)
            : Colors.transparent;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    final tile = Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? AppSpacing.sm : AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Icon(
                  selected ? widget.item.selectedIcon : widget.item.icon,
                  size: 22,
                  color: fg,
                ),
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: fg,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.collapsed) {
      return Tooltip(
        message: widget.item.label,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: tile,
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: tile,
    );
  }
}

/// Builds grouped sidebar sections from shell branch indexes.
List<AppDesktopSidebarSection> buildDesktopSidebarSections({
  required AppLocalizations l10n,
  required bool operational,
  required List<int> railBranches,
}) {
  int? sectionOf(int branch) {
    if (branch == 0 || branch == 1 || branch == 2 || branch == 3 || branch == 4) {
      return 0; // operations / home
    }
    if (branch == 5 || branch == 6 || branch == 7) return 1; // management modules
    if (branch == 8) return 2; // reports
    if (branch == 9 || branch == 10 || branch == 11) return 3; // admin
    return null;
  }

  AppDesktopSidebarItem itemFor(int branch) {
    return switch (branch) {
      0 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: l10n.dashboard,
        ),
      1 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.access_time_outlined,
          selectedIcon: Icons.access_time,
          label: l10n.attendance,
        ),
      2 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: l10n.workOrders,
        ),
      3 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.more_time_outlined,
          selectedIcon: Icons.more_time,
          label: operational ? l10n.overtimeTechnicianTitle : l10n.overtime,
        ),
      4 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: l10n.profile,
        ),
      5 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          label: l10n.inventory,
        ),
      6 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.precision_manufacturing_outlined,
          selectedIcon: Icons.precision_manufacturing,
          label: l10n.assets,
        ),
      7 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.build_circle_outlined,
          selectedIcon: Icons.build_circle,
          label: l10n.assetsStatusMaintenance,
        ),
      8 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics,
          label: l10n.reportsCenter,
        ),
      9 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts,
          label: l10n.usersTitle,
        ),
      10 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          label: l10n.rolesTitle,
        ),
      11 => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: l10n.settings,
        ),
      _ => AppDesktopSidebarItem(
          branchIndex: branch,
          icon: Icons.circle_outlined,
          selectedIcon: Icons.circle,
          label: '',
        ),
    };
  }

  final ops = <AppDesktopSidebarItem>[];
  final mgmt = <AppDesktopSidebarItem>[];
  final reports = <AppDesktopSidebarItem>[];
  final admin = <AppDesktopSidebarItem>[];

  for (final branch in railBranches) {
    final section = sectionOf(branch);
    final item = itemFor(branch);
    switch (section) {
      case 0:
        ops.add(item);
      case 1:
        mgmt.add(item);
      case 2:
        reports.add(item);
      case 3:
        admin.add(item);
      default:
        break;
    }
  }

  final sections = <AppDesktopSidebarSection>[];
  if (ops.isNotEmpty) {
    sections.add(
      AppDesktopSidebarSection(
        title: l10n.dashboardOperations,
        items: ops,
      ),
    );
  }
  if (mgmt.isNotEmpty) {
    sections.add(
      AppDesktopSidebarSection(
        title: l10n.dashboardOverview,
        items: mgmt,
      ),
    );
  }
  if (reports.isNotEmpty) {
    sections.add(
      AppDesktopSidebarSection(
        title: l10n.reportsCenter,
        items: reports,
      ),
    );
  }
  if (admin.isNotEmpty) {
    sections.add(
      AppDesktopSidebarSection(
        title: l10n.settingsSectionAdministration,
        items: admin,
      ),
    );
  }
  return sections;
}
