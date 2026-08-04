import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/assets/domain/entities/asset_history.dart';
import 'package:mobile/features/assets/presentation/cubit/asset_detail_form_history_cubits.dart';
import 'package:mobile/features/assets/presentation/widgets/asset_history_tile.dart';
import 'package:mobile/features/assets/presentation/widgets/asset_status_badge.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';

class AssetDetailPage extends StatefulWidget {
  const AssetDetailPage({super.key, required this.assetId});

  final String assetId;

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  late final AssetDetailCubit _cubit;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<AssetDetailCubit>(param1: widget.assetId)..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _addHistoryEvent() async {
    final l10n = AppLocalizations.of(context);
    var type = AssetHistoryType.inspection;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.assetsAddHistory),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<AssetHistoryType>(
                      initialValue: type,
                      decoration:
                          InputDecoration(labelText: l10n.assetsHistoryType),
                      items: [
                        AssetHistoryType.installation,
                        AssetHistoryType.maintenance,
                        AssetHistoryType.repair,
                        AssetHistoryType.inspection,
                        AssetHistoryType.statusChange,
                      ]
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.apiValue),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => type = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: l10n.assetsTitle),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          InputDecoration(labelText: l10n.assetsDescription),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.assetsCancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final result = await _cubit.addHistory(
                      AssetHistoryCreateInput(
                        assetId: widget.assetId,
                        type: type,
                        title: titleController.text.trim().isEmpty
                            ? null
                            : titleController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        toStatus: type == AssetHistoryType.maintenance
                            ? 'MAINTENANCE'
                            : null,
                      ),
                    );
                    if (!dialogContext.mounted) return;
                    switch (result) {
                      case Success():
                        Navigator.of(dialogContext).pop(true);
                      case Failure(message: final message):
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(localizeAppMessage(l10n, message))),
                        );
                    }
                  },
                  child: Text(l10n.assetsSave),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    if (saved == true) _changed = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDate(context);
    final canUpdate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canUpdateAssets() == true,
    );
    final canDelete = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canDeleteAssets() == true,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: BlocProvider.value(
        value: _cubit,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.assetsDetails),
            actions: [
              IconButton(
                tooltip: l10n.assetsScanQr,
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () async {
                  final result = await _cubit.scanQr();
                  if (!context.mounted) return;
                  switch (result) {
                    case Success(data: final code):
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(code)),
                      );
                    case Failure(message: final message):
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(localizeAppMessage(l10n, message))),
                      );
                  }
                },
              ),
              if (canUpdate)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final changed = await context.push<bool>(
                      RoutePaths.assetsFormEdit(widget.assetId),
                    );
                    if (changed == true && mounted) {
                      _changed = true;
                      await _cubit.load();
                    }
                  },
                ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final result = await _cubit.delete();
                    if (!context.mounted) return;
                    switch (result) {
                      case Success():
                        Navigator.of(context).pop(true);
                      case Failure(message: final message):
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(localizeAppMessage(l10n, message))),
                        );
                    }
                  },
                ),
            ],
          ),
          body: BlocBuilder<AssetDetailCubit, AssetDetailState>(
            builder: (context, state) {
              if (state.status == AssetDetailStatus.loading ||
                  state.status == AssetDetailStatus.initial) {
                return AppLoader(message: l10n.assetsLoading);
              }
              if (state.status == AssetDetailStatus.failure ||
                  state.asset == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.assetsLoadFailed,
                        ),
                      FilledButton(
                        onPressed: _cubit.load,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              }

              final asset = state.asset!;
              return ListView(
                padding: AppScrollPadding.resolve(
                  context,
                  base: const EdgeInsets.all(AppSpacing.md),
                  chrome: AppBottomChrome.system,
                ),
                children: [
                  if (asset.image?.url != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: AppCachedNetworkImage(
                          imageUrl: asset.image!.url,
                          fit: BoxFit.cover,
                          errorIcon: Icons.image_not_supported,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          asset.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      AssetStatusBadge(status: asset.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${l10n.assetsNumber}: ${asset.assetNumber}'),
                  if (asset.category?.name != null)
                    Text('${l10n.assetsCategory}: ${asset.category!.name}'),
                  if (asset.serialNumber != null)
                    Text('${l10n.assetsSerialNumber}: ${asset.serialNumber}'),
                  if (asset.manufacturer != null)
                    Text('${l10n.assetsManufacturer}: ${asset.manufacturer}'),
                  if (asset.model != null)
                    Text('${l10n.assetsModel}: ${asset.model}'),
                  if (asset.customer != null)
                    Text('${l10n.assetsCustomer}: ${asset.customer}'),
                  if (asset.installationDate != null)
                    Text(
                      '${l10n.assetsInstallationDate}: ${dateFormat.format(asset.installationDate!.toLocal())}',
                    ),
                  if (asset.warrantyExpiry != null)
                    Text(
                      '${l10n.assetsWarrantyExpiry}: ${dateFormat.format(asset.warrantyExpiry!.toLocal())}',
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.assetsLocation,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    [
                      if (asset.location.branchName != null)
                        asset.location.branchName!,
                      if (asset.location.regionName != null)
                        asset.location.regionName!,
                      if (asset.location.cityName != null)
                        asset.location.cityName!,
                    ].join(' · ').ifEmpty(l10n.assetsNoLocation),
                  ),
                  if (asset.gps.hasCoordinates)
                    Text(
                      '${asset.gps.latitude}, ${asset.gps.longitude}',
                    ),
                  if (asset.qrCode != null)
                    Text('${l10n.assetsQrCode}: ${asset.qrCode}'),
                  if (asset.barcode != null)
                    Text('${l10n.assetsBarcode}: ${asset.barcode}'),
                  if (asset.notes != null && asset.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.assetsNotes,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(asset.notes!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Text(
                        l10n.assetsHistory,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (canUpdate)
                        TextButton(
                          onPressed: _addHistoryEvent,
                          child: Text(l10n.assetsAddHistory),
                        ),
                    ],
                  ),
                  if (state.history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(child: Text(l10n.assetsHistoryEmpty)),
                    )
                  else
                    ...state.history.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AssetHistoryTile(item: item),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      RoutePaths.assetsHistory,
                      extra: widget.assetId,
                    ),
                    icon: const Icon(Icons.history),
                    label: Text(l10n.assetsViewFullHistory),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
