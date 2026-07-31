import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';

class OrganizationHubPage extends StatelessWidget {
  const OrganizationHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      (
        title: l10n.orgCompanies,
        subtitle: l10n.orgCompaniesSubtitle,
        icon: Icons.apartment_outlined,
        path: RoutePaths.organizationCompanies,
      ),
      (
        title: l10n.orgBranches,
        subtitle: l10n.orgBranchesSubtitle,
        icon: Icons.store_mall_directory_outlined,
        path: RoutePaths.organizationBranches,
      ),
      (
        title: l10n.orgDepartments,
        subtitle: l10n.orgDepartmentsSubtitle,
        icon: Icons.account_tree_outlined,
        path: RoutePaths.organizationDepartments,
      ),
      (
        title: l10n.orgTeams,
        subtitle: l10n.orgTeamsSubtitle,
        icon: Icons.groups_outlined,
        path: RoutePaths.organizationTeams,
      ),
      (
        title: l10n.orgPositions,
        subtitle: l10n.orgPositionsSubtitle,
        icon: Icons.badge_outlined,
        path: RoutePaths.organizationPositions,
      ),
      (
        title: l10n.orgUserDirectory,
        subtitle: l10n.orgUserDirectorySubtitle,
        icon: Icons.people_outline,
        path: RoutePaths.organizationUsers,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orgTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              leading: Icon(item.icon, color: colorScheme.primary),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () => context.push(item.path),
            ),
          );
        },
      ),
    );
  }
}
