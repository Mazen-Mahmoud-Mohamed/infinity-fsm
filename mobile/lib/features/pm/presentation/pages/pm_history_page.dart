import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_schedules_history_cubits.dart';
import 'package:mobile/features/pm/presentation/widgets/pm_schedule_tile.dart';

class PmHistoryPage extends StatefulWidget {
  const PmHistoryPage({super.key, this.planId});

  final String? planId;

  @override
  State<PmHistoryPage> createState() => _PmHistoryPageState();
}

class _PmHistoryPageState extends State<PmHistoryPage> {
  late final PmHistoryCubit _cubit;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<PmHistoryCubit>(param1: widget.planId ?? '')
      ..loadFirstPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
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
        appBar: AppBar(title: Text(l10n.pmHistory)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.pmSearchSchedulesHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _cubit.search,
              ),
            ),
            BlocSelector<PmHistoryCubit, PmHistoryState, bool>(
              selector: (state) => state.isRefreshing,
              builder: (context, refreshing) =>
                  AppRefreshBar(visible: refreshing),
            ),
            Expanded(
              child: BlocBuilder<PmHistoryCubit, PmHistoryState>(
                builder: (context, state) {
                  if ((state.status == PmHistoryStatus.loading ||
                          state.status == PmHistoryStatus.initial) &&
                      state.items.isEmpty) {
                    return AppLoader(message: l10n.pmLoading);
                  }
                  if (state.status == PmHistoryStatus.failure &&
                      state.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.message ?? l10n.pmLoadFailed),
                          FilledButton(
                            onPressed: () => _cubit.loadFirstPage(),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state.items.isEmpty) {
                    return Center(child: Text(l10n.pmHistoryEmpty));
                  }
                  return RefreshIndicator(
                    onRefresh: () => _cubit.loadFirstPage(),
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
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return PmScheduleTile(schedule: state.items[index]);
                      },
                    ),
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
