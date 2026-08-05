import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';
import 'package:mobile/features/global_search/domain/entities/global_search_hit.dart';
import 'package:mobile/features/global_search/domain/repositories/global_search_repository.dart';

class SearchGloballyUseCase {
  SearchGloballyUseCase(this._repository);

  final GlobalSearchRepository _repository;

  Future<Result<List<GlobalSearchHit>>> call({
    required String query,
    required PermissionChecker permissions,
  }) {
    return _repository.search(
      query: query,
      permissions: permissions,
    );
  }
}
