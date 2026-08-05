import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
    builder: (ctx) => _OvertimeExportFiltersDialog(
      initial: initialFilters ?? const OvertimeExportFilters(),
    ),
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
  late final TextEditingController _search =
      TextEditingController(text: widget.initial.search ?? '');
  late final TextEditingController _userId =
      TextEditingController(text: widget.initial.userId ?? '');
  late final TextEditingController _departmentId =
      TextEditingController(text: widget.initial.departmentId ?? '');
  late final TextEditingController _branchId =
      TextEditingController(text: widget.initial.branchId ?? '');

  @override
  void dispose() {
    _search.dispose();
    _userId.dispose();
    _departmentId.dispose();
    _branchId.dispose();
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
      userId: _userId.text.trim().isEmpty ? null : _userId.text.trim(),
      departmentId: _departmentId.text.trim().isEmpty
          ? null
          : _departmentId.text.trim(),
      branchId: _branchId.text.trim().isEmpty ? null : _branchId.text.trim(),
      mode: _mode,
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
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _userId,
                decoration: InputDecoration(
                  labelText: l10n.overtimeExportEmployeeId,
                  hintText: l10n.overtimeExportOptionalIdHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _departmentId,
                decoration: InputDecoration(
                  labelText: l10n.overtimeExportDepartmentId,
                  hintText: l10n.overtimeExportOptionalIdHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _branchId,
                decoration: InputDecoration(
                  labelText: l10n.overtimeExportBranchId,
                  hintText: l10n.overtimeExportOptionalIdHint,
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

class _OvertimeExportReadyDialog extends StatelessWidget {
  const _OvertimeExportReadyDialog({
    required this.file,
    required this.export,
  });

  final File file;
  final OvertimeExcelExportResult export;

  Future<void> _share(BuildContext context) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: exportMime)],
        subject: export.fileName,
      ),
    );
  }

  Future<void> _openFile() async {
    if (kIsWeb) return;
    if (Platform.isWindows) {
      await Process.start('explorer', [file.path], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.start('open', [file.path]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [file.path]);
    } else {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: exportMime)]),
      );
    }
  }

  Future<void> _openFolder() async {
    if (kIsWeb) return;
    final folder = file.parent.path;
    if (Platform.isWindows) {
      await Process.start('explorer', ['/select,', file.path], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.start('open', ['-R', file.path]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [folder]);
    }
  }

  Future<void> _saveAs(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dest = File(p.join(docs.path, export.fileName));
      await dest.writeAsBytes(export.bytes, flush: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.overtimeExportSavedTo(dest.path))),
      );
    } on Object {
      if (!context.mounted) return;
      await _share(context);
    }
  }

  static const exportMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDesktop = AppBreakpoints.isDesktopOf(context);
    final rows = export.rowCount;

    return AlertDialog(
      title: Text(l10n.overtimeExportReady),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(export.fileName),
          if (rows != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.overtimeExportRowCount(rows)),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
        if (isDesktop) ...[
          TextButton(
            onPressed: _openFolder,
            child: Text(l10n.overtimeExportOpenFolder),
          ),
          TextButton(
            onPressed: _openFile,
            child: Text(l10n.overtimeExportOpenFile),
          ),
          FilledButton(
            onPressed: () => _saveAs(context),
            child: Text(l10n.overtimeExportSaveAs),
          ),
        ] else ...[
          TextButton(
            onPressed: () => _saveAs(context),
            child: Text(l10n.overtimeExportSave),
          ),
          TextButton(
            onPressed: _openFile,
            child: Text(l10n.overtimeExportOpen),
          ),
          FilledButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.share_outlined),
            label: Text(l10n.overtimeExportShare),
          ),
        ],
      ],
    );
  }
}
