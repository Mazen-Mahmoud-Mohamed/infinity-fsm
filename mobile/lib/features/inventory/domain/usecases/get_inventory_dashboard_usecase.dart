import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/inventory_dashboard.dart';
import 'package:mobile/features/inventory/domain/repositories/inventory_repository.dart';

class GetInventoryDashboardUseCase {
  GetInventoryDashboardUseCase(this._repository);

  final InventoryRepository _repository;

  Future<Result<InventoryDashboard>> call() => _repository.getDashboard();
}
