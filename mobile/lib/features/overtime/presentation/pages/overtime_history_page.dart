import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/branding/infinity_brand.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_history_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_formatters.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_status_badge.dart';

class OvertimeHistoryPage extends StatelessWidget {
  const OvertimeHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OvertimeHistoryCubit>()..loadFirstPage(),
      child: const _OvertimeHistoryView(),
    );
  }
}

class _OvertimeHistoryView extends StatefulWidget {
  const _OvertimeHistoryView();

  @override
  State<_OvertimeHistoryView> createState() => _OvertimeHistoryViewState();
}

class _OvertimeHistoryViewState extends State<_OvertimeHistoryView> {
  final ScrollController _scrollController = ScrollController();

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
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<OvertimeHistoryCubit>().loadMore();
    }
  }

  bool _isPendingSync(OvertimeSession session) {
    if (session.id.startsWith('local-')) {
      return true;
    }
    final queue = getIt<OvertimeLocalDataSource>().readQueue();
    if (queue.isEmpty) {
      return false;
    }
    final map = getIt<OvertimeLocalDataSource>().readLocalIdMap();
    return queue.any((action) {
      final sid = action.sessionId;
      if (sid == session.id) {
        return true;
      }
      if (action.type == PendingOvertimeActionType.start &&
          'local-${action.clientRequestId}' == session.id) {
        return true;
      }
      if (sid != null && map[sid] == session.id) {
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDate(context);

    return BlocListener<OvertimeSyncCubit, OvertimeSyncState>(
      listenWhen: (previous, current) =>
          previous.pendingCount != current.pendingCount ||
          previous.status != current.status,
      listener: (context, syncState) {
        // After offline queue drains (or shrinks), refresh History so badges
        // move from Pending Sync → server status.
        context.read<OvertimeHistoryCubit>().loadFirstPage();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.overtimeMyHistory)),
        body: BlocBuilder<OvertimeHistoryCubit, OvertimeHistoryState>(
          builder: (context, state) {
            if (state.status == OvertimeHistoryStatus.loading &&
                state.items.isEmpty) {
              return AppLoader(message: l10n.attendanceHistoryLoading);
            }

            if (state.status == OvertimeHistoryStatus.failure &&
                state.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.message != null
                            ? localizeAppMessage(l10n, state.message)
                            : l10n.overtimeHistoryLoadFailed,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => context
                            .read<OvertimeHistoryCubit>()
                            .loadFirstPage(),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const InfinityEmptyBrandMark(size: 56),
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.overtimeHistoryEmpty),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                AppRefreshBar(visible: state.isRefreshing),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<OvertimeHistoryCubit>().loadFirstPage(),
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppScrollPadding.resolve(
                        context,
                        base: const EdgeInsets.all(AppSpacing.lg),
                        chrome: AppBottomChrome.system,
                      ),
                      itemCount: state.items.length +
                          (state.status == OvertimeHistoryStatus.loadingMore
                              ? 1
                              : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final session = state.items[index];
                        return _HistoryCard(
                          session: session,
                          pendingSync: _isPendingSync(session),
                          dateFormat: dateFormat,
                          l10n: l10n,
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
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.session,
    required this.pendingSync,
    required this.dateFormat,
    required this.l10n,
  });

  final OvertimeSession session;
  final bool pendingSync;
  final DateFormat dateFormat;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateFormat.format(session.startAt.toLocal()),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OvertimeStatusBadge(
                status: session.status,
                pendingSync: pendingSync,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            overtimeTypeLabel(l10n, session.type),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.overtimeDurationLine(
              OvertimeFormatters.durationFromMinutes(
                session.eligibleOvertimeMinutes,
                l10n,
              ),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!pendingSync &&
              session.id.isNotEmpty &&
              !session.id.startsWith('local-')) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.overtimeStatusSynced,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          if (session.rejectionReason != null &&
              session.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.overtimeRejectionReasonLine(session.rejectionReason!),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
