import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardSummaryUseCase {
  GetDashboardSummaryUseCase(this._repository);

  final DashboardRepository _repository;

  Future<Result<RoleDashboardSummary>> call({
    required DashboardPeriod period,
    DateTime? from,
    DateTime? to,
  }) {
    return _repository.getSummary(period: period, from: from, to: to);
  }
}
