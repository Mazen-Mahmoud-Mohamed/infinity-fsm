import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_rbac.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_data_table.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/presentation/widgets/user_status_badge.dart';

/// Desktop table for the users management list.
class UsersDesktopTable extends StatelessWidget {
  const UsersDesktopTable({
    super.key,
    required this.users,
    required this.scrollController,
    this.loadingMore = false,
  });

  final List<ManagedUser> users;
  final ScrollController scrollController;
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activityFormat = AppFormatters.mediumDateTime(context);

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
          DataColumn(label: Text(l10n.usersList)),
          DataColumn(label: Text(l10n.email)),
          DataColumn(label: Text(l10n.roleLabel)),
          DataColumn(label: Text(l10n.reportsCenterStatusFilter)),
          DataColumn(label: Text(l10n.usersLastActive)),
        ],
        rows: [
          for (final user in users)
            DataRow(
              onSelectChanged: (_) async {
                final changed = await context.push<bool>(
                  RoutePaths.userDetail(user.id),
                );
                if (changed == true && context.mounted) {
                  // Parent cubit refresh handled by caller if needed.
                }
              },
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppNetworkAvatar(
                        imageUrl: user.avatarUrl,
                        radius: 16,
                        fallbackLabel: user.fullName,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(
                  Text(
                    user.primaryRole != null
                        ? localizeRoleLabel(l10n, user.primaryRole!)
                        : user.roles.isNotEmpty
                            ? localizeRoleLabel(l10n, user.roles.first)
                            : '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(UserStatusBadge(status: user.status)),
                DataCell(
                  Text(
                    user.lastActiveAt != null
                        ? activityFormat.format(user.lastActiveAt!.toLocal())
                        : '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
