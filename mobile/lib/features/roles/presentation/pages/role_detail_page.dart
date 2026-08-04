import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/localization/localize_rbac.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/roles/presentation/cubit/roles_cubits.dart';
import 'package:mobile/features/roles/presentation/widgets/assign_users_dialog.dart';
import 'package:mobile/features/roles/presentation/widgets/role_permission_tiles.dart';
import 'package:mobile/features/roles/presentation/widgets/role_status_chip.dart';

class RoleDetailPage extends StatefulWidget {
  const RoleDetailPage({super.key, required this.roleId});

  final String roleId;

  @override
  State<RoleDetailPage> createState() => _RoleDetailPageState();
}

class _RoleDetailPageState extends State<RoleDetailPage> {
  late final RoleDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<RoleDetailCubit>()..load(widget.roleId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _confirmDelete(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rolesDelete),
        content: Text(l10n.rolesDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.rolesCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.rolesDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await _cubit.delete();
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.rolesDeleted)),
        );
        context.pop(true);
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  Future<void> _clone(AppLocalizations l10n) async {
    final result = await _cubit.clone();
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.rolesCloned)),
        );
        context.push(RoutePaths.roleDetail(data.id));
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canUpdate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canUpdateRoles() == true,
    );
    final canDelete = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canDeleteRoles() == true,
    );
    final canCreate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canCreateRoles() == true,
    );
    final isAdmin = context.select(
      (AuthCubit c) => c.state.user?.roles.contains('ADMIN') == true,
    );

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<RoleDetailCubit, RoleDetailState>(
        buildWhen: (p, c) =>
            p.status != c.status ||
            p.role != c.role ||
            p.users != c.users ||
            p.message != c.message ||
            p.isRefreshing != c.isRefreshing,
        builder: (context, state) {
          final role = state.role;
          final mutating = state.status == RoleDetailStatus.mutating;

          return Scaffold(
            appBar: AppBar(
              title: Text(role?.name ?? l10n.rolesDetails),
              actions: [
                if (role != null && canUpdate && (!role.isSystem || isAdmin))
                  IconButton(
                    tooltip: l10n.rolesEdit,
                    onPressed: mutating
                        ? null
                        : () async {
                            final changed = await context.push<bool>(
                              RoutePaths.rolesFormEdit(role.id),
                            );
                            if (changed == true && mounted) {
                              await _cubit.load(widget.roleId);
                            }
                          },
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            body: Builder(
              builder: (context) {
                if ((state.status == RoleDetailStatus.loading ||
                        state.status == RoleDetailStatus.initial) &&
                    role == null) {
                  return AppLoader(message: l10n.rolesLoading);
                }
                if (state.status == RoleDetailStatus.failure && role == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.message != null
                                ? localizeAppMessage(l10n, state.message)
                                : l10n.rolesLoadFailed,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            onPressed: () => _cubit.load(widget.roleId),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (role == null) {
                  return Center(child: Text(l10n.rolesEmpty));
                }

                return Column(
                  children: [
                    AppRefreshBar(visible: state.isRefreshing),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _cubit.load(widget.roleId),
                        child: ListView(
                          padding: AppScrollPadding.resolve(
                            context,
                            base: const EdgeInsets.all(AppSpacing.md),
                            chrome: AppBottomChrome.system,
                          ),
                          children: [
                      if (mutating) const LinearProgressIndicator(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              localizeRoleLabel(l10n, role.name),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          RoleStatusChip(isActive: role.isActive),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        localizeRoleLabel(l10n, role.slug),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (role.description != null &&
                          role.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(role.description!, style: theme.textTheme.bodyLarge),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          if (role.isSystem)
                            Chip(label: Text(l10n.rolesSystemBadge)),
                          Chip(
                            label: Text(
                              l10n.rolesAssignedUsers(role.assignedUsersCount),
                            ),
                          ),
                          Chip(
                            label: Text(
                              l10n.rolesPermissionCount(role.permissions.length),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.rolesPermissions,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (role.permissions.isEmpty)
                        Text(l10n.rolesNoPermissions)
                      else
                        ..._groupPermissionKeys(role.permissions).entries.map(
                          (entry) {
                            return RolePermissionGroupCard(
                              module: entry.key,
                              count: entry.value.length,
                              initiallyExpanded: true,
                              children: [
                                for (final key in entry.value)
                                  RolePermissionTile(
                                    permissionKey: key,
                                    showCheckbox: false,
                                  ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.rolesAssignedUsersTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (state.users.isEmpty)
                        Text(l10n.rolesNoAssignedUsers)
                      else
                        ...state.users.map(
                          (u) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(
                                u.fullName.isNotEmpty
                                    ? u.fullName[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(u.fullName),
                            subtitle: Text(u.email ?? u.username ?? ''),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          if (canUpdate)
                            FilledButton.tonalIcon(
                              onPressed: mutating
                                  ? null
                                  : () async {
                                      final assigned =
                                          await showAssignUsersDialog(
                                        context,
                                        roleId: role.id,
                                      );
                                      if (assigned == true && mounted) {
                                        await _cubit.load(widget.roleId);
                                      }
                                    },
                              icon: const Icon(Icons.person_add_alt_1),
                              label: Text(l10n.rolesAssignUsers),
                            ),
                          if (canUpdate && (!role.isSystem || isAdmin))
                            OutlinedButton.icon(
                              onPressed: mutating
                                  ? null
                                  : () async {
                                      final result = await _cubit.toggleActive();
                                      if (!mounted) return;
                                      switch (result) {
                                        case Failure(:final message):
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(content: Text(localizeAppMessage(l10n, message))),
                                          );
                                        case Success():
                                          break;
                                      }
                                    },
                              icon: Icon(
                                role.isActive
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline,
                              ),
                              label: Text(
                                role.isActive
                                    ? l10n.rolesDeactivate
                                    : l10n.rolesActivate,
                              ),
                            ),
                          if (canCreate)
                            OutlinedButton.icon(
                              onPressed:
                                  mutating ? null : () => _clone(l10n),
                              icon: const Icon(Icons.copy_all_outlined),
                              label: Text(l10n.rolesClone),
                            ),
                          if (canDelete && !role.isSystem)
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                              ),
                              onPressed: mutating
                                  ? null
                                  : () => _confirmDelete(l10n),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(l10n.rolesDelete),
                            ),
                        ],
                      ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Groups permission keys by module prefix for presentation only.
  Map<String, List<String>> _groupPermissionKeys(List<String> keys) {
    final modules = <String, List<String>>{};
    for (final key in keys) {
      final module = key.contains(':') ? key.split(':').first : 'general';
      modules.putIfAbsent(module, () => []).add(key);
    }
    return modules;
  }
}
