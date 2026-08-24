import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/dashboard/data/models/role_dashboard_summary_model.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';

abstract class DashboardRemoteDataSource {
  Future<RoleDashboardSummary> getSummary({
    required DashboardPeriod period,
    DateTime? from,
    DateTime? to,
  });
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<RoleDashboardSummary> getSummary({
    required DashboardPeriod period,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.dashboardSummary,
      queryParameters: {
        'period': dashboardPeriodToQuery(period),
        if (period == DashboardPeriod.custom && from != null)
          'from': from.toIso8601String(),
        if (period == DashboardPeriod.custom && to != null)
          'to': to.toIso8601String(),
      },
    );
    return RoleDashboardSummaryModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }
}
