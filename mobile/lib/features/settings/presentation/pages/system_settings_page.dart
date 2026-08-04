import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/features/settings/presentation/cubit/settings_cubits.dart';
import 'package:mobile/features/settings/presentation/utils/server_management_unlock.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_layout.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  late final SystemInfoCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<SystemInfoCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: widget.embedded
          ? _buildBody(l10n)
          : Scaffold(
              appBar: AppBar(title: Text(l10n.settingsSystemStatus)),
              body: _buildBody(l10n),
            ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return BlocBuilder<SystemInfoCubit, SystemInfoState>(
      builder: (context, state) {
        if (state.status == SystemInfoStatus.loading && state.info == null) {
          return AppLoader(message: l10n.settingsLoading);
        }
        if (state.status == SystemInfoStatus.failure && state.info == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.settingsLoadFailed,
                        ),
                FilledButton(
                  onPressed: _cubit.load,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          );
        }

        final info = state.info;
        return RefreshIndicator(
          onRefresh: _cubit.load,
          child: SettingsPageBody(
            embedded: widget.embedded,
            children: [
              if (state.isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              SettingsCard(
                title: l10n.settingsCacheManagement,
                leading: const Icon(Icons.tune_outlined),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.backup_outlined),
                      title: Text(l10n.settingsBackupRestore),
                      subtitle: Text(l10n.settingsUiOnly),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.settingsComingSoonAction),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cached_outlined),
                      title: Text(l10n.settingsCacheManagement),
                      subtitle: Text(l10n.settingsUiOnly),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await context.read<AppCubit>().clearLocalCache();
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.settingsCacheCleared)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Long-press System Status card → Server Management (admin gate).
              GestureDetector(
                onLongPress: () => openServerManagementSecurely(context),
                child: SettingsCard(
                  title: l10n.settingsSystemStatus,
                  subtitle: l10n.serverMgmtUnlockHint,
                  leading: const Icon(Icons.monitor_heart_outlined),
                  child: Column(
                    children: [
                      SettingsInfoRow(
                        label: l10n.settingsApiStatus,
                        value: info?.apiStatus ?? '-',
                      ),
                      SettingsInfoRow(
                        label: l10n.settingsDatabaseStatus,
                        value: info?.databaseStatus ?? '-',
                      ),
                      SettingsInfoRow(
                        label: l10n.settingsStorageUsage,
                        value: info?.storageUsage.note ??
                            info?.storageUsage.provider ??
                            '-',
                      ),
                      SettingsInfoRow(
                        label: l10n.settingsApiVersion,
                        value: info?.apiVersion ?? '-',
                      ),
                      SettingsInfoRow(
                        label: l10n.settingsBackendVersion,
                        value: info?.backendVersion ?? '-',
                      ),
                      SettingsInfoRow(
                        label: l10n.settingsAppVersion,
                        value:
                            '${AppConfig.appName} ${AppConfig.appVersion}',
                      ),
                      SettingsInfoRow(
                        label: l10n.settingsUptime,
                        value: '${info?.uptimeSeconds ?? 0}s',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
