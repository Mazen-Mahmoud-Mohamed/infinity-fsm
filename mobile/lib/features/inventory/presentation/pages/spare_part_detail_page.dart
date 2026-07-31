import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/inventory/domain/entities/stock_movement.dart';
import 'package:mobile/features/inventory/domain/entities/warehouse.dart';
import 'package:mobile/features/inventory/presentation/cubit/spare_part_detail_cubit.dart';
import 'package:mobile/features/inventory/presentation/widgets/stock_status_badge.dart';

class SparePartDetailPage extends StatefulWidget {
  const SparePartDetailPage({super.key, required this.partId});

  final String partId;

  @override
  State<SparePartDetailPage> createState() => _SparePartDetailPageState();
}

class _SparePartDetailPageState extends State<SparePartDetailPage> {
  late final SparePartDetailCubit _cubit;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<SparePartDetailCubit>(param1: widget.partId)..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _formatQty(double value) {
    return AppFormatters.formatDecimalOrInt(context, value);
  }

  Future<void> _showStockDialog(StockMovementType type) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SparePartDetailCubit>();
    final warehouses = cubit.state.warehouses;
    if (warehouses.isEmpty && type != StockMovementType.transfer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inventoryNoWarehouses)),
      );
      return;
    }
    if (warehouses.length < 2 && type == StockMovementType.transfer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inventoryNeedTwoWarehouses)),
      );
      return;
    }

    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    Warehouse? warehouse = warehouses.isNotEmpty ? warehouses.first : null;
    Warehouse? fromWarehouse = warehouses.isNotEmpty ? warehouses.first : null;
    Warehouse? toWarehouse =
        warehouses.length > 1 ? warehouses[1] : null;
    var direction = AdjustmentDirection.increase;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final title = switch (type) {
              StockMovementType.stockIn => l10n.inventoryStockIn,
              StockMovementType.stockOut => l10n.inventoryStockOut,
              StockMovementType.transfer => l10n.inventoryTransfer,
              StockMovementType.adjustment => l10n.inventoryAdjustment,
            };
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (type == StockMovementType.transfer) ...[
                      DropdownButtonFormField<Warehouse>(
                        initialValue: fromWarehouse,
                        decoration: InputDecoration(
                          labelText: l10n.inventoryFromWarehouse,
                        ),
                        items: warehouses
                            .map(
                              (w) => DropdownMenuItem(
                                value: w,
                                child: Text('${w.name} (${w.code})'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => fromWarehouse = value),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<Warehouse>(
                        initialValue: toWarehouse,
                        decoration: InputDecoration(
                          labelText: l10n.inventoryToWarehouse,
                        ),
                        items: warehouses
                            .map(
                              (w) => DropdownMenuItem(
                                value: w,
                                child: Text('${w.name} (${w.code})'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => toWarehouse = value),
                      ),
                    ] else
                      DropdownButtonFormField<Warehouse>(
                        initialValue: warehouse,
                        decoration: InputDecoration(
                          labelText: l10n.inventoryWarehouse,
                        ),
                        items: warehouses
                            .map(
                              (w) => DropdownMenuItem(
                                value: w,
                                child: Text('${w.name} (${w.code})'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => warehouse = value),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    if (type == StockMovementType.adjustment)
                      DropdownButtonFormField<AdjustmentDirection>(
                        initialValue: direction,
                        decoration: InputDecoration(
                          labelText: l10n.inventoryDirection,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: AdjustmentDirection.increase,
                            child: Text(l10n.inventoryIncrease),
                          ),
                          DropdownMenuItem(
                            value: AdjustmentDirection.decrease,
                            child: Text(l10n.inventoryDecrease),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => direction = value);
                          }
                        },
                      ),
                    if (type == StockMovementType.adjustment)
                      const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: qtyController,
                      decoration: InputDecoration(
                        labelText: l10n.inventoryQuantity,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: l10n.inventoryReason,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: l10n.inventoryNotes,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.inventoryCancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final qty = double.tryParse(qtyController.text.trim());
                    if (qty == null || qty <= 0) return;

                    late final Result<StockMovementResult> result;
                    switch (type) {
                      case StockMovementType.stockIn:
                        if (warehouse == null) return;
                        result = await cubit.stockIn(
                          StockInInput(
                            sparePartId: widget.partId,
                            warehouseId: warehouse!.id,
                            quantity: qty,
                            reason: reasonController.text.trim().isEmpty
                                ? null
                                : reasonController.text.trim(),
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          ),
                        );
                      case StockMovementType.stockOut:
                        if (warehouse == null) return;
                        result = await cubit.stockOut(
                          StockOutInput(
                            sparePartId: widget.partId,
                            warehouseId: warehouse!.id,
                            quantity: qty,
                            reason: reasonController.text.trim().isEmpty
                                ? null
                                : reasonController.text.trim(),
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          ),
                        );
                      case StockMovementType.transfer:
                        if (fromWarehouse == null || toWarehouse == null) {
                          return;
                        }
                        result = await cubit.transfer(
                          TransferStockInput(
                            sparePartId: widget.partId,
                            fromWarehouseId: fromWarehouse!.id,
                            toWarehouseId: toWarehouse!.id,
                            quantity: qty,
                            reason: reasonController.text.trim().isEmpty
                                ? null
                                : reasonController.text.trim(),
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          ),
                        );
                      case StockMovementType.adjustment:
                        if (warehouse == null ||
                            reasonController.text.trim().isEmpty) {
                          return;
                        }
                        result = await cubit.adjustment(
                          AdjustmentInput(
                            sparePartId: widget.partId,
                            warehouseId: warehouse!.id,
                            quantity: qty,
                            direction: direction,
                            reason: reasonController.text.trim(),
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          ),
                        );
                    }

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
                  child: Text(l10n.inventorySave),
                ),
              ],
            );
          },
        );
      },
    );

    qtyController.dispose();
    reasonController.dispose();
    notesController.dispose();

    if (saved == true) {
      _changed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canUpdate = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canUpdateInventory() == true,
    );
    final canDelete = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canDeleteInventory() == true,
    );
    final canManageStock = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canManageInventoryStock() == true,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_changed);
        }
      },
      child: BlocProvider.value(
        value: _cubit,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.inventoryPartDetails),
            actions: [
              if (canUpdate)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final changed = await context.push<bool>(
                      RoutePaths.inventoryPartFormEdit(widget.partId),
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
          body: BlocBuilder<SparePartDetailCubit, SparePartDetailState>(
            builder: (context, state) {
              if (state.status == SparePartDetailStatus.loading ||
                  state.status == SparePartDetailStatus.initial) {
                return const AppLoader();
              }
              if (state.status == SparePartDetailStatus.failure ||
                  state.part == null) {
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

              final part = state.part!;
              return ListView(
                padding: AppScrollPadding.resolve(
                  context,
                  base: const EdgeInsets.all(AppSpacing.md),
                  chrome: AppBottomChrome.system,
                ),
                children: [
                  if (part.image?.url != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: AppCachedNetworkImage(
                          imageUrl: part.image!.url,
                          fit: BoxFit.cover,
                          errorIcon: Icons.image_not_supported,
                        ),
                      ),
                    ),
                  if (part.image?.url != null)
                    const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          part.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      StockStatusBadge(status: part.stockStatus),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${l10n.inventoryPartNumber}: ${part.partNumber}'),
                  if (part.category != null)
                    Text('${l10n.inventoryCategory}: ${part.category}'),
                  if (part.barcode != null)
                    Text('${l10n.inventoryBarcode}: ${part.barcode}'),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.inventoryAvailableQuantity),
                                Text(
                                  '${_formatQty(part.currentQuantity)} ${part.unit}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(l10n.inventoryMinimumQuantity),
                              Text(
                                '${_formatQty(part.minimumQuantity)} ${part.unit}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (part.description != null &&
                      part.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.inventoryDescription,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(part.description!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (canManageStock)
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FilledButton.tonal(
                          onPressed: state.status ==
                                  SparePartDetailStatus.mutating
                              ? null
                              : () =>
                                  _showStockDialog(StockMovementType.stockIn),
                          child: Text(l10n.inventoryStockIn),
                        ),
                        FilledButton.tonal(
                          onPressed: state.status ==
                                  SparePartDetailStatus.mutating
                              ? null
                              : () =>
                                  _showStockDialog(StockMovementType.stockOut),
                          child: Text(l10n.inventoryStockOut),
                        ),
                        FilledButton.tonal(
                          onPressed: state.status ==
                                  SparePartDetailStatus.mutating
                              ? null
                              : () =>
                                  _showStockDialog(StockMovementType.transfer),
                          child: Text(l10n.inventoryTransfer),
                        ),
                        FilledButton.tonal(
                          onPressed: state.status ==
                                  SparePartDetailStatus.mutating
                              ? null
                              : () => _showStockDialog(
                                    StockMovementType.adjustment,
                                  ),
                          child: Text(l10n.inventoryAdjustment),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      RoutePaths.inventoryStockHistory,
                      extra: widget.partId,
                    ),
                    icon: const Icon(Icons.history),
                    label: Text(l10n.inventoryStockHistory),
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
