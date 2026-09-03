import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/services/app_package_info.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/settings/presentation/utils/server_management_unlock.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_layout.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_package_version_rows.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';
import 'package:mobile/core/push/push_notification_service.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localePreference =
        context.select((AppCubit c) => c.state.localePreference);

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsLanguage,
          leading: const Icon(Icons.language),
          child: RadioGroup<String>(
            groupValue: localePreference,
            onChanged: (value) {
              if (value == null) return;
              final cubit = context.read<AppCubit>();
              switch (value) {
                case 'system':
                  cubit.setLocaleToSystem();
                case 'ar':
                  cubit.setLocaleCode('ar');
                case 'en':
                  cubit.setLocaleCode('en');
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'system',
                  title: Text(l10n.settingsLanguageSystem),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'ar',
                  title: Text(l10n.settingsLanguageArabic),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'en',
                  title: Text(l10n.settingsLanguageEnglish),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLanguage)),
      body: body,
    );
  }
}

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  /// Local preview brightness only — never writes to [AppCubit] theme mode.
  bool _previewDark = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = context.select((AppCubit c) => c.state.themeMode);
    final previewTheme = _previewDark ? AppTheme.dark() : AppTheme.light();

    final body = SettingsPageBody(
      embedded: widget.embedded,
      children: [
        SettingsCard(
          title: l10n.settingsTheme,
          leading: const Icon(Icons.brightness_6_outlined),
          child: RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) {
                context.read<AppCubit>().setThemeMode(value);
              }
            },
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text(l10n.settingsThemeSystem),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text(l10n.settingsThemeLight),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text(l10n.settingsThemeDark),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsCard(
          title: l10n.settingsThemePreview,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settingsThemePreviewBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(l10n.settingsThemeLight),
                    icon: const Icon(Icons.light_mode_outlined, size: 18),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(l10n.settingsThemeDark),
                    icon: const Icon(Icons.dark_mode_outlined, size: 18),
                  ),
                ],
                selected: {_previewDark},
                onSelectionChanged: (selected) {
                  setState(() => _previewDark = selected.first);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Theme(
                data: previewTheme,
                child: Builder(
                  builder: (previewContext) {
                    final previewScheme = Theme.of(previewContext).colorScheme;
                    final previewText = Theme.of(previewContext).textTheme;
                    return Material(
                      color: previewScheme.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: previewScheme.outlineVariant
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _previewDark
                                      ? Icons.dark_mode_outlined
                                      : Icons.light_mode_outlined,
                                  color: previewScheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _previewDark
                                        ? l10n.settingsThemeDark
                                        : l10n.settingsThemeLight,
                                    style: previewText.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Chip(
                                  avatar: Icon(
                                    Icons.visibility_outlined,
                                    size: 16,
                                    color: previewScheme.primary,
                                  ),
                                  label: Text(l10n.settingsThemePreview),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.settingsThemePreview,
                                      style: previewText.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      l10n.settingsThemePreviewBody,
                                      style: previewText.bodySmall?.copyWith(
                                        color: previewScheme.onSurfaceVariant,
                                        height: 1.35,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.settingsTheme,
                              style: previewText.bodyLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              key: ValueKey<bool>(_previewDark),
                              readOnly: true,
                              initialValue: _previewDark
                                  ? l10n.settingsThemeDark
                                  : l10n.settingsThemeLight,
                              decoration: InputDecoration(
                                labelText: l10n.settingsTheme,
                                prefixIcon: const Icon(Icons.palette_outlined),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                FilledButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.check, size: 18),
                                  label: Text(l10n.save),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.close, size: 18),
                                  label: Text(l10n.cancel),
                                ),
                                TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.info_outline,
                                    size: 18,
                                  ),
                                  label: Text(l10n.settingsThemeSystem),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Divider(),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Icon(
                                  Icons.dashboard_outlined,
                                  color: previewScheme.primary,
                                ),
                                Icon(
                                  Icons.notifications_outlined,
                                  color: previewScheme.onSurfaceVariant,
                                ),
                                Icon(
                                  Icons.settings_outlined,
                                  color: previewScheme.secondary,
                                ),
                                Chip(
                                  label: Text(l10n.settingsThemeLight),
                                  avatar: const Icon(
                                    Icons.light_mode_outlined,
                                    size: 16,
                                  ),
                                ),
                                Chip(
                                  label: Text(l10n.settingsThemeDark),
                                  avatar: const Icon(
                                    Icons.dark_mode_outlined,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTheme)),
      body: body,
    );
  }
}

class NotificationPreferencesPage extends StatelessWidget {
  const NotificationPreferencesPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AppCubit>().state;

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsNotificationPreferences,
          leading: const Icon(Icons.notifications_outlined),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsPushNotifications),
            value: state.notificationPushEnabled,
            onChanged: (value) async {
              await context
                  .read<AppCubit>()
                  .setNotificationPreferences(pushEnabled: value);
              if (getIt.isRegistered<PushNotificationService>()) {
                await getIt<PushNotificationService>()
                    .applyPushPreference(value);
              }
            },
          ),
        ),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotificationPreferences)),
      body: body,
    );
  }
}

class AboutSettingsPage extends StatefulWidget {
  const AboutSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AboutSettingsPage> createState() => _AboutSettingsPageState();
}

class _AboutSettingsPageState extends State<AboutSettingsPage> {
  int _versionTaps = 0;
  DateTime? _firstTapAt;

  static const int _requiredTaps = 7;
  static const Duration _tapWindow = Duration(seconds: 4);

  void _onVersionTap() {
    final now = DateTime.now();
    if (_firstTapAt == null || now.difference(_firstTapAt!) > _tapWindow) {
      _firstTapAt = now;
      _versionTaps = 1;
      return;
    }

    _versionTaps += 1;
    if (_versionTaps < _requiredTaps) {
      return;
    }

    _versionTaps = 0;
    _firstTapAt = null;
    openDeveloperOptionsSecurely(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final channel = context.watch<AppCubit>().state.releaseChannel;
    final year = DateTime.now().year.toString();

    final body = SettingsPageBody(
      embedded: widget.embedded,
      children: [
        SettingsCard(
          child: Column(
            children: [
              InkWell(
                onTap: _onVersionTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppConfig.appName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        AppConfig.companyName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              SettingsPackageVersionRows(
                versionLabel: l10n.serverMgmtAppVersion,
                buildLabel: l10n.serverMgmtBuildNumber,
              ),
              SettingsInfoRow(
                label: l10n.settingsReleaseChannel,
                value: channel,
              ),
              SettingsInfoRow(
                label: l10n.settingsDeveloper,
                value: AppConfig.companyName,
              ),
              SettingsInfoRow(
                label: l10n.settingsCompanyName,
                value: AppConfig.companyName,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.settingsCopyright(year, AppConfig.companyName),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsCard(
          title: l10n.settingsPrivacyPolicy,
          child: Text(
            l10n.settingsPrivacyBody,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsCard(
          title: l10n.settingsTermsOfService,
          child: Text(
            l10n.settingsTermsBody,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsCard(
          title: l10n.settingsOpenSourceLicenses,
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.code,
                title: l10n.settingsOpenSourcePackages,
                onTap: () async {
                  final info = await AppPackageInfo.load();
                  if (!context.mounted) return;
                  showLicensePage(
                    context: context,
                    applicationName: AppConfig.appName,
                    applicationVersion: '${info.version}+${info.buildNumber}',
                    applicationLegalese: AppConfig.companyName,
                  );
                },
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.system_update_alt,
                title: l10n.settingsUpdateCenter,
                onTap: () => context.push(RoutePaths.settingsUpdates),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAboutApp)),
      body: body,
    );
  }
}
