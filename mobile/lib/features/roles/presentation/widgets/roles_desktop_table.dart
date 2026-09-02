import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_data_table.dart';
import 'package:mobile/features/roles/domain/entities/role_entities.dart';
import 'package:mobile/features/roles/presentation/widgets/role_status_chip.dart';

/// Desktop table for the roles management list.
class RolesDesktopTable extends StatelessWidget {
  const RolesDesktopTable({
    super.key,
    required this.roles,
    required this.scrollController,
    this.loadingMore = false,
  });

  final List<RoleEntity> roles;
  final ScrollController scrollController;
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: AppDesktopDataTable(
        controller: scrollController,
        loadingMore: loadingMore,
        columns: [
          DataColumn(label: Text(l10n.rolesList)),
          DataColumn(label: Text(l10n.labelType)),
          DataColumn(label: Text(l10n.reportsCenterStatusFilter)),
          DataColumn(label: Text(l10n.usersTotal)),
        ],
        rows: [
          for (final role in roles)
            DataRow(
              onSelectChanged: (_) =>
                  context.push(RoutePaths.roleDetail(role.id)),
              cells: [
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _parseColor(role.color, theme),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              role.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (role.description != null &&
                                role.description!.isNotEmpty)
                              Text(
                                role.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    role.isSystem ? l10n.rolesSystem : l10n.rolesCustom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(RoleStatusChip(isActive: role.isActive)),
                DataCell(Text('${role.assignedUsersCount}')),
              ],
            ),
        ],
      ),
    );
  }

  Color _parseColor(String? hex, ThemeData theme) {
    if (hex == null || hex.isEmpty) return theme.colorScheme.primary;
    var value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? theme.colorScheme.primary : Color(parsed);
  }
}
