import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required DashboardRemoteDataSource remote})
      : _remote = remote;

  final DashboardRemoteDataSource _remote;

  /// In-flight + ultra-short reuse so dashboard load and notifications unread
  /// (same period) do not issue duplicate HTTP calls within a few seconds.
  Future<Result<RoleDashboardSummary>>? _inFlight;
  String? _inFlightKey;
  RoleDashboardSummary? _lastSuccess;
  String? _lastSuccessKey;
  DateTime? _lastSuccessAt;

  static const Duration _freshResultTtl = Duration(seconds: 5);

  @override
  Future<Result<RoleDashboardSummary>> getSummary({
    required DashboardPeriod period,
    DateTime? from,
    DateTime? to,
  }) async {
    final key = _cacheKey(period: period, from: from, to: to);

    if (_inFlight != null && _inFlightKey == key) {
      return _inFlight!;
    }

    final lastAt = _lastSuccessAt;
    final last = _lastSuccess;
    if (last != null &&
        _lastSuccessKey == key &&
        lastAt != null &&
        DateTime.now().difference(lastAt) < _freshResultTtl) {
      return Success(last);
    }

    final future = _fetch(period: period, from: from, to: to, key: key);
    _inFlight = future;
    _inFlightKey = key;
    try {
      return await future;
    } finally {
      if (identical(_inFlight, future)) {
        _inFlight = null;
        _inFlightKey = null;
      }
    }
  }

  Future<Result<RoleDashboardSummary>> _fetch({
    required DashboardPeriod period,
    DateTime? from,
    DateTime? to,
    required String key,
  }) async {
    try {
      final summary = await _remote.getSummary(
        period: period,
        from: from,
        to: to,
      );
      _lastSuccess = summary;
      _lastSuccessKey = key;
      _lastSuccessAt = DateTime.now();
      return Success(summary);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  String _cacheKey({
    required DashboardPeriod period,
    DateTime? from,
    DateTime? to,
  }) {
    return '${period.name}|${from?.toIso8601String() ?? ''}|${to?.toIso8601String() ?? ''}';
  }
}
