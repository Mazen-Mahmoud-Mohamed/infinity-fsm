import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required DashboardRemoteDataSource remote})
      : _remote = remote;

  final DashboardRemoteDataSource _remote;

  @override
  Future<Result<RoleDashboardSummary>> getSummary({
    required DashboardPeriod period,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      return Success(
        await _remote.getSummary(period: period, from: from, to: to),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }
}
