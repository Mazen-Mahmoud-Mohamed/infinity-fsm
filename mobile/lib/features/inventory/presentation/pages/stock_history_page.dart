import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/inventory/domain/entities/stock_movement.dart';
import 'package:mobile/features/inventory/presentation/cubit/stock_history_cubit.dart';
import 'package:mobile/features/inventory/presentation/widgets/stock_movement_tile.dart';

class StockHistoryPage extends StatefulWidget {
  const StockHistoryPage({super.key, this.sparePartId});

  final String? sparePartId;

  @override
  State<StockHistoryPage> createState() => _StockHistoryPageState();
}

class _StockHistoryPageState extends State<StockHistoryPage> {
  late final StockHistoryCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<StockHistoryCubit>(param1: widget.sparePartId ?? '')
      ..loadFirstPage();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: const _StockHistoryView(),
    );
  }
}

class _StockHistoryView extends StatefulWidget {
  const _StockHistoryView();

  @override
  State<_StockHistoryView> createState() => _StockHistoryViewState();
}

class _StockHistoryViewState extends State<_StockHistoryView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<StockHistoryCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventoryStockHistory)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.inventorySearchMovements,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<StockHistoryCubit>().search('');
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) =>
                  context.read<StockHistoryCubit>().search(value),
            ),
          ),
          BlocBuilder<StockHistoryCubit, StockHistoryState>(
            buildWhen: (previous, current) => previous.type != current.type,
            builder: (context, state) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.inventoryFilterAll),
                      selected: state.type == null,
                      onSelected: (_) =>
                          context.read<StockHistoryCubit>().setFilter(null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ...StockMovementType.values.map((type) {
                      final label = switch (type) {
                        StockMovementType.stockIn => l10n.inventoryStockIn,
                        StockMovementType.stockOut => l10n.inventoryStockOut,
                        StockMovementType.transfer => l10n.inventoryTransfer,
                        StockMovementType.adjustment =>
                          l10n.inventoryAdjustment,
                      };
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: FilterChip(
                          label: Text(label),
                          selected: state.type == type,
                          onSelected: (_) => context
                              .read<StockHistoryCubit>()
                              .setFilter(type),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: BlocBuilder<StockHistoryCubit, StockHistoryState>(
              buildWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.items != current.items ||
                  previous.hasMore != current.hasMore ||
                  previous.isRefreshing != current.isRefreshing ||
                  previous.message != current.message,
              builder: (context, state) {
                if ((state.status == StockHistoryStatus.loading ||
                        state.status == StockHistoryStatus.initial) &&
                    state.items.isEmpty) {
                  return const AppLoader();
                }
                if (state.status == StockHistoryStatus.failure &&
                    state.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message ?? l10n.inventoryLoadFailed),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: () => context
                              .read<StockHistoryCubit>()
                              .loadFirstPage(),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }
                if (state.items.isEmpty) {
                  return Column(
                    children: [
                      AppRefreshBar(visible: state.isRefreshing),
                      Expanded(
                        child: Center(
                          child: Text(l10n.inventoryMovementsEmpty),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    AppRefreshBar(visible: state.isRefreshing),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => context
                            .read<StockHistoryCubit>()
                            .loadFirstPage(),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: AppScrollPadding.resolve(
                            context,
                            base: const EdgeInsets.all(AppSpacing.md),
                            chrome: AppBottomChrome.system,
                          ),
                          itemCount:
                              state.items.length + (state.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return StockMovementTile(
                              movement: state.items[index],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
