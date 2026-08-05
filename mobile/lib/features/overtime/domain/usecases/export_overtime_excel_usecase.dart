import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_export_filters.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';

class ExportOvertimeExcelUseCase {
  const ExportOvertimeExcelUseCase(this._repository);

  final OvertimeRepository _repository;

  Future<Result<OvertimeExcelExportResult>> call(
    OvertimeExportFilters filters,
  ) {
    return _repository.exportExcel(filters);
  }
}
