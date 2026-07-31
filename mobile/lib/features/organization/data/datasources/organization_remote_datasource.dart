import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/organization/data/models/branch_model.dart';
import 'package:mobile/features/organization/data/models/company_model.dart';
import 'package:mobile/features/organization/data/models/department_model.dart';
import 'package:mobile/features/organization/data/models/organization_context_model.dart';
import 'package:mobile/features/organization/data/models/organization_summary_model.dart';
import 'package:mobile/features/organization/data/models/position_model.dart';
import 'package:mobile/features/organization/data/models/team_model.dart';
import 'package:mobile/features/organization/data/models/user_summary_model.dart';

class OrganizationRemoteDataSource {
  OrganizationRemoteDataSource(this._client);

  final DioClient _client;

  Future<OrganizationContextModel> getMyContext() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.organizationContext,
    );
    final data = response.data?['data'] as Map<String, dynamic>;
    return OrganizationContextModel.fromJson(data);
  }

  Future<OrganizationSummaryModel> getSummary() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.organizationSummary,
    );
    final data = response.data?['data'] as Map<String, dynamic>;
    return OrganizationSummaryModel.fromJson(data);
  }

  Future<List<CompanyModel>> getCompanies() async {
    return _getList(
      ApiConstants.organizationsCompanies,
      CompanyModel.fromJson,
    );
  }

  Future<List<BranchModel>> getBranches({String? search}) async {
    return _getList(
      ApiConstants.organizationBranches,
      BranchModel.fromJson,
      queryParameters: _searchQuery(search),
    );
  }

  Future<List<DepartmentModel>> getDepartments({String? search}) async {
    return _getList(
      ApiConstants.organizationDepartments,
      DepartmentModel.fromJson,
      queryParameters: _searchQuery(search),
    );
  }

  Future<List<TeamModel>> getTeams({String? search}) async {
    return _getList(
      ApiConstants.organizationTeams,
      TeamModel.fromJson,
      queryParameters: _searchQuery(search),
    );
  }

  Future<List<PositionModel>> getPositions({String? search}) async {
    return _getList(
      ApiConstants.organizationPositions,
      PositionModel.fromJson,
      queryParameters: _searchQuery(search),
    );
  }

  Future<List<UserSummaryModel>> getUsers({String? search}) async {
    return _getList(
      ApiConstants.organizationUsers,
      UserSummaryModel.fromJson,
      queryParameters: _searchQuery(search),
    );
  }

  Map<String, dynamic>? _searchQuery(String? search) {
    if (search == null || search.trim().isEmpty) {
      return null;
    }
    return {'search': search.trim()};
  }

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic> json) mapper, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    final data = response.data?['data'];
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(mapper)
        .toList();
  }
}
