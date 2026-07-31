import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';
import 'package:mobile/features/service_reports/presentation/cubit/service_reports_cubits.dart';
import 'package:mobile/features/service_reports/presentation/widgets/service_report_preview_card.dart';

class ServiceReportGeneratePage extends StatefulWidget {
  const ServiceReportGeneratePage({super.key});

  @override
  State<ServiceReportGeneratePage> createState() =>
      _ServiceReportGeneratePageState();
}

class _ServiceReportGeneratePageState extends State<ServiceReportGeneratePage> {
  late final GenerateReportCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _jobNumberController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _assetNumberController = TextEditingController();
  final _assetNameController = TextEditingController();
  final _technicianNameController = TextEditingController();
  final _technicianNotesController = TextEditingController();
  final _customerNotesController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;
  String? _signatureId;
  ServiceReport? _preview;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<GenerateReportCubit>()..loadSignatures();
  }

  @override
  void dispose() {
    _jobNumberController.dispose();
    _jobTitleController.dispose();
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _assetNumberController.dispose();
    _assetNameController.dispose();
    _technicianNameController.dispose();
    _technicianNotesController.dispose();
    _customerNotesController.dispose();
    _durationController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _startTime : _endTime) ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _startTime = value;
      } else {
        _endTime = value;
      }
    });
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final input = GenerateServiceReportInput(
      signatureId: _signatureId,
      workOrder: ReportWorkOrderInfo(
        jobNumber: _jobNumberController.text.trim().isEmpty
            ? null
            : _jobNumberController.text.trim(),
        jobTitle: _jobTitleController.text.trim().isEmpty
            ? null
            : _jobTitleController.text.trim(),
        customerName: _customerNameController.text.trim().isEmpty
            ? null
            : _customerNameController.text.trim(),
        customerAddress: _customerAddressController.text.trim().isEmpty
            ? null
            : _customerAddressController.text.trim(),
      ),
      asset: ReportAssetInfo(
        assetNumber: _assetNumberController.text.trim().isEmpty
            ? null
            : _assetNumberController.text.trim(),
        name: _assetNameController.text.trim().isEmpty
            ? null
            : _assetNameController.text.trim(),
      ),
      technician: ReportTechnicianInfo(
        name: _technicianNameController.text.trim().isEmpty
            ? null
            : _technicianNameController.text.trim(),
      ),
      startTime: _startTime,
      endTime: _endTime,
      totalDurationMinutes: int.tryParse(_durationController.text.trim()),
      technicianNotes: _technicianNotesController.text.trim().isEmpty
          ? null
          : _technicianNotesController.text.trim(),
      customerNotes: _customerNotesController.text.trim().isEmpty
          ? null
          : _customerNotesController.text.trim(),
    );

    final result = await _cubit.generate(input);
    if (!mounted) return;
    switch (result) {
      case Success(data: final report):
        setState(() => _preview = report);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportsGeneratedSuccess)),
        );
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.reportsGenerate)),
        body: BlocBuilder<GenerateReportCubit, GenerateReportState>(
          builder: (context, state) {
            if (state.status == GenerateReportStatus.loadingSignatures) {
              return AppLoader(message: l10n.reportsLoading);
            }

            final generating =
                state.status == GenerateReportStatus.generating;

            return Form(
              key: _formKey,
              child: AppBottomSafeListView(
                basePadding: const EdgeInsets.all(AppSpacing.md),
                chrome: AppBottomChrome.system,
                children: [
                  Text(
                    l10n.reportsWorkOrderInfo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _jobNumberController,
                    decoration:
                        InputDecoration(labelText: l10n.reportsJobNumber),
                    enabled: !generating,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _jobTitleController,
                    decoration:
                        InputDecoration(labelText: l10n.reportsJobTitle),
                    enabled: !generating,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _customerNameController,
                    decoration:
                        InputDecoration(labelText: l10n.reportsCustomerName),
                    enabled: !generating,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _customerAddressController,
                    decoration: InputDecoration(
                      labelText: l10n.reportsCustomerAddress,
                    ),
                    enabled: !generating,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.reportsAssetInfo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _assetNumberController,
                    decoration:
                        InputDecoration(labelText: l10n.reportsAssetNumber),
                    enabled: !generating,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _assetNameController,
                    decoration:
                        InputDecoration(labelText: l10n.reportsAssetName),
                    enabled: !generating,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.reportsTechnician,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _technicianNameController,
                    decoration: InputDecoration(
                      labelText: l10n.reportsTechnicianName,
                    ),
                    enabled: !generating,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.reportsStartTime),
                    subtitle: Text(
                      _startTime?.toLocal().toString() ?? '—',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.schedule),
                      onPressed:
                          generating ? null : () => _pickDateTime(isStart: true),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.reportsEndTime),
                    subtitle: Text(_endTime?.toLocal().toString() ?? '—'),
                    trailing: IconButton(
                      icon: const Icon(Icons.schedule),
                      onPressed: generating
                          ? null
                          : () => _pickDateTime(isStart: false),
                    ),
                  ),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: l10n.reportsTotalDuration,
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !generating,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _technicianNotesController,
                    decoration: InputDecoration(
                      labelText: l10n.reportsTechnicianNotes,
                    ),
                    maxLines: 3,
                    enabled: !generating,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _customerNotesController,
                    decoration: InputDecoration(
                      labelText: l10n.reportsCustomerNotes,
                    ),
                    maxLines: 3,
                    enabled: !generating,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<String?>(
                    initialValue: _signatureId,
                    decoration: InputDecoration(
                      labelText: l10n.reportsCustomerSignature,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.reportsNone),
                      ),
                      ...state.signatures.map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            [
                              s.customerName,
                              if (s.customerPosition != null)
                                s.customerPosition!,
                            ].join(' · '),
                          ),
                        ),
                      ),
                    ],
                    onChanged: generating
                        ? null
                        : (v) => setState(() => _signatureId = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: generating
                        ? null
                        : () async {
                            final changed = await context
                                .push<bool>(RoutePaths.reportsSignature);
                            if (changed == true && mounted) {
                              await _cubit.loadSignatures();
                            }
                          },
                    child: Text(l10n.reportsCaptureSignature),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: generating ? null : _generate,
                    icon: generating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(l10n.reportsGenerate),
                  ),
                  if (_preview != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.reportsPreview,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ServiceReportPreviewCard(report: _preview!),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(
                        RoutePaths.reportDetail(_preview!.id),
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(l10n.reportsDetails),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
