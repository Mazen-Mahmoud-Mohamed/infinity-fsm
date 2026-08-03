import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/settings/presentation/utils/server_management_unlock.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_layout.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = context.select((AppCubit c) => c.state.localeCode);

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsLanguage,
          leading: const Icon(Icons.language),
          child: RadioGroup<String>(
            groupValue: localeCode,
            onChanged: (value) {
              if (value != null) {
                context.read<AppCubit>().setLocaleCode(value);
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'en',
                  title: Text(l10n.settingsLanguageEnglish),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'ar',
                  title: Text(l10n.settingsLanguageArabic),
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

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeMode = context.select((AppCubit c) => c.state.themeMode);

    final body = SettingsPageBody(
      embedded: embedded,
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
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              SettingsActionBar(
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, kSettingsControlHeight),
                    ),
                    onPressed: () => context
                        .read<AppCubit>()
                        .setThemeMode(ThemeMode.light),
                    child: Text(l10n.settingsThemeLight),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, kSettingsControlHeight),
                    ),
                    onPressed: () =>
                        context.read<AppCubit>().setThemeMode(ThemeMode.dark),
                    child: Text(l10n.settingsThemeDark),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        theme.brightness == Brightness.dark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        theme.brightness == Brightness.dark
                            ? l10n.settingsThemeDark
                            : l10n.settingsThemeLight,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (embedded) return body;

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
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsPushNotifications),
                value: state.notificationPushEnabled,
                onChanged: (value) => context
                    .read<AppCubit>()
                    .setNotificationPreferences(pushEnabled: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsEmailNotifications),
                value: state.notificationEmailEnabled,
                onChanged: (value) => context
                    .read<AppCubit>()
                    .setNotificationPreferences(emailEnabled: value),
              ),
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsNotifAttendance),
                value: state.notifAttendance,
                onChanged: (value) => context
                    .read<AppCubit>()
                    .setNotificationPreferences(attendance: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsNotifTasks),
                value: state.notifTasks,
                onChanged: (value) => context
                    .read<AppCubit>()
                    .setNotificationPreferences(tasks: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsNotifOvertime),
                value: state.notifOvertime,
                onChanged: (value) => context
                    .read<AppCubit>()
                    .setNotificationPreferences(overtime: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsNotifSync),
                value: state.notifSync,
                onChanged: (value) => context
                    .read<AppCubit>()
                    .setNotificationPreferences(sync: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsNotifUpdates),
                value: state.notifUpdates,
                onChanged: (value) => context
                    .read<AppCubit>()
                    .setNotificationPreferences(updates: value),
              ),
            ],
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
              SettingsInfoRow(
                label: l10n.serverMgmtAppVersion,
                value: AppConfig.appVersion,
              ),
              SettingsInfoRow(
                label: l10n.serverMgmtBuildNumber,
                value: AppConfig.buildNumber,
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
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: AppConfig.appName,
                  applicationVersion:
                      '${AppConfig.appVersion}+${AppConfig.buildNumber}',
                  applicationLegalese: AppConfig.companyName,
                ),
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
