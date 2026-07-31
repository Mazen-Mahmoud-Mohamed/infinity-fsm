import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/assets/domain/entities/asset_history.dart';
import 'package:mobile/features/assets/presentation/cubit/asset_detail_form_history_cubits.dart';
import 'package:mobile/features/assets/presentation/widgets/asset_history_tile.dart';

class AssetHistoryPage extends StatefulWidget {
  const AssetHistoryPage({super.key, this.assetId});

  final String? assetId;

  @override
  State<AssetHistoryPage> createState() => _AssetHistoryPageState();
}

class _AssetHistoryPageState extends State<AssetHistoryPage> {
  late final AssetHistoryCubit _cubit;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<AssetHistoryCubit>(param1: widget.assetId ?? '')
      ..loadFirstPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.assetsHistory)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.assetsSearchHistory,
                  prefixIcon: const Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _cubit.search,
              ),
            ),
            BlocBuilder<AssetHistoryCubit, AssetHistoryListState>(
              buildWhen: (p, c) => p.type != c.type,
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(l10n.assetsFilterAll),
                        selected: state.type == null,
                        onSelected: (_) => _cubit.setFilter(null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...[
                        AssetHistoryType.installation,
                        AssetHistoryType.maintenance,
                        AssetHistoryType.repair,
                        AssetHistoryType.inspection,
                        AssetHistoryType.statusChange,
                      ].map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text(type.apiValue),
                            selected: state.type == type,
                            onSelected: (_) => _cubit.setFilter(type),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: BlocBuilder<AssetHistoryCubit, AssetHistoryListState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.items != current.items ||
                    previous.hasMore != current.hasMore ||
                    previous.isRefreshing != current.isRefreshing ||
                    previous.message != current.message,
                builder: (context, state) {
                  if ((state.status == AssetHistoryStatus.loading ||
                          state.status == AssetHistoryStatus.initial) &&
                      state.items.isEmpty) {
                    return const AppLoader();
                  }
                  if (state.status == AssetHistoryStatus.failure &&
                      state.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.message ?? l10n.assetsLoadFailed),
                          FilledButton(
                            onPressed: () => _cubit.loadFirstPage(),
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
                            child: Text(l10n.assetsHistoryEmpty),
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
                          onRefresh: () => _cubit.loadFirstPage(),
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: AppScrollPadding.resolve(
                              context,
                              base: const EdgeInsets.all(AppSpacing.md),
                              chrome: AppBottomChrome.system,
                            ),
                            itemCount: state.items.length +
                                (state.hasMore ? 1 : 0),
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
                              return AssetHistoryTile(
                                item: state.items[index],
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
      ),
    );
  }
}
