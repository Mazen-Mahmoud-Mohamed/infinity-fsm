import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';
import 'package:mobile/features/service_reports/presentation/cubit/service_reports_cubits.dart';
import 'package:mobile/features/service_reports/presentation/widgets/report_status_badge.dart';
import 'package:mobile/features/service_reports/presentation/widgets/service_reports_skeleton.dart';

class ServiceReportsListPage extends StatefulWidget {
  const ServiceReportsListPage({
    super.key,
    @visibleForTesting this.debugCubit,
  });

  /// When set, skips GetIt and does not auto-call [loadFirstPage] (widget tests).
  @visibleForTesting
  final ServiceReportsListCubit? debugCubit;

  @override
  State<ServiceReportsListPage> createState() => _ServiceReportsListPageState();
}

class _ServiceReportsListPageState extends State<ServiceReportsListPage> {
  late final ServiceReportsListCubit _cubit;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = widget.debugCubit ??
        (getIt<ServiceReportsListCubit>()..loadFirstPage());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    if (widget.debugCubit == null) {
      _cubit.close();
    }
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
    final dateFormat = AppFormatters.mediumDate(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.reportsList)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.reportsSearchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _cubit.search,
              ),
            ),
            BlocBuilder<ServiceReportsListCubit, ServiceReportsListState>(
              buildWhen: (p, c) => p.filterStatus != c.filterStatus,
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(l10n.reportsFilterAll),
                        selected: state.filterStatus == null,
                        onSelected: (_) => _cubit.setFilter(null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...ServiceReportStatus.values.map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text(switch (status) {
                              ServiceReportStatus.draft =>
                                l10n.reportsStatusDraft,
                              ServiceReportStatus.generated =>
                                l10n.reportsStatusGenerated,
                              ServiceReportStatus.downloaded =>
                                l10n.reportsStatusDownloaded,
                            }),
                            selected: state.filterStatus == status,
                            onSelected: (_) => _cubit.setFilter(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            BlocSelector<ServiceReportsListCubit, ServiceReportsListState, bool>(
              selector: (state) => state.isRefreshing,
              builder: (context, refreshing) =>
                  AppRefreshBar(visible: refreshing),
            ),
            Expanded(
              child: BlocBuilder<ServiceReportsListCubit, ServiceReportsListState>(
                builder: (context, state) {
                  final Widget body;
                  if ((state.status == ServiceReportsListStatus.loading ||
                          state.status == ServiceReportsListStatus.initial) &&
                      state.items.isEmpty) {
                    body = ServiceReportsSkeleton(
                      key: const ValueKey('service-reports-list-skeleton'),
                      variant: ServiceReportsSkeletonVariant.list,
                      semanticsLabel: l10n.reportsLoading,
                    );
                  } else if (state.status == ServiceReportsListStatus.failure &&
                      state.items.isEmpty) {
                    body = Center(
                      key: const ValueKey('service-reports-list-error'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.reportsLoadFailed,
                        ),
                          FilledButton(
                            onPressed: () => _cubit.loadFirstPage(),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  } else if (state.items.isEmpty) {
                    body = Center(
                      key: const ValueKey('service-reports-list-empty'),
                      child: Text(l10n.reportsEmpty),
                    );
                  } else {
                  body = RefreshIndicator(
                    key: const ValueKey('service-reports-list-content'),
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
                        final report = state.items[index];
                        return Card(
                          child: ListTile(
                            title: Text(report.reportNumber),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (report.workOrder.jobNumber != null)
                                  Text(report.workOrder.jobNumber!),
                                if (report.generatedAt != null)
                                  Text(
                                    dateFormat
                                        .format(report.generatedAt!.toLocal()),
                                  ),
                                const SizedBox(height: AppSpacing.xs),
                                ReportStatusBadge(status: report.status),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () => context.push(
                              RoutePaths.reportDetail(report.id),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: body,
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
