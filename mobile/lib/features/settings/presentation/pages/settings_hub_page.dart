import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_tiles.dart';

class SettingsHubPage extends StatefulWidget {
  const SettingsHubPage({super.key});

  @override
  State<SettingsHubPage> createState() => _SettingsHubPageState();
}

class _SettingsHubPageState extends State<SettingsHubPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(String query, List<String> values) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return values.any((v) => v.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authUser = context.watch<AuthCubit>().state.user;
    final canViewSettings =
        authUser?.permissionChecker.canViewSettings() == true;
    final canManageSettings =
        authUser?.permissionChecker.canManageSettings() == true;
    final canUsers = authUser?.permissionChecker.canViewUsers() == true;
    final canRoles = authUser?.permissionChecker.canViewRoles() == true;

    final sections = <_SettingsSection>[
      _SettingsSection(
        title: l10n.settingsSectionAccount,
        tiles: [
          _SettingsItem(
            icon: Icons.person_outline,
            title: l10n.settingsMyProfile,
            keywords: ['profile', 'account'],
            onTap: () => context.go(RoutePaths.profile),
          ),
          _SettingsItem(
            icon: Icons.lock_outline,
            title: l10n.settingsChangePassword,
            keywords: ['password', 'security'],
            onTap: () => context.push(RoutePaths.usersChangePassword),
          ),
          _SettingsItem(
            icon: Icons.language,
            title: l10n.settingsLanguage,
            keywords: ['language', 'locale', 'arabic', 'english'],
            onTap: () => context.push(RoutePaths.settingsLanguage),
          ),
          _SettingsItem(
            icon: Icons.brightness_6_outlined,
            title: l10n.settingsTheme,
            keywords: ['theme', 'dark', 'light'],
            onTap: () => context.push(RoutePaths.settingsTheme),
          ),
          _SettingsItem(
            icon: Icons.notifications_outlined,
            title: l10n.settingsNotificationPreferences,
            keywords: ['notification', 'push', 'email'],
            onTap: () => context.push(RoutePaths.settingsNotifications),
          ),
          _SettingsItem(
            icon: Icons.logout,
            title: l10n.logout,
            keywords: ['logout', 'sign out'],
            onTap: () async {
              await context.read<AuthCubit>().logout();
              if (context.mounted) context.go(RoutePaths.login);
            },
          ),
        ],
      ),
      if (canViewSettings || canManageSettings)
        _SettingsSection(
          title: l10n.settingsSectionOrganization,
          tiles: [
            _SettingsItem(
              icon: Icons.business_outlined,
              title: l10n.settingsCompanyInformation,
              keywords: ['company', 'organization', 'logo', 'address'],
              onTap: () => context.push(RoutePaths.settingsOrganization),
            ),
          ],
        ),
      if (canUsers || canRoles)
        _SettingsSection(
          title: l10n.settingsSectionAdministration,
          tiles: [
            if (canUsers)
              _SettingsItem(
                icon: Icons.manage_accounts_outlined,
                title: l10n.usersTitle,
                keywords: ['users', 'employees'],
                onTap: () => context.push(RoutePaths.users),
              ),
            if (canRoles)
              _SettingsItem(
                icon: Icons.admin_panel_settings_outlined,
                title: l10n.rolesTitle,
                keywords: ['roles', 'permissions'],
                onTap: () => context.push(RoutePaths.roles),
              ),
          ],
        ),
      if (canViewSettings)
        _SettingsSection(
          title: l10n.settingsSectionSystem,
          tiles: [
            _SettingsItem(
              icon: Icons.backup_outlined,
              title: l10n.settingsBackupRestore,
              keywords: ['backup', 'restore'],
              onTap: () => context.push(RoutePaths.settingsSystem),
              subtitle: l10n.settingsUiOnly,
            ),
            _SettingsItem(
              icon: Icons.cached_outlined,
              title: l10n.settingsCacheManagement,
              keywords: ['cache'],
              onTap: () => context.push(RoutePaths.settingsSystem),
              subtitle: l10n.settingsUiOnly,
            ),
            _SettingsItem(
              icon: Icons.monitor_heart_outlined,
              title: l10n.settingsSystemStatus,
              keywords: ['api', 'database', 'storage', 'version'],
              onTap: () => context.push(RoutePaths.settingsSystem),
            ),
          ],
        ),
      _SettingsSection(
        title: l10n.settingsSectionAbout,
        tiles: [
          _SettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: l10n.settingsPrivacyPolicy,
            keywords: ['privacy'],
            onTap: () => context.push(RoutePaths.settingsAbout),
          ),
          _SettingsItem(
            icon: Icons.description_outlined,
            title: l10n.settingsTermsOfService,
            keywords: ['terms'],
            onTap: () => context.push(RoutePaths.settingsAbout),
          ),
          _SettingsItem(
            icon: Icons.code,
            title: l10n.settingsOpenSourceLicenses,
            keywords: ['licenses', 'open source'],
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'INFINITY',
            ),
          ),
        ],
      ),
    ];

    final filtered = sections
        .map(
          (section) => _SettingsSection(
            title: section.title,
            tiles: section.tiles
                .where(
                  (tile) => _matches(_query, [
                    tile.title,
                    tile.subtitle ?? '',
                    ...tile.keywords,
                    section.title,
                  ]),
                )
                .toList(),
          ),
        )
        .where((section) => section.tiles.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.settingsSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        l10n.settingsEmptySearch,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                : ListView(
                    padding: AppScrollPadding.resolve(
                      context,
                      base: const EdgeInsets.only(bottom: AppSpacing.xl),
                      chrome: AppBottomChrome.system,
                    ),
                    children: [
                      for (var s = 0; s < filtered.length; s++) ...[
                        SettingsSectionHeader(
                          title: filtered[s].title,
                          isFirst: s == 0,
                        ),
                        Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < filtered[s].tiles.length;
                                  i++) ...[
                                if (i > 0) const Divider(height: 1),
                                SettingsTile(
                                  icon: filtered[s].tiles[i].icon,
                                  title: filtered[s].tiles[i].title,
                                  subtitle: filtered[s].tiles[i].subtitle,
                                  onTap: filtered[s].tiles[i].onTap,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection {
  const _SettingsSection({required this.title, required this.tiles});
  final String title;
  final List<_SettingsItem> tiles;
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.keywords,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<String> keywords;
  final VoidCallback onTap;
}
