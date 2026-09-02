import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_cubit.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_state.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_layout.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';

class UpdateCenterPage extends StatelessWidget {
  const UpdateCenterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final releaseChannel = context.read<AppCubit>().state.releaseChannel;

    return BlocProvider.value(
      value: getIt<UpdateCenterCubit>()
        ..bindReleaseChannel(releaseChannel)
        ..initialize(),
      child: _UpdateCenterView(embedded: embedded),
    );
  }
}

class _UpdateCenterView extends StatelessWidget {
  const _UpdateCenterView({required this.embedded});

  final bool embedded;

  String _statusLabel(AppLocalizations l10n, UpdateCenterState state) {
    if (state.autoUpdateEnabled || state.autoUpdateOwned) {
      return switch (state.status) {
        UpdateCenterStatus.downloading =>
          state.latestRelease == null
              ? l10n.settingsUpdateDownloading
              : l10n.settingsAutoUpdateDownloading(state.latestRelease!.version),
        UpdateCenterStatus.verifying => l10n.settingsAutoUpdateVerifying,
        UpdateCenterStatus.downloadReady => l10n.settingsAutoUpdateReady,
        UpdateCenterStatus.installing => l10n.settingsAutoUpdateInstalling,
        UpdateCenterStatus.downloadFailed => l10n.settingsAutoUpdateFailed,
        _ => state.autoUpdateEnabled
            ? l10n.settingsAutoUpdateStatusEnabled
            : _manualStatusLabel(l10n, state),
      };
    }
    return _manualStatusLabel(l10n, state);
  }

  String _manualStatusLabel(AppLocalizations l10n, UpdateCenterState state) {
    return switch (state.status) {
      UpdateCenterStatus.idle => l10n.settingsUpdateNeverChecked,
      UpdateCenterStatus.checking => l10n.settingsUpdateChecking,
      UpdateCenterStatus.upToDate => l10n.settingsUpdateUpToDate,
      UpdateCenterStatus.updateAvailable =>
        l10n.settingsUpdateAvailableVersion(state.latestRelease!.version),
      UpdateCenterStatus.aheadOfServer => l10n.settingsUpdateAheadOfServer,
      UpdateCenterStatus.platformUnavailable =>
        l10n.settingsUpdatePlatformUnavailable,
      UpdateCenterStatus.checkFailed => _checkFailureLabel(l10n, state.errorCode),
      UpdateCenterStatus.downloading => l10n.settingsUpdateDownloading,
      UpdateCenterStatus.verifying => l10n.settingsAutoUpdateVerifying,
      UpdateCenterStatus.downloadReady => l10n.appUpdateReadyToInstall,
      UpdateCenterStatus.downloadFailed => l10n.settingsUpdateDownloadFailed,
      UpdateCenterStatus.installing => l10n.settingsUpdateInstalling,
    };
  }

  String _checkFailureLabel(AppLocalizations l10n, String? errorCode) {
    return switch (errorCode) {
      'offline' => l10n.settingsUpdateOfflineCheck,
      'invalid_response' => l10n.settingsUpdateInvalidResponse,
      _ => l10n.settingsUpdateFailed,
    };
  }

  String _formatCheckedAt(BuildContext context, DateTime? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null) return l10n.settingsUpdateNeverChecked;
    return AppFormatters.mediumDateTime(context).format(value.toLocal());
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _showReleaseNotes(
    BuildContext context,
    UpdateCenterCubit cubit,
  ) async {
    final l10n = AppLocalizations.of(context);
    final notes = cubit.releaseNotes;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.settingsViewReleaseNotes),
          content: SingleChildScrollView(
            child: Text(
              notes ?? l10n.settingsUpdateReleaseNotesUnavailable,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<UpdateCenterCubit, UpdateCenterState>(
      builder: (context, state) {
        final channel = context.watch<AppCubit>().state.releaseChannel;
        final latestVersion =
            state.latestRelease?.version ?? l10n.settingsNotAvailable;
        final releaseDate = state.latestRelease?.releaseDate;
        final releaseDateLabel = releaseDate == null
            ? l10n.settingsNotAvailable
            : AppFormatters.mediumDateTime(context).format(releaseDate.toLocal());

        final body = SettingsPageBody(
          embedded: embedded,
          children: [
            SettingsCard(
              title: l10n.settingsAutoUpdate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.settingsAutoUpdate),
                    subtitle: Text(l10n.settingsAutoUpdateDescription),
                    value: state.autoUpdateEnabled,
                    onChanged: (value) => context
                        .read<UpdateCenterCubit>()
                        .setAutoUpdateEnabled(value),
                  ),
                  Text(
                    state.autoUpdateEnabled
                        ? l10n.settingsAutoUpdateEnabledHint
                        : l10n.settingsAutoUpdateDisabledHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            SettingsCard(
              title: l10n.settingsUpdateCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.settingsUpdateTestReleaseMarker,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsInfoRow(
                    label: l10n.serverMgmtAppVersion,
                    value: state.installedVersion.isEmpty
                        ? l10n.settingsNotAvailable
                        : state.installedVersion,
                  ),
                  SettingsInfoRow(
                    label: l10n.settingsLatestVersion,
                    value: latestVersion,
                  ),
                  SettingsInfoRow(
                    label: l10n.serverMgmtBuildNumber,
                    value: state.installedBuild > 0
                        ? '${state.installedBuild}'
                        : l10n.settingsNotAvailable,
                  ),
                  SettingsInfoRow(
                    label: l10n.settingsReleaseChannel,
                    value: channel,
                  ),
                  SettingsInfoRow(
                    label: l10n.settingsReleaseDate,
                    value: releaseDateLabel,
                  ),
                  SettingsInfoRow(
                    label: l10n.settingsUpdateLastChecked,
                    value: _formatCheckedAt(context, state.lastCheckedAt),
                  ),
                  SettingsInfoRow(
                    label: l10n.settingsUpdateStatus,
                    value: _statusLabel(l10n, state),
                  ),
                  if (state.status == UpdateCenterStatus.downloading ||
                      state.status == UpdateCenterStatus.verifying) ...[
                    const SizedBox(height: AppSpacing.sm),
                    if (state.downloadProgress != null)
                      LinearProgressIndicator(value: state.downloadProgress),
                    if (state.downloadReceivedBytes != null &&
                        state.downloadTotalBytes != null &&
                        state.downloadTotalBytes! > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_formatBytes(state.downloadReceivedBytes!)} / ${_formatBytes(state.downloadTotalBytes!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Chip(
                      avatar: Icon(
                        switch (state.status) {
                          UpdateCenterStatus.checking ||
                          UpdateCenterStatus.downloading ||
                          UpdateCenterStatus.verifying ||
                          UpdateCenterStatus.installing =>
                            Icons.hourglass_top,
                          UpdateCenterStatus.upToDate ||
                          UpdateCenterStatus.downloadReady =>
                            Icons.check_circle_outline,
                          UpdateCenterStatus.updateAvailable =>
                            Icons.system_update_alt,
                          UpdateCenterStatus.checkFailed ||
                          UpdateCenterStatus.downloadFailed =>
                            Icons.error_outline,
                          UpdateCenterStatus.aheadOfServer ||
                          UpdateCenterStatus.platformUnavailable =>
                            Icons.info_outline,
                          UpdateCenterStatus.idle => Icons.info_outline,
                        },
                        size: 18,
                      ),
                      label: Text(_statusLabel(l10n, state)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(kSettingsControlHeight),
                    ),
                    onPressed: state.isBusy
                        ? null
                        : () =>
                            context.read<UpdateCenterCubit>().checkForUpdates(),
                    icon: state.status == UpdateCenterStatus.checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.system_update_alt),
                    label: Text(l10n.settingsCheckForUpdates),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(kSettingsControlHeight),
                    ),
                    onPressed: state.latestRelease == null
                        ? null
                        : () => _showReleaseNotes(
                              context,
                              context.read<UpdateCenterCubit>(),
                            ),
                    child: Text(l10n.settingsViewReleaseNotes),
                  ),
                  if (state.status == UpdateCenterStatus.downloadFailed) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: state.isBusy
                          ? null
                          : () => context
                              .read<UpdateCenterCubit>()
                              .downloadUpdate(),
                      child: Text(l10n.appUpdateActionRetry),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (state.canInstall) ...[
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(kSettingsControlHeight),
                      ),
                      onPressed: state.isBusy
                          ? null
                          : () => context
                              .read<UpdateCenterCubit>()
                              .installDownloadedUpdate(),
                      child: Text(
                        state.platformKey == 'android'
                            ? l10n.settingsUpdateInstallAndroid
                            : l10n.settingsUpdateInstallAndRestart,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(kSettingsControlHeight),
                    ),
                    onPressed: state.canDownload
                        ? () => context
                            .read<UpdateCenterCubit>()
                            .downloadUpdate()
                        : null,
                    child: Text(l10n.settingsDownloadUpdate),
                  ),
                ],
              ),
            ),
          ],
        );

        if (embedded) return body;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsUpdateCenter)),
          body: body,
        );
      },
    );
  }
}
