import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:mobile/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';

class _CountingRemote implements DashboardRemoteDataSource {
  int calls = 0;

  @override
  Future<RoleDashboardSummary> getSummary({
    required DashboardPeriod period,
    DateTime? from,
    DateTime? to,
  }) async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return RoleDashboardSummary(
      viewRole: DashboardViewRole.admin,
      period: period,
      from: DateTime.utc(2026, 8, 1),
      to: DateTime.utc(2026, 8, 31),
    );
  }
}

void main() {
  test('concurrent getSummary calls share one HTTP request', () async {
    final remote = _CountingRemote();
    final repo = DashboardRepositoryImpl(remote: remote);

    final results = await Future.wait([
      repo.getSummary(period: DashboardPeriod.month),
      repo.getSummary(period: DashboardPeriod.month),
      repo.getSummary(period: DashboardPeriod.month),
    ]);

    expect(remote.calls, 1);
    for (final result in results) {
      expect(result, isA<Success<RoleDashboardSummary>>());
    }
  });

  test('fresh success is reused within short TTL without a second HTTP call',
      () async {
    final remote = _CountingRemote();
    final repo = DashboardRepositoryImpl(remote: remote);

    final first = await repo.getSummary(period: DashboardPeriod.month);
    final second = await repo.getSummary(period: DashboardPeriod.month);

    expect(first, isA<Success<RoleDashboardSummary>>());
    expect(second, isA<Success<RoleDashboardSummary>>());
    expect(remote.calls, 1);
  });
}
