import 'dart:io' show File, Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/config/api_endpoint_service.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_rbac.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/services/app_log_buffer.dart';
import 'package:mobile/core/services/app_runtime_info.dart';
import 'package:mobile/core/services/biometric_auth_service.dart';
import 'package:mobile/core/services/sync_configuration_service.dart';
import 'package:mobile/core/widgets/offline_banner.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_sync_cubit.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';
import 'package:mobile/features/settings/presentation/pages/server_management_page.dart';
import 'package:mobile/features/settings/presentation/utils/server_management_unlock.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_layout.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';
import 'package:mobile/shared/presentation/utils/profile_photo_update.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:mobile/features/app_update/presentation/pages/update_center_page.dart';

// â”€â”€â”€ Account overview â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AccountOverviewPage extends StatefulWidget {
  const AccountOverviewPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AccountOverviewPage> createState() => _AccountOverviewPageState();
}

class _AccountOverviewPageState extends State<AccountOverviewPage> {
  int _avatarEpoch = 0;
  bool _uploading = false;

  Future<void> _onChangePhoto() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final ok = await changeOwnProfilePhoto(context);
      if (mounted && ok) setState(() => _avatarEpoch++);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthCubit>().state.user;

    final body = SettingsPageBody(
      embedded: widget.embedded,
      children: [
        SettingsCard(
          title: l10n.settingsAccountOverview,
          child: Column(
            children: [
              KeyedSubtree(
                key: ValueKey('account-avatar-$_avatarEpoch-${user?.profilePhotoUrl}'),
                child: AppNetworkAvatar(
                  imageUrl: user?.profilePhotoUrl,
                  radius: 40,
                  fallbackLabel: user?.fullName,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonal(
                onPressed: _uploading ? null : _onChangePhoto,
                child: Text(l10n.settingsChangePhoto),
              ),
              const SizedBox(height: AppSpacing.md),
              SettingsInfoRow(
                label: l10n.labelName,
                value: user?.fullName ?? '-',
              ),
              SettingsInfoRow(label: l10n.email, value: user?.email ?? '-'),
              SettingsInfoRow(
                label: l10n.roleLabel,
                value: localizeRoleLabel(l10n, user?.primaryRole),
              ),
              SettingsInfoRow(
                label: l10n.settingsEmployeeId,
                value: user?.employeeId ?? '-',
              ),
              SettingsInfoRow(
                label: l10n.settingsBranch,
                value: user?.branchId ?? '-',
              ),
              SettingsInfoRow(
                label: l10n.settingsDepartment,
                value: user?.departmentId ?? '-',
              ),
              SettingsInfoRow(
                label: l10n.settingsAccountCreated,
                value: l10n.settingsNotAvailable,
              ),
              SettingsInfoRow(
                label: l10n.settingsLastLogin,
                value: l10n.settingsNotAvailable,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsCard(
          title: l10n.settingsEditablePrefs,
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.language,
                title: l10n.settingsLanguage,
                onTap: () => context.push(RoutePaths.settingsLanguage),
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.brightness_6_outlined,
                title: l10n.settingsTheme,
                onTap: () => context.push(RoutePaths.settingsTheme),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAccountOverview)),
      body: body,
    );
  }
}

// â”€â”€â”€ Sync â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class SyncSettingsPage extends StatelessWidget {
  const SyncSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = context.watch<AppCubit>();
    final attendance = context.watch<AttendanceSyncCubit>().state;
    final overtime = context.watch<OvertimeSyncCubit>().state;
    final pending = attendance.pendingCount + overtime.pendingCount;

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsSyncTitle,
          child: Column(
            children: [
              SettingsInfoRow(
                label: l10n.settingsLastSuccessfulSync,
                value: attendance.lastSyncedAt == null
                    ? l10n.settingsNotAvailable
                    : AppFormatters.mediumDateTime(context)
                        .format(attendance.lastSyncedAt!),
              ),
              SettingsInfoRow(
                label: l10n.settingsPendingUploads,
                value: '$pending',
              ),
              SettingsInfoRow(
                label: l10n.settingsPendingDownloads,
                value: '0',
              ),
              SettingsInfoRow(
                label: l10n.settingsSyncStatus,
                value: connectivityStatusMessage(
                      l10n,
                      context.watch<AppCubit>().state.connectivity,
                    ) ??
                    l10n.connectivityOnline,
              ),
              SettingsInfoRow(
                label: l10n.settingsNetworkRequirement,
                value: app.state.wifiOnlySync
                    ? l10n.settingsWifiOnlySync
                    : l10n.serverMgmtOnline,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsAutoSync),
                value: app.state.autoSync,
                onChanged: (v) =>
                    context.read<AppCubit>().setSyncPreferences(autoSync: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsWifiOnlySync),
                value: app.state.wifiOnlySync,
                onChanged: (v) =>
                    context.read<AppCubit>().setSyncPreferences(wifiOnly: v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsSyncInterval),
                subtitle: Text('${app.state.syncIntervalMinutes} min'),
                trailing: DropdownButton<int>(
                  value: app.state.syncIntervalMinutes,
                  items: SyncConfigurationService.supportedIntervalMinutes
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text('$m min'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      context
                          .read<AppCubit>()
                          .setSyncPreferences(intervalMinutes: v);
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () async {
                  final attendance =
                      context.read<AttendanceSyncCubit>();
                  final overtime = context.read<OvertimeSyncCubit>();
                  final messenger = ScaffoldMessenger.of(context);
                  await attendance.syncNow();
                  await overtime.syncNow(force: true);
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.settingsManualSyncDone)),
                  );
                },
                icon: const Icon(Icons.sync),
                label: Text(l10n.settingsManualSync),
              ),
            ],
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSyncTitle)),
      body: body,
    );
  }
}

// â”€â”€â”€ Storage / Cache â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class StorageSettingsPage extends StatelessWidget {
  const StorageSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cache = PaintingBinding.instance.imageCache;
    final approxKb = (cache.currentSizeBytes / 1024).round();

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsStorageTitle,
          child: Column(
            children: [
              SettingsInfoRow(
                label: l10n.settingsCacheSize,
                value: '~$approxKb KB',
              ),
              SettingsInfoRow(
                label: l10n.settingsImagesSize,
                value: '${cache.currentSize} entries',
              ),
              SettingsInfoRow(
                label: l10n.settingsTempFiles,
                value: l10n.settingsManagedByOs,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await context.read<AppCubit>().clearLocalCache();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.settingsCacheCleared)),
                  );
                },
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text(l10n.settingsClearCache),
              ),
            ],
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsStorageTitle)),
      body: body,
    );
  }
}

// â”€â”€â”€ Support â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class SupportSettingsPage extends StatelessWidget {
  const SupportSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  Future<void> _open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsSupportTitle,
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.mail_outline,
                title: l10n.settingsContactSupport,
                onTap: () => _open(
                  Uri(
                    scheme: 'mailto',
                    path: 'support@infinityfsm.com',
                    queryParameters: {
                      'subject': 'Infinity FSM Support',
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.bug_report_outlined,
                title: l10n.settingsReportBug,
                onTap: () => _open(
                  Uri(
                    scheme: 'mailto',
                    path: 'support@infinityfsm.com',
                    queryParameters: {'subject': 'Bug Report'},
                  ),
                ),
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.lightbulb_outline,
                title: l10n.settingsRequestFeature,
                onTap: () => _open(
                  Uri(
                    scheme: 'mailto',
                    path: 'support@infinityfsm.com',
                    queryParameters: {'subject': 'Feature Request'},
                  ),
                ),
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.help_outline,
                title: l10n.settingsFaq,
                onTap: () => _open(Uri.parse('https://infinityfsm.com/faq')),
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.settingsPrivacyPolicy,
                onTap: () => context.push(RoutePaths.settingsAbout),
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.description_outlined,
                title: l10n.settingsTermsOfService,
                onTap: () => context.push(RoutePaths.settingsAbout),
              ),
            ],
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSupportTitle)),
      body: body,
    );
  }
}

// â”€â”€â”€ Security â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthCubit>().state.user;

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsSecurityTitle,
          child: Column(
            children: [
              SettingsInfoRow(
                label: l10n.settingsCurrentSession,
                value: user?.email ?? '-',
              ),
              SettingsInfoRow(
                label: l10n.settingsLastLogin,
                value: l10n.settingsNotAvailable,
              ),
              SettingsInfoRow(
                label: l10n.settingsDeviceName,
                value: Platform.localHostname,
              ),
              FutureBuilder<bool>(
                future: getIt<BiometricAuthService>().canAuthenticate(),
                builder: (context, snap) {
                  return SettingsInfoRow(
                    label: l10n.settingsBiometricStatus,
                    value: snap.data == true
                        ? l10n.settingsBiometricAvailable
                        : l10n.settingsBiometricUnavailable,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SettingsTile(
                icon: Icons.lock_outline,
                title: l10n.settingsChangePassword,
                onTap: () => context.push(RoutePaths.usersChangePassword),
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.devices_other_outlined,
                title: l10n.settingsLogoutAllDevices,
                subtitle: l10n.settingsComingSoonAction,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.settingsComingSoonAction)),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSecurityTitle)),
      body: body,
    );
  }
}

// â”€â”€â”€ Application info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ApplicationInfoPage extends StatelessWidget {
  const ApplicationInfoPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final api = getIt<ApiEndpointService>();
    final env = getIt<EnvConfig>();

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsApplicationTitle,
          child: Column(
            children: [
              SettingsInfoRow(
                label: l10n.serverMgmtAppVersion,
                value: AppConfig.appVersion,
              ),
              SettingsInfoRow(
                label: l10n.serverMgmtBuildNumber,
                value: AppConfig.buildNumber,
              ),
              SettingsInfoRow(
                label: l10n.serverMgmtPlatform,
                value: Theme.of(context).platform.name,
              ),
              SettingsInfoRow(
                label: l10n.serverMgmtDeviceModel,
                value: Platform.localHostname,
              ),
              SettingsInfoRow(
                label: l10n.serverMgmtCurrentApiUrl,
                value: api.effectiveBaseUrl,
                selectable: true,
              ),
              SettingsInfoRow(
                label: l10n.serverMgmtEnvironment,
                value: const String.fromEnvironment(
                  'ENV',
                  defaultValue: 'production',
                ),
              ),
              SettingsInfoRow(
                label: l10n.serverMgmtCurrentServer,
                value: ApiUrlNormalizer.serverDisplayName(env.apiBaseUrl),
              ),
            ],
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsApplicationTitle)),
      body: body,
    );
  }
}

// â”€â”€â”€ Performance (read-only) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class PerformanceSettingsPage extends StatelessWidget {
  const PerformanceSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cache = PaintingBinding.instance.imageCache;
    final online = context.watch<AppCubit>().state.isOnline;
    final uptime = getIt<AppRuntimeInfo>().uptime;

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsPerformanceTitle,
          child: Column(
            children: [
              SettingsInfoRow(
                label: l10n.settingsMemoryUsage,
                value: l10n.settingsManagedByOs,
              ),
              SettingsInfoRow(
                label: l10n.settingsCacheUsage,
                value:
                    '${(cache.currentSizeBytes / 1024).toStringAsFixed(0)} KB',
              ),
              SettingsInfoRow(
                label: l10n.settingsNetworkLatency,
                value: l10n.settingsUseServerMgmt,
              ),
              SettingsInfoRow(
                label: l10n.settingsDatabaseConnection,
                value: online ? l10n.serverMgmtOnline : l10n.serverMgmtOffline,
              ),
              SettingsInfoRow(
                label: l10n.settingsServerHealth,
                value: online
                    ? l10n.serverMgmtHealthHealthy
                    : l10n.serverMgmtHealthError,
              ),
              SettingsInfoRow(
                label: l10n.serverMgmtAppUptime,
                value: '${uptime.inMinutes} min',
              ),
            ],
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPerformanceTitle)),
      body: body,
    );
  }
}

// â”€â”€â”€ Accessibility â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = context.watch<AppCubit>();

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsAccessibilityTitle,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsLargeText),
                value: app.state.largeText,
                onChanged: (v) => context
                    .read<AppCubit>()
                    .setAccessibilityPreferences(largeText: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsReduceAnimations),
                value: app.state.reduceAnimations,
                onChanged: (v) => context
                    .read<AppCubit>()
                    .setAccessibilityPreferences(reduceAnimations: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsHighContrast),
                value: app.state.highContrast,
                onChanged: (v) => context
                    .read<AppCubit>()
                    .setAccessibilityPreferences(highContrast: v),
              ),
            ],
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAccessibilityTitle)),
      body: body,
    );
  }
}

// â”€â”€â”€ Backup placeholder â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class BackupSettingsPage extends StatelessWidget {
  const BackupSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsBackupRestore,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.settingsBackupUnavailable),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.settingsRestoreUnavailable),
            ],
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsBackupRestore)),
      body: body,
    );
  }
}

// â”€â”€â”€ Danger zone â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class DangerZonePage extends StatelessWidget {
  const DangerZonePage({super.key, this.embedded = false});

  final bool embedded;

  Future<bool> _confirm(BuildContext context, String title, String body) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsConfirm),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final body = SettingsPageBody(
      embedded: embedded,
      children: [
        SettingsCard(
          title: l10n.settingsDangerZone,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settingsDangerZoneHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    l10n.settingsResetPreferences,
                    l10n.settingsResetPreferencesConfirm,
                  );
                  if (!ok || !context.mounted) return;
                  await context.read<AppCubit>().restoreDefaultPreferences();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.settingsPrefsRestored)),
                  );
                },
                child: Text(l10n.settingsResetPreferences),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    l10n.settingsClearCache,
                    l10n.settingsClearCacheConfirm,
                  );
                  if (!ok || !context.mounted) return;
                  await context.read<AppCubit>().clearLocalCache();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.settingsCacheCleared)),
                  );
                },
                child: Text(l10n.settingsClearCache),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    l10n.settingsRestoreDefaults,
                    l10n.settingsRestoreDefaultsConfirm,
                  );
                  if (!ok || !context.mounted) return;
                  final app = context.read<AppCubit>();
                  final messenger = ScaffoldMessenger.of(context);
                  await app.restoreDefaultPreferences();
                  await app.clearLocalCache();
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.settingsPrefsRestored)),
                  );
                },
                child: Text(l10n.settingsRestoreDefaults),
              ),
            ],
          ),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsDangerZone)),
      body: body,
    );
  }
}

// â”€â”€â”€ Update center â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// â”€â”€â”€ Admin logs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AdminLogsPage extends StatefulWidget {
  const AdminLogsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminLogsPage> createState() => _AdminLogsPageState();
}

class _AdminLogsPageState extends State<AdminLogsPage> {
  String _query = '';
  AppLogLevel? _level;
  AppLogCategory? _category;
  bool _unlockChecked = false;
  bool _unlockAllowed = false;

  AppLogBuffer get _buffer => getIt<AppLogBuffer>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _gateUnlock());
  }

  Future<void> _gateUnlock() async {
    final user = context.read<AuthCubit>().state.user;
    if (!ServerManagementPage.canAccess(user)) {
      if (!mounted) return;
      setState(() {
        _unlockChecked = true;
        _unlockAllowed = false;
      });
      return;
    }
    final allowed = await ensureAdminSettingsUnlocked(context);
    if (!mounted) return;
    setState(() {
      _unlockChecked = true;
      _unlockAllowed = allowed;
    });
  }

  String _levelLabel(AppLocalizations l10n, AppLogLevel level) {
    return switch (level) {
      AppLogLevel.debug => l10n.settingsLogLevelDebug,
      AppLogLevel.info => l10n.settingsLogLevelInfo,
      AppLogLevel.warning => l10n.settingsLogLevelWarning,
      AppLogLevel.error => l10n.settingsLogLevelError,
    };
  }

  String _categoryLabel(AppLocalizations l10n, AppLogCategory category) {
    return switch (category) {
      AppLogCategory.general => l10n.settingsLogCategoryAll,
      AppLogCategory.network => l10n.settingsLogCategoryNetwork,
      AppLogCategory.authentication => l10n.settingsLogCategoryAuth,
      AppLogCategory.synchronization => l10n.settingsLogCategorySync,
      AppLogCategory.error => l10n.settingsLogLevelError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthCubit>().state.user;
    if (!ServerManagementPage.canAccess(user)) {
      final denied = Center(child: Text(l10n.serverMgmtAccessDenied));
      if (widget.embedded) return denied;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsAdminLogs)),
        body: denied,
      );
    }

    if (!_unlockChecked) {
      const loading = Center(child: CircularProgressIndicator());
      if (widget.embedded) return loading;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsAdminLogs)),
        body: loading,
      );
    }

    if (!_unlockAllowed) {
      final denied = Center(child: Text(l10n.serverMgmtAccessDenied));
      if (widget.embedded) return denied;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsAdminLogs)),
        body: denied,
      );
    }

    final logs = _buffer.filtered(
      query: _query,
      level: _level,
      category: _category,
    );

    final body = SettingsPageBody(
      embedded: widget.embedded,
      children: [
        SettingsCard(
          title: l10n.settingsAdminLogs,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.settingsSearchLogs,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text(l10n.settingsLogAll),
                    selected: _level == null,
                    onSelected: (_) => setState(() => _level = null),
                  ),
                  ...AppLogLevel.values.map(
                    (l) => FilterChip(
                      label: Text(_levelLabel(l10n, l)),
                      selected: _level == l,
                      onSelected: (_) => setState(() => _level = l),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text(l10n.settingsLogCategoryAll),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  ...[
                    AppLogCategory.network,
                    AppLogCategory.authentication,
                    AppLogCategory.synchronization,
                    AppLogCategory.error,
                  ].map(
                    (c) => FilterChip(
                      label: Text(_categoryLabel(l10n, c)),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final text =
                          logs.map((e) => e.toExportLine()).join('\n');
                      await Clipboard.setData(ClipboardData(text: text));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.settingsLogsCopied)),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.settingsCopyLogs),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final text =
                          logs.map((e) => e.toExportLine()).join('\n');
                      final dir = await getTemporaryDirectory();
                      final file = File(
                        '${dir.path}${Platform.pathSeparator}app_logs.txt',
                      );
                      await file.writeAsString(text);
                      await SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(file.path, mimeType: 'text/plain')],
                          subject: l10n.settingsAdminLogs,
                        ),
                      );
                    },
                    icon: const Icon(Icons.ios_share),
                    label: Text(l10n.settingsExportLogs),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _buffer.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.settingsClearLogs),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsCard(
          title: '${l10n.settingsLogEntries} (${logs.length})',
          child: logs.isEmpty
              ? Text(l10n.settingsNoLogs)
              : SizedBox(
                  height: 420,
                  child: ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = logs[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          e.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${e.timestamp.toLocal()} Â· ${e.levelLabel} Â· ${_categoryLabel(l10n, e.category)}',
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAdminLogs)),
      body: body,
    );
  }
}

// â”€â”€â”€ Developer options â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class DeveloperOptionsPage extends StatefulWidget {
  const DeveloperOptionsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DeveloperOptionsPage> createState() => _DeveloperOptionsPageState();
}

class _DeveloperOptionsPageState extends State<DeveloperOptionsPage> {
  bool _unlockChecked = false;
  bool _unlockAllowed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _gateUnlock());
  }

  Future<void> _gateUnlock() async {
    final user = context.read<AuthCubit>().state.user;
    if (!ServerManagementPage.canAccess(user)) {
      if (!mounted) return;
      setState(() {
        _unlockChecked = true;
        _unlockAllowed = false;
      });
      return;
    }
    final allowed = await ensureAdminSettingsUnlocked(context);
    if (!mounted) return;
    setState(() {
      _unlockChecked = true;
      _unlockAllowed = allowed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthCubit>().state.user;
    if (!ServerManagementPage.canAccess(user)) {
      final denied = Center(child: Text(l10n.serverMgmtAccessDenied));
      if (widget.embedded) return denied;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsDeveloperOptions)),
        body: denied,
      );
    }

    if (!_unlockChecked) {
      const loading = Center(child: CircularProgressIndicator());
      if (widget.embedded) return loading;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsDeveloperOptions)),
        body: loading,
      );
    }

    if (!_unlockAllowed) {
      final denied = Center(child: Text(l10n.serverMgmtAccessDenied));
      if (widget.embedded) return denied;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsDeveloperOptions)),
        body: denied,
      );
    }

    final body = SettingsPageBody(
      embedded: widget.embedded,
      children: [
        SettingsCard(
          title: l10n.settingsDeveloperOptions,
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.article_outlined,
                title: l10n.settingsAdminLogs,
                onTap: () => context.push(RoutePaths.settingsLogs),
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.flag_outlined,
                title: l10n.settingsFeatureFlags,
                subtitle: l10n.settingsReadOnly,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.settingsNoFeatureFlags)),
                  );
                },
              ),
              const Divider(height: 1),
              SettingsInfoRow(
                label: l10n.serverMgmtAppVersion,
                value: '${AppConfig.appVersion}+${AppConfig.buildNumber}',
              ),
              SettingsInfoRow(
                label: l10n.serverMgmtEnvironment,
                value: const String.fromEnvironment(
                  'ENV',
                  defaultValue: 'production',
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsDeveloperOptions)),
      body: body,
    );
  }
}
