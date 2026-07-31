import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';

abstract class DashboardRepository {
  Future<Result<RoleDashboardSummary>> getSummary({
    required DashboardPeriod period,
    DateTime? from,
    DateTime? to,
  });
}
