import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_rbac.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_list_card.dart';
import 'package:mobile/core/widgets/technician_main_app_bar.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_page_header.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_split_view.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_surface.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/branding/infinity_brand.dart';
import 'package:mobile/core/widgets/offline_banner.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/features/notifications/presentation/widgets/notifications_bell_action.dart';
import 'package:mobile/features/organization/presentation/cubit/profile_cubit.dart';
import 'package:mobile/features/roles/presentation/widgets/role_permission_tiles.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;

    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..load(user),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final pagePad = AppBreakpoints.pagePadding(width);
    final isDesktop = AppBreakpoints.isDesktop(width);

    return Scaffold(
      appBar: isDesktop
          ? null
          : TechnicianMainAppBar(
              title: Text(l10n.profile),
              actions: const [
                NotificationsBellAction(),
              ],
            ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final user = state.user ?? context.watch<AuthCubit>().state.user;
          final org = state.context;

          if (state.status == ProfileStatus.loading && org == null) {
            return AppLoader(message: l10n.profileLoading);
          }

          final roles = user?.roles ?? const <String>[];
          final permissions = user?.permissions ?? const <String>[];
          final groups = _groupPermissions(permissions);

          final accountSection = [
            _ProfileHeaderCard(
              isDesktop: isDesktop,
              imageUrl: user?.profilePhotoUrl,
              name: user?.fullName ?? l10n.profile,
              email: user?.email ?? '-',
              role: localizeRoleLabel(
                l10n,
                user?.primaryRole ?? '',
              ),
              fallbackLabel: user?.fullName ?? user?.email ?? '?',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppListCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileRow(
                    label: l10n.email,
                    value: user?.email ?? '-',
                  ),
                  _ProfileRow(
                    label: l10n.profilePhone,
                    value: user?.phone ?? '-',
                  ),
                  _ProfileRow(
                    label: l10n.roleLabel,
                    value: localizeRoleLabel(
                      l10n,
                      user?.primaryRole ?? '',
                    ),
                  ),
                  _ProfileRow(
                    label: l10n.companyLabel,
                    value: org?.company?.name ?? '-',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.settingsChangePassword),
              onTap: () => context.push(RoutePaths.usersChangePassword),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout),
              title: Text(l10n.logout),
              onTap: () async {
                await context.read<AuthCubit>().logout();
                if (context.mounted) {
                  context.go(RoutePaths.login);
                }
              },
            ),
          ];

          final permissionsSection = [
            Text(
              l10n.rolesPermissions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (roles.isNotEmpty) ...[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: roles
                    .map(
                      (role) => Chip(
                        avatar: const Icon(Icons.badge_outlined, size: 16),
                        label: Text(localizeRoleLabel(l10n, role)),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (permissions.isEmpty)
              Text(
                l10n.profileNoPermissions,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              Column(
                children: [
                  for (final entry in groups.entries)
                    RolePermissionGroupCard(
                      module: entry.key,
                      count: entry.value.length,
                      initiallyExpanded: groups.length <= 3,
                      children: [
                        for (final permission in entry.value)
                          RolePermissionTile(
                            permissionKey: permission,
                            showCheckbox: false,
                          ),
                      ],
                    ),
                ],
              ),
            if (state.message != null &&
                !isUserFacingNetworkNoise(state.message)) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                localizeAppMessage(l10n, state.message),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ];

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<ProfileCubit>().load(
                        user,
                        forceRefresh: true,
                      ),
                  child: AppPageFrame(
                    maxWidth: isDesktop
                        ? AppBreakpoints.contentWideMax
                        : AppBreakpoints.contentMax,
                    child: ListView(
                      padding: AppScrollPadding.resolve(
                        context,
                        base: EdgeInsets.all(pagePad),
                        chrome: AppBottomChrome.system,
                      ),
                      children: [
                        if (isDesktop) ...[
                          AppDesktopWorkspacePadding(
                            child: AppDesktopPageHeader(title: l10n.profile),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (isDesktop)
                          AppDesktopSplitView(
                            start: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: accountSection,
                            ),
                            end: AppDesktopSurface(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: permissionsSection,
                              ),
                            ),
                          )
                        else ...[
                          ...accountSection,
                          ...permissionsSection,
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        const Center(
                          child: InfinityBrandImageView.logo(height: 72),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: Text(
                            AppConfig.appName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Center(
                          child: Text(
                            AppConfig.companyName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Map<String, List<String>> _groupPermissions(List<String> permissions) {
    final groups = <String, List<String>>{};
    for (final permission in permissions) {
      final sep = permission.indexOf(':');
      final module = sep > 0 ? permission.substring(0, sep) : 'general';
      groups.putIfAbsent(module, () => []).add(permission);
    }
    final keys = groups.keys.toList()..sort();
    return {for (final key in keys) key: (groups[key]!..sort())};
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.isDesktop,
    required this.imageUrl,
    required this.name,
    required this.email,
    required this.role,
    required this.fallbackLabel,
  });

  final bool isDesktop;
  final String? imageUrl;
  final String name;
  final String email;
  final String role;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = AppNetworkAvatar(
      imageUrl: imageUrl,
      radius: isDesktop ? 36 : 42,
      fallbackLabel: fallbackLabel,
    );

    if (!isDesktop) {
      return Column(
        children: [
          avatar,
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return AppListCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatar,
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Chip(
                  avatar: const Icon(Icons.badge_outlined, size: 16),
                  label: Text(role),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
