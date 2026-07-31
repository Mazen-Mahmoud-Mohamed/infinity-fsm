import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/domain/entities/asset_category.dart';
import 'package:mobile/features/assets/presentation/cubit/asset_detail_form_history_cubits.dart';
import 'package:mobile/features/organization/domain/entities/branch.dart';

class AssetFormPage extends StatefulWidget {
  const AssetFormPage({super.key, this.assetId});

  final String? assetId;

  @override
  State<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<AssetFormPage> {
  late final AssetFormCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _serialController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _customerController = TextEditingController();
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  final _qrController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _notesController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  AssetStatus _status = AssetStatus.active;
  String? _categoryId;
  String? _branchId;
  DateTime? _installationDate;
  DateTime? _warrantyExpiry;
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _existingImageUrl;
  bool _removeImage = false;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<AssetFormCubit>(param1: widget.assetId ?? '')..load();
  }

  @override
  void dispose() {
    _cubit.close();
    _numberController.dispose();
    _nameController.dispose();
    _serialController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _customerController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _qrController.dispose();
    _barcodeController.dispose();
    _notesController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _hydrate(Asset asset) {
    if (_hydrated) return;
    _hydrated = true;
    _numberController.text = asset.assetNumber;
    _nameController.text = asset.name;
    _serialController.text = asset.serialNumber ?? '';
    _manufacturerController.text = asset.manufacturer ?? '';
    _modelController.text = asset.model ?? '';
    _customerController.text = asset.customer ?? '';
    _regionController.text = asset.location.regionName ?? '';
    _cityController.text = asset.location.cityName ?? '';
    _qrController.text = asset.qrCode ?? '';
    _barcodeController.text = asset.barcode ?? '';
    _notesController.text = asset.notes ?? '';
    _latController.text = asset.gps.latitude?.toString() ?? '';
    _lngController.text = asset.gps.longitude?.toString() ?? '';
    _status = asset.status;
    _categoryId = asset.category?.id;
    _branchId = asset.location.branchId;
    _installationDate = asset.installationDate;
    _warrantyExpiry = asset.warrantyExpiry;
    _existingImageUrl = asset.image?.url;
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageFileName = file.name;
      _removeImage = false;
    });
  }

  Future<void> _pickDate({required bool installation}) async {
    final initial = installation
        ? (_installationDate ?? DateTime.now())
        : (_warrantyExpiry ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (installation) {
        _installationDate = picked;
      } else {
        _warrantyExpiry = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final input = AssetUpsertInput(
      assetNumber: _numberController.text.trim(),
      name: _nameController.text.trim(),
      categoryId: _categoryId,
      serialNumber: _serialController.text.trim().isEmpty
          ? null
          : _serialController.text.trim(),
      manufacturer: _manufacturerController.text.trim().isEmpty
          ? null
          : _manufacturerController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      installationDate: _installationDate,
      warrantyExpiry: _warrantyExpiry,
      status: _status,
      branchId: _branchId,
      regionName: _regionController.text.trim().isEmpty
          ? null
          : _regionController.text.trim(),
      cityName: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      gps: AssetGps(
        latitude: double.tryParse(_latController.text.trim()),
        longitude: double.tryParse(_lngController.text.trim()),
      ),
      qrCode:
          _qrController.text.trim().isEmpty ? null : _qrController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      customer: _customerController.text.trim().isEmpty
          ? null
          : _customerController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      removeImage: _removeImage,
      image: _imageBytes == null
          ? null
          : AssetImageInput(
              bytes: _imageBytes!,
              fileName: _imageFileName ?? 'asset.jpg',
              mimeType: 'image/jpeg',
            ),
    );

    final result = await _cubit.save(input);
    if (!mounted) return;
    switch (result) {
      case Success():
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
    final isEditing = widget.assetId != null && widget.assetId!.isNotEmpty;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? l10n.assetsEdit : l10n.assetsCreate),
          actions: [
            IconButton(
              tooltip: l10n.assetsScanQr,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () async {
                final result = await _cubit.scanQr();
                if (!mounted) return;
                switch (result) {
                  case Success(data: final code):
                    setState(() => _qrController.text = code);
                  case Failure(message: final message):
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizeAppMessage(l10n, message))),
                    );
                }
              },
            ),
          ],
        ),
        body: BlocConsumer<AssetFormCubit, AssetFormState>(
          listener: (context, state) {
            if (state.asset != null) _hydrate(state.asset!);
          },
          builder: (context, state) {
            if (state.status == AssetFormStatus.loading ||
                (isEditing && state.status == AssetFormStatus.initial)) {
              return const AppLoader();
            }
            if (state.status == AssetFormStatus.failure &&
                state.asset == null &&
                isEditing) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message ?? l10n.assetsLoadFailed),
                    FilledButton(
                      onPressed: _cubit.load,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }

            return Form(
              key: _formKey,
              child: AppBottomSafeListView(
                basePadding: const EdgeInsets.all(AppSpacing.md),
                chrome: AppBottomChrome.system,
                children: [
                  TextFormField(
                    controller: _numberController,
                    decoration: InputDecoration(labelText: l10n.assetsNumber),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.assetsRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l10n.assetsName),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.assetsRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String?>(
                    initialValue: _categoryId,
                    decoration: InputDecoration(labelText: l10n.assetsCategory),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.assetsFilterAll),
                      ),
                      ...state.categories.map(
                        (AssetCategory c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<AssetStatus>(
                    initialValue: _status,
                    decoration: InputDecoration(labelText: l10n.assetsStatus),
                    items: AssetStatus.values
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.apiValue),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _serialController,
                    decoration:
                        InputDecoration(labelText: l10n.assetsSerialNumber),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _manufacturerController,
                    decoration:
                        InputDecoration(labelText: l10n.assetsManufacturer),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _modelController,
                    decoration: InputDecoration(labelText: l10n.assetsModel),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _customerController,
                    decoration: InputDecoration(labelText: l10n.assetsCustomer),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.assetsInstallationDate),
                    subtitle: Text(
                      _installationDate?.toLocal().toString().split(' ').first ??
                          '—',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(installation: true),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.assetsWarrantyExpiry),
                    subtitle: Text(
                      _warrantyExpiry?.toLocal().toString().split(' ').first ??
                          '—',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(installation: false),
                    ),
                  ),
                  DropdownButtonFormField<String?>(
                    initialValue: _branchId,
                    decoration: InputDecoration(labelText: l10n.assetsBranch),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.assetsFilterAll),
                      ),
                      ...state.branches.map(
                        (Branch b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _branchId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _regionController,
                    decoration: InputDecoration(labelText: l10n.assetsRegion),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(labelText: l10n.assetsCity),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          decoration:
                              InputDecoration(labelText: l10n.assetsLatitude),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          decoration:
                              InputDecoration(labelText: l10n.assetsLongitude),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _qrController,
                    decoration: InputDecoration(labelText: l10n.assetsQrCode),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _barcodeController,
                    decoration: InputDecoration(labelText: l10n.assetsBarcode),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(labelText: l10n.assetsNotes),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_imageBytes != null)
                    Image.memory(_imageBytes!, height: 160, fit: BoxFit.cover)
                  else if (_existingImageUrl != null && !_removeImage)
                    AppCachedNetworkImage(
                      imageUrl: _existingImageUrl!,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_outlined),
                        label: Text(l10n.assetsAddPhoto),
                      ),
                      if (_existingImageUrl != null || _imageBytes != null)
                        TextButton(
                          onPressed: () => setState(() {
                            _imageBytes = null;
                            _existingImageUrl = null;
                            _removeImage = true;
                          }),
                          child: Text(l10n.assetsRemovePhoto),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed:
                        state.status == AssetFormStatus.saving ? null : _submit,
                    child: state.status == AssetFormStatus.saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.assetsSave),
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
