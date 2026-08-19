import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/settings/presentation/pages/account_settings_pages.dart';
import 'package:mobile/features/settings/presentation/pages/organization_settings_page.dart';
import 'package:mobile/features/settings/presentation/pages/overtime_settings_page.dart';
import 'package:mobile/features/settings/presentation/pages/settings_extra_pages.dart';
import 'package:mobile/features/settings/presentation/pages/system_settings_page.dart';
import 'package:mobile/features/settings/presentation/pages/technician_interface_settings_page.dart';
import 'package:mobile/features/settings/presentation/utils/admin_settings_unlock_session.dart';
import 'package:mobile/features/settings/presentation/utils/server_management_unlock.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_tiles.dart';

enum _SettingsEmbedTarget {
  account,
  organization,
  system,
  language,
  theme,
  notifications,
  sync,
  storage,
  about,
  support,
  security,
  application,
  performance,
  accessibility,
  backup,
  danger,
  updates,
  overtime,
  technicianInterface,
}

class SettingsHubPage extends StatefulWidget {
  const SettingsHubPage({super.key});

  @override
  State<SettingsHubPage> createState() => _SettingsHubPageState();
}

class _SettingsHubPageState extends State<SettingsHubPage> {
  final _searchController = TextEditingController();
  String _query = '';
  int _selectedSection = 0;
  _SettingsEmbedTarget? _embeddedTarget;

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

  void _embed(_SettingsEmbedTarget target) {
    setState(() => _embeddedTarget = target);
  }

  void _handleTileTap(_SettingsItem item, bool isDesktop) {
    if (isDesktop && item.embedTarget != null) {
      _embed(item.embedTarget!);
      return;
    }
    item.onTap();
  }

  List<_SettingsSection> _buildSections(AppLocalizations l10n) {
    final authUser = context.watch<AuthCubit>().state.user;
    final canViewSettings =
        authUser?.permissionChecker.canViewSettings() == true;
    final canManageSettings =
        authUser?.permissionChecker.canManageSettings() == true;
    final isAdmin = authUser?.roles.any((r) => r.toUpperCase() == 'ADMIN') ==
            true ||
        canManageSettings;

    return <_SettingsSection>[
      _SettingsSection(
        title: l10n.settingsSectionAccount,
        icon: Icons.person_outline,
        tiles: [
          _SettingsItem(
            icon: Icons.manage_accounts_outlined,
            title: l10n.settingsAccountOverview,
            keywords: ['account', 'profile', 'photo', 'employee'],
            onTap: () => context.push(RoutePaths.settingsAccount),
            embedTarget: _SettingsEmbedTarget.account,
          ),
          _SettingsItem(
            icon: Icons.person_outline,
            title: l10n.settingsMyProfile,
            keywords: ['profile', 'edit'],
            onTap: () => context.go(RoutePaths.profile),
          ),
          _SettingsItem(
            icon: Icons.lock_outline,
            title: l10n.settingsChangePassword,
            keywords: ['password', 'security'],
            onTap: () => context.push(RoutePaths.usersChangePassword),
          ),
          _SettingsItem(
            icon: Icons.logout,
            title: l10n.logout,
            keywords: ['logout', 'sign out'],
            onTap: () async {
              final navigator = GoRouter.of(context);
              getIt<AdminSettingsUnlockSession>().clear();
              await context.read<AuthCubit>().logout();
              navigator.go(RoutePaths.login);
            },
          ),
        ],
      ),
      _SettingsSection(
        title: l10n.settingsSectionPreferences,
        icon: Icons.tune_outlined,
        tiles: [
          _SettingsItem(
            icon: Icons.language,
            title: l10n.settingsLanguage,
            keywords: ['language', 'locale', 'arabic', 'english'],
            onTap: () => context.push(RoutePaths.settingsLanguage),
            embedTarget: _SettingsEmbedTarget.language,
          ),
          _SettingsItem(
            icon: Icons.brightness_6_outlined,
            title: l10n.settingsTheme,
            keywords: ['theme', 'dark', 'light', 'appearance'],
            onTap: () => context.push(RoutePaths.settingsTheme),
            embedTarget: _SettingsEmbedTarget.theme,
          ),
          _SettingsItem(
            icon: Icons.notifications_outlined,
            title: l10n.settingsNotificationPreferences,
            keywords: ['notification', 'push', 'email'],
            onTap: () => context.push(RoutePaths.settingsNotifications),
            embedTarget: _SettingsEmbedTarget.notifications,
          ),
          _SettingsItem(
            icon: Icons.accessibility_new_outlined,
            title: l10n.settingsAccessibilityTitle,
            keywords: ['accessibility', 'contrast', 'text', 'animation'],
            onTap: () => context.push(RoutePaths.settingsAccessibility),
            embedTarget: _SettingsEmbedTarget.accessibility,
          ),
        ],
      ),
      _SettingsSection(
        title: l10n.settingsSectionSystem,
        icon: Icons.settings_suggest_outlined,
        tiles: [
          _SettingsItem(
            icon: Icons.sync_outlined,
            title: l10n.settingsSyncTitle,
            keywords: ['sync', 'offline', 'wifi'],
            onTap: () => context.push(RoutePaths.settingsSync),
            embedTarget: _SettingsEmbedTarget.sync,
          ),
          _SettingsItem(
            icon: Icons.cached_outlined,
            title: l10n.settingsStorageTitle,
            keywords: ['cache', 'storage', 'images'],
            onTap: () => context.push(RoutePaths.settingsStorage),
            embedTarget: _SettingsEmbedTarget.storage,
          ),
          _SettingsItem(
            icon: Icons.speed_outlined,
            title: l10n.settingsPerformanceTitle,
            keywords: ['performance', 'memory', 'latency'],
            onTap: () => context.push(RoutePaths.settingsPerformance),
            embedTarget: _SettingsEmbedTarget.performance,
          ),
          _SettingsItem(
            icon: Icons.phone_android_outlined,
            title: l10n.settingsApplicationTitle,
            keywords: ['application', 'version', 'api', 'environment'],
            onTap: () => context.push(RoutePaths.settingsApplication),
            embedTarget: _SettingsEmbedTarget.application,
          ),
          _SettingsItem(
            icon: Icons.system_update_alt,
            title: l10n.settingsUpdateCenter,
            keywords: ['update', 'version', 'release'],
            onTap: () => context.push(RoutePaths.settingsUpdates),
            embedTarget: _SettingsEmbedTarget.updates,
          ),
          if (canViewSettings)
            _SettingsItem(
              icon: Icons.monitor_heart_outlined,
              title: l10n.settingsSystemStatus,
              keywords: ['api', 'database', 'storage', 'version'],
              onTap: () => context.push(RoutePaths.settingsSystem),
              embedTarget: _SettingsEmbedTarget.system,
              onLongPress: () => openServerManagementSecurely(context),
            ),
          _SettingsItem(
            icon: Icons.backup_outlined,
            title: l10n.settingsBackupRestore,
            keywords: ['backup', 'restore'],
            onTap: () => context.push(RoutePaths.settingsBackup),
            embedTarget: _SettingsEmbedTarget.backup,
            subtitle: l10n.settingsUiOnly,
          ),
          _SettingsItem(
            icon: Icons.warning_amber_outlined,
            title: l10n.settingsDangerZone,
            keywords: ['reset', 'danger', 'defaults'],
            onTap: () => context.push(RoutePaths.settingsDanger),
            embedTarget: _SettingsEmbedTarget.danger,
          ),
        ],
      ),
      if (canViewSettings || canManageSettings)
        _SettingsSection(
          title: l10n.settingsCompanyInformation,
          icon: Icons.business_outlined,
          tiles: [
            _SettingsItem(
              icon: Icons.business_outlined,
              title: l10n.settingsCompanyInformation,
              keywords: ['company', 'logo', 'address'],
              onTap: () => context.push(RoutePaths.settingsCompany),
              embedTarget: _SettingsEmbedTarget.organization,
            ),
            _SettingsItem(
              icon: Icons.more_time_outlined,
              title: l10n.settingsOvertimeTitle,
              keywords: ['overtime', 'voice', 'recording', 'duration'],
              onTap: () => context.push(RoutePaths.settingsOvertime),
              embedTarget: _SettingsEmbedTarget.overtime,
            ),
            if (canManageSettings)
              _SettingsItem(
                icon: Icons.engineering_outlined,
                title: l10n.settingsTechnicianInterfaceTitle,
                keywords: [
                  'technician',
                  'interface',
                  'navigation',
                  'sections',
                ],
                onTap: () =>
                    context.push(RoutePaths.settingsTechnicianInterface),
                embedTarget: _SettingsEmbedTarget.technicianInterface,
              ),
          ],
        ),
      _SettingsSection(
        title: l10n.settingsSectionSecurity,
        icon: Icons.shield_outlined,
        tiles: [
          _SettingsItem(
            icon: Icons.security_outlined,
            title: l10n.settingsSecurityTitle,
            keywords: ['security', 'biometric', 'session'],
            onTap: () => context.push(RoutePaths.settingsSecurity),
            embedTarget: _SettingsEmbedTarget.security,
          ),
        ],
      ),
      _SettingsSection(
        title: l10n.settingsSectionSupport,
        icon: Icons.help_outline,
        tiles: [
          _SettingsItem(
            icon: Icons.support_agent_outlined,
            title: l10n.settingsSupportTitle,
            keywords: ['support', 'bug', 'faq', 'contact'],
            onTap: () => context.push(RoutePaths.settingsSupport),
            embedTarget: _SettingsEmbedTarget.support,
          ),
          _SettingsItem(
            icon: Icons.info_outline,
            title: l10n.settingsAboutApp,
            keywords: ['about', 'version', 'licenses'],
            onTap: () => context.push(RoutePaths.settingsAbout),
            embedTarget: _SettingsEmbedTarget.about,
          ),
          _SettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: l10n.settingsPrivacyPolicy,
            keywords: ['privacy'],
            onTap: () => context.push(RoutePaths.settingsAbout),
            embedTarget: _SettingsEmbedTarget.about,
          ),
          _SettingsItem(
            icon: Icons.description_outlined,
            title: l10n.settingsTermsOfService,
            keywords: ['terms'],
            onTap: () => context.push(RoutePaths.settingsAbout),
            embedTarget: _SettingsEmbedTarget.about,
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
      if (isAdmin)
        _SettingsSection(
          title: l10n.settingsSectionDeveloper,
          icon: Icons.developer_mode_outlined,
          tiles: [
            _SettingsItem(
              icon: Icons.developer_mode_outlined,
              title: l10n.settingsDeveloperOptions,
              keywords: ['developer', 'debug', 'flags'],
              onTap: () => openDeveloperOptionsSecurely(context),
              subtitle: l10n.settingsReadOnly,
            ),
            _SettingsItem(
              icon: Icons.article_outlined,
              title: l10n.settingsAdminLogs,
              keywords: ['logs', 'error', 'debug'],
              onTap: () => openAdminLogsSecurely(context),
            ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    final sections = _buildSections(l10n);
    final filtered = sections
        .map(
          (section) => _SettingsSection(
            title: section.title,
            icon: section.icon,
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

    if (filtered.isEmpty) {
      // keep index
    } else if (_selectedSection >= filtered.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedSection = 0);
      });
    }

    final contentIndex = filtered.isEmpty
        ? 0
        : _selectedSection.clamp(0, filtered.length - 1);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: AppPageFrame(
        maxWidth: AppBreakpoints.contentWideMax,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
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
                              setState(() {
                                _query = '';
                                _embeddedTarget = null;
                              });
                            },
                          ),
                  ),
                  onChanged: (value) => setState(() {
                    _query = value.trim();
                    _embeddedTarget = null;
                  }),
                ),
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
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : isDesktop
                      ? _DesktopSettingsSplit(
                          sections: filtered,
                          selectedIndex: contentIndex,
                          embeddedTarget: _embeddedTarget,
                          onSelect: (index) => setState(() {
                            _selectedSection = index;
                            _embeddedTarget = null;
                          }),
                          onTileTap: (item) => _handleTileTap(item, true),
                        )
                      : _MobileSettingsList(sections: filtered),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSettingsSplit extends StatelessWidget {
  const _DesktopSettingsSplit({
    required this.sections,
    required this.selectedIndex,
    required this.embeddedTarget,
    required this.onSelect,
    required this.onTileTap,
  });

  final List<_SettingsSection> sections;
  final int selectedIndex;
  final _SettingsEmbedTarget? embeddedTarget;
  final ValueChanged<int> onSelect;
  final ValueChanged<_SettingsItem> onTileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = sections[selectedIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 300,
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.xs,
                ),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  final selectedNav = index == selectedIndex;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ListTile(
                      selected: selectedNav,
                      leading: Icon(section.icon),
                      title: Text(section.title),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      onTap: () => onSelect(index),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: embeddedTarget == null
                  ? ListView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          child: Text(
                            selected.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        for (var i = 0; i < selected.tiles.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          SettingsTile(
                            icon: selected.tiles[i].icon,
                            title: selected.tiles[i].title,
                            subtitle: selected.tiles[i].subtitle,
                            onTap: () => onTileTap(selected.tiles[i]),
                            onLongPress: selected.tiles[i].onLongPress,
                          ),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (selected.tiles
                                .where((t) => t.embedTarget != null)
                                .length >
                            1)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                for (final tile in selected.tiles.where(
                                  (t) => t.embedTarget != null,
                                ))
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: AppSpacing.sm,
                                    ),
                                    child: GestureDetector(
                                      onLongPress: tile.onLongPress,
                                      child: ChoiceChip(
                                        selected:
                                            embeddedTarget == tile.embedTarget,
                                        avatar: Icon(tile.icon, size: 18),
                                        label: Text(tile.title),
                                        onSelected: (_) => onTileTap(tile),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: _SettingsEmbeddedContent(
                            target: embeddedTarget!,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsEmbeddedContent extends StatelessWidget {
  const _SettingsEmbeddedContent({required this.target});

  final _SettingsEmbedTarget target;

  @override
  Widget build(BuildContext context) {
    return switch (target) {
      _SettingsEmbedTarget.account =>
        const AccountOverviewPage(embedded: true),
      _SettingsEmbedTarget.organization =>
        const OrganizationSettingsPage(embedded: true),
      _SettingsEmbedTarget.overtime =>
        const OvertimeSettingsPage(embedded: true),
      _SettingsEmbedTarget.technicianInterface =>
        const TechnicianInterfaceSettingsPage(embedded: true),
      _SettingsEmbedTarget.system => const SystemSettingsPage(embedded: true),
      _SettingsEmbedTarget.language =>
        const LanguageSettingsPage(embedded: true),
      _SettingsEmbedTarget.theme => const ThemeSettingsPage(embedded: true),
      _SettingsEmbedTarget.notifications =>
        const NotificationPreferencesPage(embedded: true),
      _SettingsEmbedTarget.sync => const SyncSettingsPage(embedded: true),
      _SettingsEmbedTarget.storage =>
        const StorageSettingsPage(embedded: true),
      _SettingsEmbedTarget.about => const AboutSettingsPage(embedded: true),
      _SettingsEmbedTarget.support =>
        const SupportSettingsPage(embedded: true),
      _SettingsEmbedTarget.security =>
        const SecuritySettingsPage(embedded: true),
      _SettingsEmbedTarget.application =>
        const ApplicationInfoPage(embedded: true),
      _SettingsEmbedTarget.performance =>
        const PerformanceSettingsPage(embedded: true),
      _SettingsEmbedTarget.accessibility =>
        const AccessibilitySettingsPage(embedded: true),
      _SettingsEmbedTarget.backup => const BackupSettingsPage(embedded: true),
      _SettingsEmbedTarget.danger => const DangerZonePage(embedded: true),
      _SettingsEmbedTarget.updates => const UpdateCenterPage(embedded: true),
    };
  }
}

class _MobileSettingsList extends StatelessWidget {
  const _MobileSettingsList({required this.sections});

  final List<_SettingsSection> sections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.only(bottom: AppSpacing.xl),
        chrome: AppBottomChrome.system,
      ),
      children: [
        for (var s = 0; s < sections.length; s++) ...[
          SettingsSectionHeader(
            title: sections[s].title,
            isFirst: s == 0,
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < sections[s].tiles.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  SettingsTile(
                    icon: sections[s].tiles[i].icon,
                    title: sections[s].tiles[i].title,
                    subtitle: sections[s].tiles[i].subtitle,
                    onTap: sections[s].tiles[i].onTap,
                    onLongPress: sections[s].tiles[i].onLongPress,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SettingsSection {
  const _SettingsSection({
    required this.title,
    required this.tiles,
    this.icon = Icons.settings_outlined,
  });
  final String title;
  final IconData icon;
  final List<_SettingsItem> tiles;
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.keywords,
    required this.onTap,
    this.onLongPress,
    this.subtitle,
    this.embedTarget,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<String> keywords;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final _SettingsEmbedTarget? embedTarget;
}
