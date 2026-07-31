import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';
import 'package:mobile/features/service_reports/presentation/cubit/service_reports_cubits.dart';
import 'package:mobile/features/service_reports/presentation/widgets/signature_pad.dart';

class CustomerSignaturePage extends StatefulWidget {
  const CustomerSignaturePage({super.key});

  @override
  State<CustomerSignaturePage> createState() => _CustomerSignaturePageState();
}

class _CustomerSignaturePageState extends State<CustomerSignaturePage> {
  late final SignatureCaptureCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _signatureController = SignaturePadController();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _workOrderNumberController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<SignatureCaptureCubit>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _workOrderNumberController.dispose();
    _notesController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (!_signatureController.hasStroke) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportsSignatureRequired)),
      );
      return;
    }

    final bytes = await _signatureController.toPngBytes();
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportsSignatureRequired)),
      );
      return;
    }

    final result = await _cubit.save(
      CreateSignatureInput(
        customerName: _nameController.text.trim(),
        customerPosition: _positionController.text.trim().isEmpty
            ? null
            : _positionController.text.trim(),
        workOrderNumber: _workOrderNumberController.text.trim().isEmpty
            ? null
            : _workOrderNumberController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        signatureBytes: bytes,
      ),
    );

    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportsSignatureSaved)),
        );
        Navigator.of(context).pop(true);
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final padHeight = width < 600 ? 220.0 : 280.0;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.reportsCaptureSignature)),
        body: BlocBuilder<SignatureCaptureCubit, SignatureCaptureState>(
          builder: (context, state) {
            final saving = state.status == SignatureCaptureStatus.saving;
            return Form(
              key: _formKey,
              child: AppBottomSafeListView(
                basePadding: const EdgeInsets.all(AppSpacing.md),
                chrome: AppBottomChrome.system,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        InputDecoration(labelText: l10n.reportsCustomerName),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.reportsRequired : null,
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _positionController,
                    decoration: InputDecoration(
                      labelText: l10n.reportsCustomerPosition,
                    ),
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _workOrderNumberController,
                    decoration: InputDecoration(
                      labelText: l10n.reportsWorkOrderNumberOptional,
                    ),
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(labelText: l10n.reportsNotes),
                    maxLines: 3,
                    enabled: !saving,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.reportsCustomerSignature,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  IgnorePointer(
                    ignoring: saving,
                    child: SignaturePad(
                      controller: _signatureController,
                      height: padHeight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: saving ? null : _save,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(l10n.reportsSaveSignature),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
