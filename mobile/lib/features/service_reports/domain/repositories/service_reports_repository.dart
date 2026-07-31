import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';

abstract class ServiceReportsRepository {
  Future<Result<ServiceReportsDashboard>> getDashboard();

  Future<Result<ServiceReportPage>> listReports({
    int page = 1,
    int limit = 20,
    String? search,
    ServiceReportStatus? status,
  });

  Future<Result<ServiceReport>> getReportById(String id);

  Future<Result<ServiceReport>> generateReport(GenerateServiceReportInput input);

  Future<Result<ServiceReportDownload>> downloadReport(String id);

  Future<Result<CustomerSignaturePage>> listSignatures({
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Result<CustomerSignature>> getSignatureById(String id);

  Future<Result<CustomerSignature>> createSignature(CreateSignatureInput input);

  Future<Result<CustomerSignature>> deleteSignature(String id);

  /// Offline sync prep — returns queued actions (empty in online MVP).
  Future<List<PendingReportAction>> getPendingActions();

  /// Offline sync prep — no-op online MVP.
  Future<Result<int>> syncPendingActions();
}
