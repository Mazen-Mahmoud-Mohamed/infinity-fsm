import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/config/api_endpoint_service.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/localization/localize_rbac.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_sync_cubit.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';
import 'package:mobile/features/settings/domain/entities/server_management_entities.dart';
import 'package:mobile/features/settings/presentation/cubit/server_management_cubit.dart';
import 'package:mobile/features/settings/presentation/utils/server_management_unlock.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_layout.dart';

/// Admin-only runtime backend URL management + diagnostics.
class ServerManagementPage extends StatefulWidget {
  const ServerManagementPage({super.key, this.embedded = false});

  final bool embedded;

  static bool canAccess(CurrentUser? user) {
    if (user == null) return false;
    final isAdmin = user.roles.any((r) => r.toUpperCase() == 'ADMIN');
    return isAdmin || user.permissionChecker.canManageSettings();
  }

  @override
  State<ServerManagementPage> createState() => _ServerManagementPageState();
}

class _ServerManagementPageState extends State<ServerManagementPage> {
  late final ServerManagementCubit _cubit;
  late final TextEditingController _urlController;
  final _urlFocus = FocusNode();
  bool _unlockChecked = false;
  bool _unlockAllowed = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ServerManagementCubit>();
    _urlController = TextEditingController();
    final user = getIt<AuthCubit>().state.user;
    final pending = getIt<AttendanceSyncCubit>().state.pendingCount +
        getIt<OvertimeSyncCubit>().state.pendingCount;
    _cubit.configureContext(
      userRole: user?.primaryRole,
      userDisplayName: user?.fullName,
      pendingSyncCount: pending,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _gateUnlock());
  }

  Future<void> _gateUnlock() async {
    final allowed = await ensureAdminSettingsUnlocked(context);
    if (!mounted) return;
    setState(() {
      _unlockChecked = true;
      _unlockAllowed = allowed;
    });
    if (!allowed) return;
    await _cubit.load();
    if (!mounted) return;
    _urlController.text = _cubit.state.urlInput;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocus.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _pasteUrl() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _urlController.text = text;
    _urlController.selection = TextSelection.collapsed(offset: text.length);
    _cubit.applyPastedUrl(text);
  }

  Future<void> _copyUrl() async {
    final text = _urlController.text.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).serverMgmtCopyUrl)),
    );
  }

  void _clearUrl() {
    _urlController.clear();
    _cubit.clearUrl();
    _urlFocus.requestFocus();
  }

  Future<void> _copyServerInfo() async {
    await Clipboard.setData(ClipboardData(text: _cubit.buildCopyReport()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).serverMgmtCopySuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthCubit>().state.user;

    if (!ServerManagementPage.canAccess(user)) {
      final denied = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(l10n.serverMgmtAccessDenied),
        ),
      );
      if (widget.embedded) return denied;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.serverMgmtTitle)),
        body: denied,
      );
    }

    if (!_unlockChecked) {
      const loading = Center(child: CircularProgressIndicator());
      if (widget.embedded) return loading;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.serverMgmtTitle)),
        body: loading,
      );
    }

    if (!_unlockAllowed) {
      final denied = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(l10n.serverMgmtAccessDenied),
        ),
      );
      if (widget.embedded) return denied;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.serverMgmtTitle)),
        body: denied,
      );
    }

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ServerManagementCubit, ServerManagementState>(
        listenWhen: (p, c) =>
            (p.message != c.message && c.message != null) ||
            (p.urlInput != c.urlInput &&
                _urlController.text != c.urlInput &&
                (c.status == ServerManagementStatus.idle)),
        listener: (context, state) {
          if (_urlController.text != state.urlInput &&
              (state.status == ServerManagementStatus.idle)) {
            _urlController.value = TextEditingValue(
              text: state.urlInput,
              selection: TextSelection.collapsed(offset: state.urlInput.length),
            );
          }
          if (state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(localizeAppMessage(l10n, state.message)),
                ),
              );
            context.read<ServerManagementCubit>().clearFeedback();
          }
        },
        child: widget.embedded
            ? _buildBody(l10n)
            : Scaffold(
                appBar: AppBar(title: Text(l10n.serverMgmtTitle)),
                body: _buildBody(l10n),
              ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return BlocBuilder<ServerManagementCubit, ServerManagementState>(
      builder: (context, state) {
        final connectionCard = _ConnectionSettingsCard(
          controller: _urlController,
          focusNode: _urlFocus,
          state: state,
          onChanged: _cubit.onUrlChanged,
          onTest: state.isBusy ? null : _cubit.testConnection,
          onPing: state.isBusy ? null : _cubit.pingServer,
          onSave: state.isBusy ? null : _cubit.save,
          onRestore: state.isBusy ? null : _cubit.restoreDefault,
          onCopy: state.isBusy ? null : _copyUrl,
          onPaste: state.isBusy ? null : _pasteUrl,
          onClear: state.isBusy ? null : _clearUrl,
        );
        final infoCard = _CurrentServerCard(
          state: state,
          onRetry: state.isBusy ? null : _cubit.testConnection,
        );

        return SettingsPageBody(
          children: [
            SettingsResponsiveRow(
              left: connectionCard,
              right: infoCard,
            ),
            const SizedBox(height: AppSpacing.lg),
            _AdvancedDiagnosticsCard(
              diagnostics: state.diagnostics,
              connection: state.connectionTest,
              ping: state.pingResult,
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsActionBar(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, kSettingsControlHeight),
                  ),
                  onPressed: state.isBusy ? null : _copyServerInfo,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: Text(l10n.serverMgmtCopyServerInfo),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, kSettingsControlHeight),
                  ),
                  onPressed: state.isBusy ? null : _cubit.exportDiagnostics,
                  icon: state.status == ServerManagementStatus.exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_outlined),
                  label: Text(l10n.serverMgmtExportDiagnostics),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.serverMgmtFutureHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
        );
      },
    );
  }
}

class _ConnectionSettingsCard extends StatelessWidget {
  const _ConnectionSettingsCard({
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.onChanged,
    required this.onTest,
    required this.onPing,
    required this.onSave,
    required this.onRestore,
    required this.onCopy,
    required this.onPaste,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ServerManagementState state;
  final ValueChanged<String> onChanged;
  final VoidCallback? onTest;
  final VoidCallback? onPing;
  final VoidCallback? onSave;
  final VoidCallback? onRestore;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final testing = state.status == ServerManagementStatus.testing;
    final pinging = state.status == ServerManagementStatus.pinging;
    final saving = state.status == ServerManagementStatus.saving;

    return SettingsCard(
      title: l10n.serverMgmtConnectionSettings,
      leading: const Icon(Icons.settings_ethernet),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !state.isBusy,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableInteractiveSelection: true,
              onChanged: onChanged,
              decoration: InputDecoration(
                labelText: l10n.serverMgmtBackendUrl,
                hintText: 'https://infinity-fsm-api.onrender.com',
                helperText: l10n.serverMgmtUrlHelper,
                errorText: state.urlError != null
                    ? l10n.serverMgmtInvalidUrl
                    : null,
                prefixIcon: const Icon(Icons.dns_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsActionBar(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, kSettingsControlHeight),
                  ),
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: Text(l10n.serverMgmtCopyUrl),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, kSettingsControlHeight),
                  ),
                  onPressed: onPaste,
                  icon: const Icon(Icons.content_paste_outlined, size: 18),
                  label: Text(l10n.serverMgmtPasteUrl),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, kSettingsControlHeight),
                  ),
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_outlined, size: 18),
                  label: Text(l10n.serverMgmtClearUrl),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, kSettingsControlHeight),
                  ),
                  onPressed: onRestore,
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.serverMgmtRestoreDefault),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsActionBar(
              children: [
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, kSettingsControlHeight),
                  ),
                  onPressed: onTest,
                  icon: testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.health_and_safety_outlined),
                  label: Text(l10n.serverMgmtTestConnection),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, kSettingsControlHeight),
                  ),
                  onPressed: onPing,
                  icon: pinging
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_ping),
                  label: Text(l10n.serverMgmtPingServer),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, kSettingsControlHeight),
                  ),
                  onPressed: onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.serverMgmtSave),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _CurrentServerCard extends StatelessWidget {
  const _CurrentServerCard({required this.state, required this.onRetry});

  final ServerManagementState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final test = state.connectionTest;
    final ping = state.pingResult;
    final quality = ping?.quality ?? test?.quality;
    final unreachable = test?.connected == false ||
        (test == null && ping?.reachable == false);

    final latencyText = test != null && test.connected
        ? '${test.responseTimeMs} ms'
        : (ping?.averageMs != null
            ? '${ping!.averageMs!.round()} ms'
            : l10n.serverMgmtUnknown);

    return SettingsCard(
      title: l10n.serverMgmtServerInformation,
      leading: Icon(Icons.cloud_outlined, color: cs.primary),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    test?.serverName ??
                        (state.activeBaseUrl.isEmpty
                            ? l10n.serverMgmtUnknown
                            : ApiUrlNormalizer.serverDisplayName(
                                state.activeBaseUrl,
                              )),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (test != null)
                  _StatusBadge(
                    connected: test.connected,
                    label: test.connected
                        ? l10n.serverMgmtConnectedBadge
                        : l10n.serverMgmtServerUnreachable,
                  ),
              ],
            ),
            if (unreachable) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_outlined, color: cs.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        test?.errorMessage == 'timeout'
                            ? l10n.serverMgmtTimeout
                            : l10n.serverMgmtServerUnreachable,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onRetry,
                      child: Text(l10n.serverMgmtRetry),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (quality != null) _QualityChip(quality: quality),
                _EnvBadge(url: state.activeBaseUrl, environment: test?.environment),
                _MetaChip(
                  icon: Icons.tag,
                  label: '${l10n.serverMgmtVersion}: ${formatBackendVersion(test?.backendVersion)}',
                ),
                _MetaChip(
                  icon: Icons.speed,
                  label: '${l10n.serverMgmtLatency}: $latencyText',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoTile(
              icon: Icons.layers_outlined,
              label: l10n.serverMgmtEnvironment,
              value: formatEnvironmentLabel(test?.environment),
            ),
            _InfoTile(
              icon: Icons.link,
              label: l10n.serverMgmtApiUrlLabel,
              value: state.diagnostics?.currentApiUrl ?? state.activeBaseUrl,
              selectable: true,
            ),
            _InfoTile(
              icon: Icons.storage_outlined,
              label: l10n.serverMgmtDatabase,
              value: test?.databaseStatus ?? l10n.serverMgmtUnknown,
            ),
            _InfoTile(
              icon: Icons.public_outlined,
              label: l10n.serverMgmtRegion,
              value: (test?.region?.isNotEmpty == true)
                  ? test!.region!
                  : l10n.serverMgmtUnknown,
            ),
            _InfoTile(
              icon: Icons.timer_outlined,
              label: l10n.serverMgmtServerUptime,
              value: formatServerUptime(test?.serverUptimeSeconds),
            ),
            if (test?.connected == true) ...[
              const SizedBox(height: AppSpacing.sm),
              _InfoTile(
                icon: Icons.favorite_outline,
                label: l10n.serverMgmtHealth,
                value: test!.apiStatus ?? l10n.serverMgmtUnknown,
              ),
            ],
            if (ping?.reachable == true) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _MetaChip(
                    icon: Icons.trending_flat,
                    label:
                        '${l10n.serverMgmtAvgLatency}: ${ping!.averageMs!.round()} ms',
                  ),
                  _MetaChip(
                    icon: Icons.arrow_downward,
                    label: '${l10n.serverMgmtMinLatency}: ${ping.minMs} ms',
                  ),
                  _MetaChip(
                    icon: Icons.arrow_upward,
                    label: '${l10n.serverMgmtMaxLatency}: ${ping.maxMs} ms',
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _InfoTile(
              icon: Icons.history,
              label: l10n.serverMgmtLastSuccessful,
              value: state.diagnostics?.lastSuccessfulSync == null
                  ? l10n.serverMgmtUnknown
                  : AppFormatters.mediumDateTime(context).format(
                      state.diagnostics!.lastSuccessfulSync!,
                    ),
            ),
          ],
        ),
    );
  }
}

class _AdvancedDiagnosticsCard extends StatelessWidget {
  const _AdvancedDiagnosticsCard({
    required this.diagnostics,
    required this.connection,
    required this.ping,
  });

  final ServerDiagnosticsSnapshot? diagnostics;
  final ServerConnectionTestResult? connection;
  final ServerPingResult? ping;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = diagnostics;

    return SettingsCard(
      title: l10n.serverMgmtAdvancedDiagnostics,
      leading: const Icon(Icons.bug_report_outlined),
      child: d == null
          ? Text(l10n.serverMgmtStatusUnknown)
          : Column(
              children: [
                _DiagGroup(
                  icon: Icons.phone_android_outlined,
                  title: l10n.settingsDiagDevice,
                  rows: [
                    _DiagRow(l10n.serverMgmtAppVersion, d.appVersion),
                    _DiagRow(l10n.serverMgmtBuildNumber, d.buildNumber),
                    _DiagRow(l10n.serverMgmtPlatform, d.platform),
                    _DiagRow(
                      l10n.serverMgmtAndroidVersion,
                      d.androidVersion ?? l10n.serverMgmtUnknown,
                    ),
                    _DiagRow(
                      l10n.serverMgmtDeviceModel,
                      d.deviceModel ?? l10n.serverMgmtUnknown,
                    ),
                    _DiagRow(
                      l10n.serverMgmtDeviceLocalTime,
                      AppFormatters.mediumDateTime(context)
                          .format(d.deviceLocalTime),
                    ),
                    _DiagRow(l10n.serverMgmtDeviceTimezone, d.deviceTimezone),
                    _DiagRow(
                      l10n.serverMgmtAppUptime,
                      _formatDuration(d.appUptime),
                    ),
                  ],
                ),
                _DiagGroup(
                  icon: Icons.wifi_outlined,
                  title: l10n.settingsDiagNetwork,
                  rows: [
                    _DiagRow(l10n.serverMgmtNetworkType, d.networkType),
                    _DiagRow(
                      l10n.serverMgmtOnlineStatus,
                      d.isOnline
                          ? l10n.serverMgmtOnline
                          : l10n.serverMgmtOffline,
                    ),
                  ],
                ),
                _DiagGroup(
                  icon: Icons.dns_outlined,
                  title: l10n.settingsDiagServer,
                  rows: [
                    _DiagRow(
                      l10n.serverMgmtBackendVersion,
                      d.backendVersion ?? l10n.serverMgmtUnknown,
                    ),
                    _DiagRow(l10n.serverMgmtEnvironment, d.environmentLabel),
                    _DiagRow(
                      l10n.serverMgmtServerTime,
                      d.serverTime == null
                          ? l10n.serverMgmtUnknown
                          : AppFormatters.mediumDateTime(context)
                              .format(d.serverTime!),
                    ),
                    _DiagRow(
                      l10n.serverMgmtClockDifference,
                      d.clockDifference == null
                          ? l10n.serverMgmtUnknown
                          : '${d.clockDifference!.inSeconds}s',
                    ),
                  ],
                ),
                _DiagGroup(
                  icon: Icons.api_outlined,
                  title: l10n.settingsDiagApi,
                  rows: [
                    _DiagRow(l10n.serverMgmtCurrentApiUrl, d.currentApiUrl),
                    _DiagRow(
                      l10n.serverMgmtApiHealth,
                      _apiHealthLabel(l10n, d.apiHealth),
                    ),
                    _DiagRow(
                      l10n.serverMgmtRequestTimeout,
                      '${d.requestTimeoutSeconds}s',
                    ),
                  ],
                ),
                _DiagGroup(
                  icon: Icons.storage_outlined,
                  title: l10n.settingsDiagDatabase,
                  rows: [
                    _DiagRow(
                      l10n.serverMgmtDatabaseConnectivity,
                      d.databaseConnectivity,
                    ),
                  ],
                ),
                _DiagGroup(
                  icon: Icons.verified_user_outlined,
                  title: l10n.settingsDiagAuth,
                  rows: [
                    _DiagRow(
                      l10n.serverMgmtUserRole,
                      localizeRoleLabel(l10n, d.userRole),
                    ),
                  ],
                ),
                _DiagGroup(
                  icon: Icons.speed_outlined,
                  title: l10n.settingsDiagPerformance,
                  rows: [
                    _DiagRow(
                      l10n.serverMgmtAvgLatency,
                      d.averageLatencyMs == null
                          ? l10n.serverMgmtUnknown
                          : '${d.averageLatencyMs!.round()} ms',
                    ),
                    _DiagRow(
                      l10n.serverMgmtMinLatency,
                      d.minLatencyMs == null
                          ? l10n.serverMgmtUnknown
                          : '${d.minLatencyMs} ms',
                    ),
                    _DiagRow(
                      l10n.serverMgmtMaxLatency,
                      d.maxLatencyMs == null
                          ? l10n.serverMgmtUnknown
                          : '${d.maxLatencyMs} ms',
                    ),
                    _DiagRow(
                      l10n.serverMgmtPendingSyncQueue,
                      '${d.pendingSyncCount}',
                    ),
                    _DiagRow(
                      l10n.serverMgmtLastSuccessfulSync,
                      d.lastSuccessfulSync == null
                          ? l10n.serverMgmtUnknown
                          : AppFormatters.mediumDateTime(context)
                              .format(d.lastSuccessfulSync!),
                    ),
                    _DiagRow(
                      l10n.serverMgmtLastSuccessfulPing,
                      d.lastSuccessfulPing == null
                          ? l10n.serverMgmtUnknown
                          : AppFormatters.mediumDateTime(context)
                              .format(d.lastSuccessfulPing!),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${AppConfig.appName} · ${AppConfig.companyName}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}

class _EnvBadge extends StatelessWidget {
  const _EnvBadge({required this.url, this.environment});

  final String url;
  final String? environment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final lower = url.toLowerCase();
    final envLower = (environment ?? '').toLowerCase();
    final chips = <Widget>[];

    if (lower.startsWith('https://')) {
      chips.add(
        Chip(
          avatar: Icon(Icons.lock_outline, size: 16, color: cs.primary),
          label: Text(l10n.serverMgmtBadgeHttps),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    final isLocal = lower.contains('localhost') ||
        lower.contains('127.0.0.1') ||
        RegExp(r'(^|[^0-9])10\.').hasMatch(lower) ||
        lower.contains('192.168.');
    final isDev = envLower.contains('dev') ||
        envLower.contains('staging') ||
        isLocal;
    chips.add(
      Chip(
        avatar: Icon(
          isLocal
              ? Icons.computer_outlined
              : (isDev ? Icons.science_outlined : Icons.cloud_done_outlined),
          size: 16,
          color: cs.secondary,
        ),
        label: Text(
          isLocal
              ? l10n.serverMgmtBadgeLocal
              : (isDev
                  ? l10n.serverMgmtBadgeDevelopment
                  : l10n.serverMgmtBadgeProduction),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.connected, required this.label});

  final bool connected;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = connected
        ? cs.primaryContainer
        : cs.errorContainer;
    final fg = connected ? cs.onPrimaryContainer : cs.onErrorContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connected ? Icons.check_circle : Icons.error_outline,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  const _QualityChip({required this.quality});

  final ConnectionQuality quality;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final (color, label) = switch (quality) {
      ConnectionQuality.excellent => (cs.primary, l10n.serverMgmtQualityExcellent),
      ConnectionQuality.good => (const Color(0xFF16A34A), l10n.serverMgmtQualityGood),
      ConnectionQuality.fair => (const Color(0xFFF59E0B), l10n.serverMgmtQualityFair),
      ConnectionQuality.slow => (const Color(0xFFEA580C), l10n.serverMgmtQualitySlow),
      ConnectionQuality.poor => (cs.error, l10n.serverMgmtQualityPoor),
      ConnectionQuality.unreachable => (cs.error, l10n.serverMgmtQualityUnreachable),
    };

    return Chip(
      avatar: Icon(Icons.network_check, size: 16, color: color),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.45)),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 16, color: cs.primary),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DiagGroup extends StatelessWidget {
  const _DiagGroup({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<_DiagRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        leading: Icon(icon, size: 20),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        children: rows,
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  const _DiagRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _apiHealthLabel(AppLocalizations l10n, ApiHealthStatus s) {
  return switch (s) {
    ApiHealthStatus.healthy => l10n.serverMgmtHealthHealthy,
    ApiHealthStatus.warning => l10n.serverMgmtHealthWarning,
    ApiHealthStatus.error => l10n.serverMgmtHealthError,
    ApiHealthStatus.unknown => l10n.serverMgmtUnknown,
  };
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${s}s';
  return '${s}s';
}
