import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';
import 'package:mobile/features/global_search/domain/entities/global_search_hit.dart';

/// Searches existing module list APIs. Swap implementation only if a dedicated
/// search endpoint is introduced later.
abstract class GlobalSearchRepository {
  Future<Result<List<GlobalSearchHit>>> search({
    required String query,
    required PermissionChecker permissions,
  });
}
