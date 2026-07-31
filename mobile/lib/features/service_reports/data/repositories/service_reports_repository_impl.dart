import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/service_reports/data/datasources/service_reports_local_datasource.dart';
import 'package:mobile/features/service_reports/data/datasources/service_reports_remote_datasource.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';
import 'package:mobile/features/service_reports/domain/repositories/service_reports_repository.dart';

class ServiceReportsRepositoryImpl implements ServiceReportsRepository {
  ServiceReportsRepositoryImpl({
    required ServiceReportsRemoteDataSource remote,
    required ServiceReportsLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final ServiceReportsRemoteDataSource _remote;
  final ServiceReportsLocalDataSource _local;

  @override
  Future<Result<ServiceReportsDashboard>> getDashboard() async {
    try {
      return Success(await _remote.getDashboard());
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<ServiceReportPage>> listReports({
    int page = 1,
    int limit = 20,
    String? search,
    ServiceReportStatus? status,
  }) async {
    try {
      return Success(
        await _remote.listReports(
          page: page,
          limit: limit,
          search: search,
          status: status,
        ),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<ServiceReport>> getReportById(String id) async {
    try {
      return Success(await _remote.getReportById(id));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<ServiceReport>> generateReport(
    GenerateServiceReportInput input,
  ) async {
    try {
      return Success(await _remote.generateReport(input));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<ServiceReportDownload>> downloadReport(String id) async {
    try {
      return Success(await _remote.downloadReport(id));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<CustomerSignaturePage>> listSignatures({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      return Success(
        await _remote.listSignatures(
          page: page,
          limit: limit,
          search: search,
        ),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<CustomerSignature>> getSignatureById(String id) async {
    try {
      return Success(await _remote.getSignatureById(id));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<CustomerSignature>> createSignature(
    CreateSignatureInput input,
  ) async {
    try {
      return Success(await _remote.createSignature(input));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<CustomerSignature>> deleteSignature(String id) async {
    try {
      return Success(await _remote.deleteSignature(id));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<List<PendingReportAction>> getPendingActions() async =>
      _local.readPendingQueue();

  @override
  Future<Result<int>> syncPendingActions() async => const Success(0);
}
