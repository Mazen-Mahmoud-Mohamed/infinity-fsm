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
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_plans_cubit.dart';
import 'package:mobile/features/pm/presentation/widgets/pm_status_badges.dart';

class PmPlansPage extends StatefulWidget {
  const PmPlansPage({super.key, this.initialStatus});

  final PmPlanStatus? initialStatus;

  @override
  State<PmPlansPage> createState() => _PmPlansPageState();
}

class _PmPlansPageState extends State<PmPlansPage> {
  late final PmPlansCubit _cubit;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<PmPlansCubit>()
      ..loadFirstPage(status: widget.initialStatus);
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
    final canCreate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canCreatePm() == true,
    );
    final dateFormat = AppFormatters.mediumDate(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.pmPlans)),
        floatingActionButton: canCreate
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final changed =
                      await context.push<bool>(RoutePaths.pmPlanForm);
                  if (changed == true && mounted) {
                    await _cubit.loadFirstPage();
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.pmCreatePlan),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.pmSearchPlansHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _cubit.search,
              ),
            ),
            BlocBuilder<PmPlansCubit, PmPlansState>(
              buildWhen: (p, c) => p.filterStatus != c.filterStatus,
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(l10n.pmFilterAll),
                        selected: state.filterStatus == null,
                        onSelected: (_) => _cubit.setStatusFilter(null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...PmPlanStatus.values.map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text(status == PmPlanStatus.active
                                ? l10n.pmStatusActive
                                : l10n.pmStatusInactive),
                            selected: state.filterStatus == status,
                            onSelected: (_) => _cubit.setStatusFilter(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            BlocSelector<PmPlansCubit, PmPlansState, bool>(
              selector: (state) => state.isRefreshing,
              builder: (context, refreshing) =>
                  AppRefreshBar(visible: refreshing),
            ),
            Expanded(
              child: BlocBuilder<PmPlansCubit, PmPlansState>(
                buildWhen: (p, c) =>
                    p.status != c.status ||
                    p.items != c.items ||
                    p.hasMore != c.hasMore ||
                    p.message != c.message,
                builder: (context, state) {
                  if ((state.status == PmPlansStatus.loading ||
                          state.status == PmPlansStatus.initial) &&
                      state.items.isEmpty) {
                    return AppLoader(message: l10n.pmLoading);
                  }
                  if (state.status == PmPlansStatus.failure &&
                      state.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.pmLoadFailed,
                        ),
                          FilledButton(
                            onPressed: () => _cubit.loadFirstPage(),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state.items.isEmpty) {
                    return Center(child: Text(l10n.pmPlansEmpty));
                  }
                  return RefreshIndicator(
                    onRefresh: () => _cubit.loadFirstPage(),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: AppScrollPadding.resolve(
                        context,
                        base: const EdgeInsets.all(AppSpacing.md),
                        chrome: AppBottomChrome.fab,
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
                        final plan = state.items[index];
                        return Card(
                          child: ListTile(
                            title: Text(plan.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan.code),
                                const SizedBox(height: AppSpacing.xs),
                                Text(pmFrequencyLabel(l10n, plan.frequency)),
                                if (plan.nextDueDate != null)
                                  Text(
                                    '${l10n.pmNextDueDate}: ${dateFormat.format(plan.nextDueDate!.toLocal())}',
                                  ),
                                const SizedBox(height: AppSpacing.xs),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  children: [
                                    PmPlanStatusBadge(status: plan.status),
                                    PmPriorityBadge(priority: plan.priority),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () async {
                              final changed = await context.push<bool>(
                                RoutePaths.pmPlanDetail(plan.id),
                              );
                              if (changed == true && mounted) {
                                await _cubit.loadFirstPage();
                              }
                            },
                          ),
                        );
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
