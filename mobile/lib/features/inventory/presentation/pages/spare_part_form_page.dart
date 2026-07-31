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
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/inventory/presentation/cubit/spare_part_form_cubit.dart';

class SparePartFormPage extends StatefulWidget {
  const SparePartFormPage({super.key, this.partId});

  final String? partId;

  @override
  State<SparePartFormPage> createState() => _SparePartFormPageState();
}

class _SparePartFormPageState extends State<SparePartFormPage> {
  late final SparePartFormCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _partNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  final _currentQtyController = TextEditingController(text: '0');
  final _minQtyController = TextEditingController(text: '0');
  final _barcodeController = TextEditingController();
  bool _isActive = true;
  bool _removeImage = false;
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _existingImageUrl;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<SparePartFormCubit>(param1: widget.partId ?? '')..load();
  }

  @override
  void dispose() {
    _cubit.close();
    _partNumberController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _currentQtyController.dispose();
    _minQtyController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _hydrate(SparePart part) {
    if (_hydrated) return;
    _hydrated = true;
    _partNumberController.text = part.partNumber;
    _nameController.text = part.name;
    _categoryController.text = part.category ?? '';
    _descriptionController.text = part.description ?? '';
    _unitController.text = part.unit;
    _minQtyController.text = part.minimumQuantity.toString();
    _barcodeController.text = part.barcode ?? '';
    _isActive = part.isActive;
    _existingImageUrl = part.image?.url;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    final isEditing = widget.partId != null && widget.partId!.isNotEmpty;
    final input = SparePartUpsertInput(
      partNumber: _partNumberController.text.trim(),
      name: _nameController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      unit: _unitController.text.trim().isEmpty
          ? 'pcs'
          : _unitController.text.trim(),
      currentQuantity: isEditing
          ? null
          : double.tryParse(_currentQtyController.text.trim()) ?? 0,
      minimumQuantity: double.tryParse(_minQtyController.text.trim()) ?? 0,
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      isActive: _isActive,
      removeImage: _removeImage,
      image: _imageBytes == null
          ? null
          : SparePartImageInput(
              bytes: _imageBytes!,
              fileName: _imageFileName ?? 'part.jpg',
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
    final isEditing = widget.partId != null && widget.partId!.isNotEmpty;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing ? l10n.inventoryEditPart : l10n.inventoryCreatePart,
          ),
        ),
        body: BlocConsumer<SparePartFormCubit, SparePartFormState>(
          listener: (context, state) {
            if (state.part != null) {
              _hydrate(state.part!);
            }
          },
          builder: (context, state) {
            if (state.status == SparePartFormStatus.loading ||
                (isEditing &&
                    state.status == SparePartFormStatus.initial)) {
              return const AppLoader();
            }
            if (state.status == SparePartFormStatus.failure &&
                state.part == null &&
                isEditing) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message ?? l10n.inventoryLoadFailed),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => _cubit.load(),
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
                    controller: _partNumberController,
                    decoration:
                        InputDecoration(labelText: l10n.inventoryPartNumber),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? l10n.inventoryRequired
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l10n.inventoryName),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? l10n.inventoryRequired
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _categoryController,
                    decoration:
                        InputDecoration(labelText: l10n.inventoryCategory),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _unitController,
                    decoration: InputDecoration(labelText: l10n.inventoryUnit),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!isEditing)
                    TextFormField(
                      controller: _currentQtyController,
                      decoration: InputDecoration(
                        labelText: l10n.inventoryCurrentQuantity,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  if (!isEditing) const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _minQtyController,
                    decoration: InputDecoration(
                      labelText: l10n.inventoryMinimumQuantity,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _barcodeController,
                    decoration:
                        InputDecoration(labelText: l10n.inventoryBarcode),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descriptionController,
                    decoration:
                        InputDecoration(labelText: l10n.inventoryDescription),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.inventoryActive),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.inventoryImage,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_imageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (_existingImageUrl != null && !_removeImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppCachedNetworkImage(
                        imageUrl: _existingImageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_outlined),
                        label: Text(l10n.inventoryAddPhoto),
                      ),
                      if (_existingImageUrl != null || _imageBytes != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _imageBytes = null;
                              _imageFileName = null;
                              _removeImage = true;
                              _existingImageUrl = null;
                            });
                          },
                          child: Text(l10n.inventoryRemovePhoto),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: state.status == SparePartFormStatus.saving
                        ? null
                        : _submit,
                    child: state.status == SparePartFormStatus.saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.inventorySave),
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
