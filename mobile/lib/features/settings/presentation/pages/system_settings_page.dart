import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/settings/presentation/cubit/settings_cubits.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

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
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settingsSystemStatus)),
        body: BlocBuilder<SystemInfoCubit, SystemInfoState>(
          builder: (context, state) {
            if (state.status == SystemInfoStatus.loading && state.info == null) {
              return AppLoader(message: l10n.settingsLoading);
            }
            if (state.status == SystemInfoStatus.failure && state.info == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message ?? l10n.settingsLoadFailed),
                    FilledButton(
                      onPressed: _cubit.load,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }

            final info = state.info;
            return Column(
              children: [
                AppRefreshBar(visible: state.isRefreshing),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _cubit.load,
                    child: ListView(
                      padding: AppScrollPadding.resolve(
                        context,
                        base: const EdgeInsets.all(AppSpacing.md),
                        chrome: AppBottomChrome.system,
                      ),
                      children: [
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.backup_outlined),
                                title: Text(l10n.settingsBackupRestore),
                                subtitle: Text(l10n.settingsUiOnly),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.settingsComingSoonAction,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.cached_outlined),
                                title: Text(l10n.settingsCacheManagement),
                                subtitle: Text(l10n.settingsUiOnly),
                                onTap: () async {
                                  await context
                                      .read<AppCubit>()
                                      .clearLocalCache();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.settingsCacheCleared),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.settingsSystemStatus,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Card(
                          child: Column(
                            children: [
                              _row(
                                l10n.settingsApiStatus,
                                info?.apiStatus ?? '-',
                              ),
                              const Divider(height: 1),
                              _row(
                                l10n.settingsDatabaseStatus,
                                info?.databaseStatus ?? '-',
                              ),
                              const Divider(height: 1),
                              _row(
                                l10n.settingsStorageUsage,
                                info?.storageUsage.note ??
                                    info?.storageUsage.provider ??
                                    '-',
                              ),
                              const Divider(height: 1),
                              _row(
                                l10n.settingsApiVersion,
                                info?.apiVersion ?? '-',
                              ),
                              const Divider(height: 1),
                              _row(
                                l10n.settingsBackendVersion,
                                info?.backendVersion ?? '-',
                              ),
                              const Divider(height: 1),
                              _row(
                                l10n.settingsAppVersion,
                                '${AppConfig.appName} 1.0.0',
                              ),
                              const Divider(height: 1),
                              _row(
                                l10n.settingsUptime,
                                '${info?.uptimeSeconds ?? 0}s',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          value,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    );
  }
}
