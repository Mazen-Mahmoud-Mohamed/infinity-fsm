import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/branding/infinity_brand.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/features/organization/presentation/cubit/profile_cubit.dart';
import 'package:mobile/features/organization/presentation/widgets/offline_banner.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            onPressed: () => context.push(RoutePaths.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final user = state.user ?? context.watch<AuthCubit>().state.user;
          final org = state.context;

          if (state.status == ProfileStatus.loading && org == null) {
            return AppLoader(message: l10n.profileLoading);
          }

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<ProfileCubit>().load(
                        user,
                        forceRefresh: true,
                      ),
                  child: ListView(
                    padding: AppScrollPadding.resolve(
                      context,
                      base: EdgeInsets.all(
                        MediaQuery.sizeOf(context).width < 600
                            ? AppSpacing.md
                            : AppSpacing.lg,
                      ),
                      chrome: AppBottomChrome.system,
                    ),
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 42,
                          backgroundImage: user?.profilePhotoUrl != null
                              ? NetworkImage(user!.profilePhotoUrl!)
                              : null,
                          child: user?.profilePhotoUrl == null
                              ? Text(
                                  _initials(
                                    user?.fullName ?? user?.email ?? '?',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: Text(
                          user?.fullName ?? l10n.profile,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
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
                        value: user?.primaryRole ?? '-',
                      ),
                      _ProfileRow(
                        label: l10n.companyLabel,
                        value: org?.company?.name ?? '-',
                      ),
                      _ProfileRow(
                        label: l10n.usersBranch,
                        value: org?.branch?.name ?? '-',
                      ),
                      _ProfileRow(
                        label: l10n.departmentLabel,
                        value: org?.department?.name ?? '-',
                      ),
                      _ProfileRow(
                        label: l10n.profilePosition,
                        value: org?.position?.name ?? '-',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Center(
                        child: InfinityBrandImageView.logo(height: 94),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: Text(
                          AppConfig.appName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
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
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.rolesPermissions,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (user?.permissions.isEmpty ?? true)
                        Text(
                          l10n.profileNoPermissions,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        )
                      else
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: user!.permissions
                              .map(
                                (permission) => Chip(
                                  label: Text(permission),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      if (state.message != null &&
                          !isUserFacingNetworkNoise(state.message)) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          localizeAppMessage(l10n, state.message),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.lock_outline),
                        title: Text(l10n.settingsChangePassword),
                        onTap: () =>
                            context.push(RoutePaths.usersChangePassword),
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
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
