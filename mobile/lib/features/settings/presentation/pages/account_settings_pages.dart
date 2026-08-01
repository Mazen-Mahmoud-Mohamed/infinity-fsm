import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = context.select((AppCubit c) => c.state.localeCode);

    final body = ListView(
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.all(AppSpacing.md),
        chrome: AppBottomChrome.system,
      ),
      children: [
        RadioListTile<String>(
          value: 'en',
          groupValue: localeCode,
          title: Text(l10n.settingsLanguageEnglish),
          onChanged: (value) {
            if (value != null) {
              context.read<AppCubit>().setLocaleCode(value);
            }
          },
        ),
        RadioListTile<String>(
          value: 'ar',
          groupValue: localeCode,
          title: Text(l10n.settingsLanguageArabic),
          onChanged: (value) {
            if (value != null) {
              context.read<AppCubit>().setLocaleCode(value);
            }
          },
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
    final themeMode = context.select((AppCubit c) => c.state.themeMode);

    final body = ListView(
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.all(AppSpacing.md),
        chrome: AppBottomChrome.system,
      ),
      children: [
        RadioListTile<ThemeMode>(
          value: ThemeMode.system,
          groupValue: themeMode,
          title: Text(l10n.settingsThemeSystem),
          onChanged: (value) {
            if (value != null) context.read<AppCubit>().setThemeMode(value);
          },
        ),
        RadioListTile<ThemeMode>(
          value: ThemeMode.light,
          groupValue: themeMode,
          title: Text(l10n.settingsThemeLight),
          onChanged: (value) {
            if (value != null) context.read<AppCubit>().setThemeMode(value);
          },
        ),
        RadioListTile<ThemeMode>(
          value: ThemeMode.dark,
          groupValue: themeMode,
          title: Text(l10n.settingsThemeDark),
          onChanged: (value) {
            if (value != null) context.read<AppCubit>().setThemeMode(value);
          },
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
    final push = context.select((AppCubit c) => c.state.notificationPushEnabled);
    final email =
        context.select((AppCubit c) => c.state.notificationEmailEnabled);

    final body = ListView(
      padding: AppScrollPadding.resolve(
        context,
        base: EdgeInsets.zero,
        chrome: AppBottomChrome.system,
      ),
      children: [
        SwitchListTile(
          title: Text(l10n.settingsPushNotifications),
          value: push,
          onChanged: (value) => context
              .read<AppCubit>()
              .setNotificationPreferences(pushEnabled: value),
        ),
        SwitchListTile(
          title: Text(l10n.settingsEmailNotifications),
          value: email,
          onChanged: (value) => context
              .read<AppCubit>()
              .setNotificationPreferences(emailEnabled: value),
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

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final body = ListView(
      padding: AppScrollPadding.resolve(
        context,
        base: const EdgeInsets.all(AppSpacing.lg),
        chrome: AppBottomChrome.system,
      ),
      children: [
        Text(l10n.settingsPrivacyPolicy, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.settingsPrivacyBody, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.settingsTermsOfService, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.settingsTermsBody, style: theme.textTheme.bodyMedium),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSectionAbout)),
      body: body,
    );
  }
}
