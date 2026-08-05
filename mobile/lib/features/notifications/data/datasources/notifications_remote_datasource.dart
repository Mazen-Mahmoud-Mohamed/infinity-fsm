import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:mobile/core/utils/result.dart';

/// Fetches activity used as the temporary notification feed.
/// Today: existing dashboard summary only. Swap this class for a future
/// `/notifications` API without changing repository contracts or UI/Cubits.
class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._getDashboardSummary);

  final GetDashboardSummaryUseCase _getDashboardSummary;

  /// Returns real backend activity items only — never synthesizes fake rows.
  Future<Result<List<DashboardLiveActivityItem>>> fetchActivityFeed() async {
    final result = await _getDashboardSummary(period: DashboardPeriod.month);
    return switch (result) {
      Failure(:final message, :final code) => Failure(message, code: code),
      Success(:final data) => Success(_extractActivity(data)),
    };
  }

  List<DashboardLiveActivityItem> _extractActivity(RoleDashboardSummary summary) {
    if (summary.liveActivity.isNotEmpty) {
      return List<DashboardLiveActivityItem>.unmodifiable(summary.liveActivity);
    }
    if (summary.teamActivity.isNotEmpty) {
      return List<DashboardLiveActivityItem>.unmodifiable(summary.teamActivity);
    }
    // Fallback: map existing dashboard notification projections (same audit source).
    return summary.notifications
        .map(
          (item) {
            final module = _moduleFromBody(item.body);
            return DashboardLiveActivityItem(
              id: item.id,
              action: item.title,
              module: module,
              actorName: _actorFromBody(item.body),
              createdAt: item.createdAt,
            );
          },
        )
        .toList(growable: false);
  }

  String _moduleFromBody(String body) {
    final parts = body.split('·');
    if (parts.isEmpty) return 'general';
    return parts.first.trim();
  }

  String? _actorFromBody(String body) {
    final parts = body.split('·');
    if (parts.length < 2) return null;
    final actor = parts.sublist(1).join('·').trim();
    return actor.isEmpty ? null : actor;
  }
}
