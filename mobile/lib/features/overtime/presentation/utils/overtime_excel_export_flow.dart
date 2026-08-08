import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_export_filters.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/usecases/export_overtime_excel_usecase.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// True when the signed-in user may see Overtime Excel export (Admin/Supervisor).
bool canExportOvertimeExcel(CurrentUser? user) {
  if (user == null) return false;
  if (!user.canAccessExecutiveDashboard) return false;
  final perms = user.permissionChecker;
  return perms.canViewAllOvertime() || perms.canApproveOvertime();
}

Future<void> showOvertimeExcelExportFlow(
  BuildContext context, {
  OvertimeExportFilters? initialFilters,
}) async {
  final user = context.read<AuthCubit>().state.user;
  final l10n = AppLocalizations.of(context);
  if (!canExportOvertimeExcel(user)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.overtimeExportDenied)),
    );
    return;
  }

  final filters = await showDialog<OvertimeExportFilters>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final localeCode = context.read<AppCubit>().state.localeCode;
      final seed = initialFilters ?? const OvertimeExportFilters();
      return _OvertimeExportFiltersDialog(
        initial: OvertimeExportFilters(
          startDate: seed.startDate,
          endDate: seed.endDate,
          status: seed.status,
          type: seed.type,
          userId: seed.userId,
          search: seed.search,
          mode: seed.mode,
          language: initialFilters?.language ??
              OvertimeExportLanguage.fromLocaleCode(localeCode),
        ),
      );
    },
  );
  if (filters == null || !context.mounted) return;

  await _runExport(context, filters);
}

Future<void> _runExport(
  BuildContext context,
  OvertimeExportFilters filters,
) async {
  final l10n = AppLocalizations.of(context);
  final phase = ValueNotifier<String>(l10n.overtimeExportPreparing);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: ValueListenableBuilder<String>(
            valueListenable: phase,
            builder: (context, text, _) {
              return Row(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(text)),
                ],
              );
            },
          ),
        ),
      );
    },
  );

  try {
    phase.value = l10n.overtimeExportDownloading;
    final result = await getIt<ExportOvertimeExcelUseCase>()(filters);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    switch (result) {
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
      case Success(data: final export):
        phase.value = l10n.overtimeExportSaving;
        final file = await _writeExportFile(export);
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) =>
              _OvertimeExportReadyDialog(file: file, export: export),
        );
    }
  } on Object catch (error) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizeAppMessage(l10n, error.toString()),
          ),
        ),
      );
    }
  } finally {
    phase.dispose();
  }
}

Future<File> _writeExportFile(OvertimeExcelExportResult export) async {
  final dir = await getTemporaryDirectory();
  final path = p.join(dir.path, export.fileName);
  final file = File(path);
  await file.writeAsBytes(export.bytes, flush: true);
  return file;
}

class _OvertimeExportFiltersDialog extends StatefulWidget {
  const _OvertimeExportFiltersDialog({required this.initial});

  final OvertimeExportFilters initial;

  @override
  State<_OvertimeExportFiltersDialog> createState() =>
      _OvertimeExportFiltersDialogState();
}

class _OvertimeExportFiltersDialogState
    extends State<_OvertimeExportFiltersDialog> {
  late DateTime? _start = widget.initial.startDate;
  late DateTime? _end = widget.initial.endDate;
  late OvertimeStatus? _status = widget.initial.status;
  late OvertimeType? _type = widget.initial.type;
  late OvertimeExportMode _mode = widget.initial.mode;
  late OvertimeExportLanguage _language = widget.initial.language;
  late final TextEditingController _search =
      TextEditingController(text: widget.initial.search ?? '');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _start : _end) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  OvertimeExportFilters _buildFilters() {
    return OvertimeExportFilters(
      startDate: _start,
      endDate: _end,
      status: _status,
      type: _type,
      search: _search.text.trim().isEmpty ? null : _search.text.trim(),
      mode: _mode,
      language: _language,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDesktop = AppBreakpoints.isDesktopOf(context);
    final width = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      title: Text(l10n.overtimeExportExcel),
      content: SizedBox(
        width: isDesktop ? 520 : width * 0.92,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.overtimeExportFiltersHint),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.overtimeExportModeLabel,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ExportModeCard(
                selected: _mode == OvertimeExportMode.summary,
                title: l10n.overtimeExportModeSummary,
                subtitle: l10n.overtimeExportModeSummaryHint,
                icon: Icons.analytics_outlined,
                onTap: () =>
                    setState(() => _mode = OvertimeExportMode.summary),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ExportModeCard(
                selected: _mode == OvertimeExportMode.detailed,
                title: l10n.overtimeExportModeDetailed,
                subtitle: l10n.overtimeExportModeDetailedHint,
                icon: Icons.table_chart_outlined,
                onTap: () =>
                    setState(() => _mode = OvertimeExportMode.detailed),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<OvertimeExportLanguage>(
                // ignore: deprecated_member_use
                value: _language,
                decoration: InputDecoration(
                  labelText: l10n.overtimeExportReportLanguage,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: OvertimeExportLanguage.english,
                    child: Text(l10n.overtimeExportLanguageEnglish),
                  ),
                  DropdownMenuItem(
                    value: OvertimeExportLanguage.arabic,
                    child: Text(l10n.overtimeExportLanguageArabic),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _language = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _start == null
                          ? l10n.overtimeExportStartDate
                          : '${l10n.overtimeExportStartDate}: ${_start!.toIso8601String().substring(0, 10)}',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _end == null
                          ? l10n.overtimeExportEndDate
                          : '${l10n.overtimeExportEndDate}: ${_end!.toIso8601String().substring(0, 10)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<OvertimeStatus?>(
                // ignore: deprecated_member_use
                value: _status,
                decoration: InputDecoration(
                  labelText: l10n.overtimeStatusLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.overtimeExportAll),
                  ),
                  ...OvertimeStatus.values.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(overtimeStatusLabel(l10n, s)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<OvertimeType?>(
                // ignore: deprecated_member_use
                value: _type,
                decoration: InputDecoration(
                  labelText: l10n.labelType,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.overtimeExportAll),
                  ),
                  ...OvertimeType.values.map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(overtimeTypeLabel(l10n, t)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  labelText: l10n.overtimeSearchTechnician,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _buildFilters()),
          icon: const Icon(Icons.file_download_outlined),
          label: Text(l10n.overtimeExportGenerate),
        ),
      ],
    );
  }
}

class _ExportModeCard extends StatelessWidget {
  const _ExportModeCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.55)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OvertimeExportReadyDialog extends StatefulWidget {
  const _OvertimeExportReadyDialog({
    required this.file,
    required this.export,
  });

  final File file;
  final OvertimeExcelExportResult export;

  @override
  State<_OvertimeExportReadyDialog> createState() =>
      _OvertimeExportReadyDialogState();
}

class _OvertimeExportReadyDialogState extends State<_OvertimeExportReadyDialog> {
  static const exportMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  static const _xlsxTypeGroup = XTypeGroup(
    label: 'Excel',
    extensions: <String>['xlsx'],
    mimeTypes: <String>[
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ],
  );

  String? _statusMessage;
  bool _busy = false;

  File get file => widget.file;
  OvertimeExcelExportResult get export => widget.export;

  bool get _supportsNativeSaveAs =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: exportMime)],
        subject: export.fileName,
      ),
    );
  }

  Future<void> _openFile() async {
    final l10n = AppLocalizations.of(context);
    try {
      if (kIsWeb) return;
      final uri = Uri.file(file.path);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showError(l10n.overtimeExportOpenFailed);
      }
    } on Object {
      if (!mounted) return;
      _showError(l10n.overtimeExportOpenFailed);
    }
  }

  Future<void> _openFolder() async {
    final l10n = AppLocalizations.of(context);
    try {
      if (kIsWeb) return;
      final folder = file.parent.path;
      if (Platform.isWindows) {
        await Process.start(
          'explorer',
          <String>['/select,', file.path],
          runInShell: true,
        );
      } else if (Platform.isMacOS) {
        await Process.start('open', <String>['-R', file.path]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', <String>[folder]);
      }
    } on Object {
      if (!mounted) return;
      _showError(l10n.overtimeExportOpenFolderFailed);
    }
  }

  /// Native Save As (Windows/macOS/Linux). Cancel returns silently.
  Future<void> _saveAs() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);

    if (!_supportsNativeSaveAs) {
      await _share();
      return;
    }

    setState(() => _busy = true);
    try {
      final FileSaveLocation? location = await getSaveLocation(
        suggestedName: export.fileName,
        acceptedTypeGroups: const <XTypeGroup>[_xlsxTypeGroup],
        confirmButtonText: l10n.overtimeExportSaveAs,
      );
      if (!mounted) return;
      if (location == null) {
        // User cancelled — keep original temp file and stay on dialog.
        return;
      }

      var destPath = location.path;
      if (!destPath.toLowerCase().endsWith('.xlsx')) {
        destPath = '$destPath.xlsx';
      }

      // Prefer copying the generated file so temp stays intact on cancel/errors.
      if (await file.exists()) {
        await file.copy(destPath);
      } else {
        await File(destPath).writeAsBytes(export.bytes, flush: true);
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = l10n.overtimeExportSavedTo(destPath);
      });
    } on Object {
      if (!mounted) return;
      _showError(l10n.overtimeExportSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDesktop = AppBreakpoints.isDesktopOf(context);
    final rows = export.rowCount;
    final width = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      title: Text(l10n.overtimeExportReady),
      content: SizedBox(
        width: isDesktop ? 440 : width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.table_view_rounded,
                    color: scheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        export.fileName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (rows != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.overtimeExportRowCount(rows),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        if (isDesktop) ...[
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: _busy ? null : _openFolder,
            child: Text(l10n.overtimeExportOpenFolder),
          ),
          TextButton(
            onPressed: _busy ? null : _openFile,
            child: Text(l10n.overtimeExportOpenFile),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _saveAs,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_as_outlined, size: 18),
            label: Text(l10n.overtimeExportSaveAs),
          ),
        ] else ...[
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: _busy ? null : _openFile,
            child: Text(l10n.overtimeExportOpen),
          ),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    try {
                      await _share();
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            icon: const Icon(Icons.share_outlined),
            label: Text(l10n.overtimeExportShare),
          ),
        ],
      ],
    );
  }
}
