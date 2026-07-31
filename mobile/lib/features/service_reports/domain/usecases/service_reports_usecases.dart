import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';
import 'package:mobile/features/service_reports/domain/repositories/service_reports_repository.dart';

class GetServiceReportsDashboardUseCase {
  GetServiceReportsDashboardUseCase(this._repository);
  final ServiceReportsRepository _repository;
  Future<Result<ServiceReportsDashboard>> call() => _repository.getDashboard();
}

class ListServiceReportsUseCase {
  ListServiceReportsUseCase(this._repository);
  final ServiceReportsRepository _repository;
  Future<Result<ServiceReportPage>> call({
    int page = 1,
    int limit = 20,
    String? search,
    ServiceReportStatus? status,
  }) =>
      _repository.listReports(
        page: page,
        limit: limit,
        search: search,
        status: status,
      );
}

class GetServiceReportByIdUseCase {
  GetServiceReportByIdUseCase(this._repository);
  final ServiceReportsRepository _repository;
  Future<Result<ServiceReport>> call(String id) =>
      _repository.getReportById(id);
}

class GenerateServiceReportUseCase {
  GenerateServiceReportUseCase(this._repository);
  final ServiceReportsRepository _repository;
  Future<Result<ServiceReport>> call(GenerateServiceReportInput input) =>
      _repository.generateReport(input);
}

class DownloadServiceReportUseCase {
  DownloadServiceReportUseCase(this._repository);
  final ServiceReportsRepository _repository;
  Future<Result<ServiceReportDownload>> call(String id) =>
      _repository.downloadReport(id);
}

class ListCustomerSignaturesUseCase {
  ListCustomerSignaturesUseCase(this._repository);
  final ServiceReportsRepository _repository;
  Future<Result<CustomerSignaturePage>> call({
    int page = 1,
    int limit = 20,
    String? search,
  }) =>
      _repository.listSignatures(page: page, limit: limit, search: search);
}

class GetCustomerSignatureByIdUseCase {
  GetCustomerSignatureByIdUseCase(this._repository);
  final ServiceReportsRepository _repository;
  Future<Result<CustomerSignature>> call(String id) =>
      _repository.getSignatureById(id);
}

class CreateCustomerSignatureUseCase {
  CreateCustomerSignatureUseCase(this._repository);
  final ServiceReportsRepository _repository;
  Future<Result<CustomerSignature>> call(CreateSignatureInput input) =>
      _repository.createSignature(input);
}

class DeleteCustomerSignatureUseCase {
  DeleteCustomerSignatureUseCase(this._repository);
  final ServiceReportsRepository _repository;
  Future<Result<CustomerSignature>> call(String id) =>
      _repository.deleteSignature(id);
}

class SyncPendingReportsUseCase {
  SyncPendingReportsUseCase(this._repository);
  final ServiceReportsRepository _repository;
  Future<Result<int>> call() => _repository.syncPendingActions();
}
