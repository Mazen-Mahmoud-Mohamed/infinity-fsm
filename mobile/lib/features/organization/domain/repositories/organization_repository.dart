import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/organization/domain/entities/branch.dart';
import 'package:mobile/features/organization/domain/entities/company.dart';
import 'package:mobile/features/organization/domain/entities/department.dart';
import 'package:mobile/features/organization/domain/entities/organization_context.dart';
import 'package:mobile/features/organization/domain/entities/organization_summary.dart';
import 'package:mobile/features/organization/domain/entities/position.dart';
import 'package:mobile/features/organization/domain/entities/team.dart';
import 'package:mobile/features/organization/domain/entities/user_summary.dart';

abstract class OrganizationRepository {
  Future<Result<OrganizationContext>> getMyContext({bool forceRefresh = false});

  Future<Result<OrganizationSummary>> getSummary({bool forceRefresh = false});

  Future<Result<List<Company>>> getCompanies({bool forceRefresh = false});

  Future<Result<List<Branch>>> getBranches({
    String? search,
    bool forceRefresh = false,
  });

  Future<Result<List<Department>>> getDepartments({
    String? search,
    bool forceRefresh = false,
  });

  Future<Result<List<Team>>> getTeams({
    String? search,
    bool forceRefresh = false,
  });

  Future<Result<List<Position>>> getPositions({
    String? search,
    bool forceRefresh = false,
  });

  Future<Result<List<UserSummary>>> getUsers({
    String? search,
    bool forceRefresh = false,
  });
}
