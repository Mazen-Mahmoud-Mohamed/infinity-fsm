import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/service_reports/presentation/cubit/service_reports_cubits.dart';
import 'package:mobile/features/service_reports/presentation/widgets/service_report_preview_card.dart';
import 'package:mobile/features/service_reports/presentation/widgets/service_reports_skeleton.dart';

class ServiceReportDetailPage extends StatefulWidget {
  const ServiceReportDetailPage({
    super.key,
    required this.reportId,
    @visibleForTesting this.debugCubit,
  });

  final String reportId;

  /// When set, skips GetIt and does not auto-call [load] (widget tests).
  @visibleForTesting
  final ServiceReportDetailCubit? debugCubit;

  @override
  State<ServiceReportDetailPage> createState() =>
      _ServiceReportDetailPageState();
}

class _ServiceReportDetailPageState extends State<ServiceReportDetailPage> {
  late final ServiceReportDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.debugCubit ??
        (getIt<ServiceReportDetailCubit>(param1: widget.reportId)..load());
  }

  @override
  void dispose() {
    if (widget.debugCubit == null) {
      _cubit.close();
    }
    super.dispose();
  }

  Future<void> _download() async {
    final l10n = AppLocalizations.of(context);
    final result = await _cubit.download();
    if (!mounted) return;
    switch (result) {
      case Success(data: final data):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reportsDownloaded(data.fileName)),
          ),
        );
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canDownload = context.select(
      (AuthCubit c) =>
          c.state.user?.permissionChecker.canDownloadReports() == true,
    );

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.reportsDetails),
          actions: [
            if (canDownload)
              IconButton(
                tooltip: l10n.reportsDownload,
                icon: const Icon(Icons.download_outlined),
                onPressed: _download,
              ),
          ],
        ),
        body: BlocBuilder<ServiceReportDetailCubit, ServiceReportDetailState>(
          buildWhen: (p, c) =>
              p.status != c.status ||
              p.report != c.report ||
              p.message != c.message ||
              p.downloading != c.downloading ||
              p.isRefreshing != c.isRefreshing,
          builder: (context, state) {
            final Widget body;
            if ((state.status == ServiceReportDetailStatus.loading ||
                    state.status == ServiceReportDetailStatus.initial) &&
                state.report == null) {
              body = ServiceReportsSkeleton(
                key: const ValueKey('service-report-detail-skeleton'),
                variant: ServiceReportsSkeletonVariant.detail,
                semanticsLabel: l10n.reportsLoading,
              );
            } else if (state.status == ServiceReportDetailStatus.failure &&
                state.report == null) {
              body = Center(
                key: const ValueKey('service-report-detail-error'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.reportsLoadFailed,
                        ),
                    FilledButton(
                      onPressed: _cubit.load,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            } else if (state.report == null) {
              body = ServiceReportsSkeleton(
                key: const ValueKey('service-report-detail-skeleton'),
                variant: ServiceReportsSkeletonVariant.detail,
                semanticsLabel: l10n.reportsLoading,
              );
            } else {
            body = Column(
              key: const ValueKey('service-report-detail-content'),
              children: [
                AppRefreshBar(visible: state.isRefreshing),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _cubit.load,
                    child: ListView(
                      padding: AppScrollPadding.resolve(
                        context,
                        base: const EdgeInsets.all(AppSpacing.md),
                        chrome: AppBottomChrome.system,
                      ),
                      children: [
                  if (state.downloading)
                    const LinearProgressIndicator(),
                  ServiceReportPreviewCard(report: state.report!),
                  if (canDownload) ...[
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: state.downloading ? null : _download,
                      icon: const Icon(Icons.download),
                      label: Text(l10n.reportsDownload),
                    ),
                  ],
                      ],
                    ),
                  ),
                ),
              ],
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
    );
  }
}
