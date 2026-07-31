import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/organization/data/cache/organization_cache_keys.dart';
import 'package:mobile/features/organization/data/cache/organization_memory_cache.dart';
import 'package:mobile/features/organization/data/datasources/organization_local_datasource.dart';
import 'package:mobile/features/organization/data/datasources/organization_remote_datasource.dart';
import 'package:mobile/features/organization/data/models/branch_model.dart';
import 'package:mobile/features/organization/data/models/company_model.dart';
import 'package:mobile/features/organization/data/models/department_model.dart';
import 'package:mobile/features/organization/data/models/organization_context_model.dart';
import 'package:mobile/features/organization/data/models/organization_summary_model.dart';
import 'package:mobile/features/organization/data/models/position_model.dart';
import 'package:mobile/features/organization/data/models/team_model.dart';
import 'package:mobile/features/organization/data/models/user_summary_model.dart';
import 'package:mobile/features/organization/domain/entities/branch.dart';
import 'package:mobile/features/organization/domain/entities/company.dart';
import 'package:mobile/features/organization/domain/entities/department.dart';
import 'package:mobile/features/organization/domain/entities/organization_context.dart';
import 'package:mobile/features/organization/domain/entities/organization_summary.dart';
import 'package:mobile/features/organization/domain/entities/position.dart';
import 'package:mobile/features/organization/domain/entities/team.dart';
import 'package:mobile/features/organization/domain/entities/user_summary.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  OrganizationRepositoryImpl({
    required this._remote,
    required this._local,
    required this._memoryCache,
    required this._connectivity,
  });

  final OrganizationRemoteDataSource _remote;
  final OrganizationLocalDataSource _local;
  final OrganizationMemoryCache _memoryCache;
  final ConnectivityService _connectivity;

  @override
  Future<Result<OrganizationContext>> getMyContext({
    bool forceRefresh = false,
  }) async {
    return _loadEntity<OrganizationContext, OrganizationContextModel>(
      memoryKey: OrganizationCacheKeys.context,
      forceRefresh: forceRefresh,
      readLocal: _local.readContext,
      fetchRemote: _remote.getMyContext,
      writeLocal: _local.saveContext,
    );
  }

  @override
  Future<Result<OrganizationSummary>> getSummary({
    bool forceRefresh = false,
  }) async {
    return _loadEntity<OrganizationSummary, OrganizationSummaryModel>(
      memoryKey: OrganizationCacheKeys.summary,
      forceRefresh: forceRefresh,
      readLocal: _local.readSummary,
      fetchRemote: _remote.getSummary,
      writeLocal: _local.saveSummary,
    );
  }

  @override
  Future<Result<List<Company>>> getCompanies({bool forceRefresh = false}) {
    return _loadEntityList<Company, CompanyModel>(
      memoryKey: OrganizationCacheKeys.companies,
      forceRefresh: forceRefresh,
      readLocal: _local.readCompanies,
      fetchRemote: _remote.getCompanies,
      writeLocal: _local.saveCompanies,
    );
  }

  @override
  Future<Result<List<Branch>>> getBranches({
    String? search,
    bool forceRefresh = false,
  }) {
    return _loadEntityList<Branch, BranchModel>(
      memoryKey: OrganizationCacheKeys.branches,
      forceRefresh: forceRefresh,
      readLocal: _local.readBranches,
      fetchRemote: () => _remote.getBranches(search: search),
      writeLocal: search == null || search.isEmpty ? _local.saveBranches : null,
      filter: (items) =>
          _filterBySearch(items, search, (item) => [item.name, item.code]),
    );
  }

  @override
  Future<Result<List<Department>>> getDepartments({
    String? search,
    bool forceRefresh = false,
  }) {
    return _loadEntityList<Department, DepartmentModel>(
      memoryKey: OrganizationCacheKeys.departments,
      forceRefresh: forceRefresh,
      readLocal: _local.readDepartments,
      fetchRemote: () => _remote.getDepartments(search: search),
      writeLocal:
          search == null || search.isEmpty ? _local.saveDepartments : null,
      filter: (items) =>
          _filterBySearch(items, search, (item) => [item.name, item.code]),
    );
  }

  @override
  Future<Result<List<Team>>> getTeams({
    String? search,
    bool forceRefresh = false,
  }) {
    return _loadEntityList<Team, TeamModel>(
      memoryKey: OrganizationCacheKeys.teams,
      forceRefresh: forceRefresh,
      readLocal: _local.readTeams,
      fetchRemote: () => _remote.getTeams(search: search),
      writeLocal: search == null || search.isEmpty ? _local.saveTeams : null,
      filter: (items) =>
          _filterBySearch(items, search, (item) => [item.name, item.code]),
    );
  }

  @override
  Future<Result<List<Position>>> getPositions({
    String? search,
    bool forceRefresh = false,
  }) {
    return _loadEntityList<Position, PositionModel>(
      memoryKey: OrganizationCacheKeys.positions,
      forceRefresh: forceRefresh,
      readLocal: _local.readPositions,
      fetchRemote: () => _remote.getPositions(search: search),
      writeLocal:
          search == null || search.isEmpty ? _local.savePositions : null,
      filter: (items) =>
          _filterBySearch(items, search, (item) => [item.name, item.code]),
    );
  }

  @override
  Future<Result<List<UserSummary>>> getUsers({
    String? search,
    bool forceRefresh = false,
  }) {
    return _loadEntityList<UserSummary, UserSummaryModel>(
      memoryKey: OrganizationCacheKeys.users,
      forceRefresh: forceRefresh,
      readLocal: _local.readUsers,
      fetchRemote: () => _remote.getUsers(search: search),
      writeLocal: search == null || search.isEmpty ? _local.saveUsers : null,
      filter: (items) => _filterBySearch(
        items,
        search,
        (item) => [item.name, item.email, item.code, item.employeeId ?? ''],
      ),
    );
  }

  Future<Result<TEntity>> _loadEntity<TEntity extends Object, TModel extends TEntity>({
    required String memoryKey,
    required bool forceRefresh,
    required TModel? Function() readLocal,
    required Future<TModel> Function() fetchRemote,
    required Future<void> Function(TModel value) writeLocal,
  }) async {
    if (!forceRefresh) {
      final memory = _memoryCache.get<TEntity>(memoryKey);
      if (memory != null) {
        return Success(memory);
      }
    }

    final isOnline = await _connectivity.isConnected;
    if (!isOnline) {
      final local = readLocal();
      if (local != null) {
        _memoryCache.set(memoryKey, local);
        return Success(local);
      }
      return const Failure(
        'errorNoInternet',
        code: 'OFFLINE',
      );
    }

    try {
      final remote = await fetchRemote();
      _memoryCache.set(memoryKey, remote);
      await writeLocal(remote);
      return Success(remote);
    } on Object catch (error) {
      final local = readLocal();
      if (local != null) {
        _memoryCache.set(memoryKey, local);
        return Success(local);
      }
      return NetworkErrorMapper.map(error);
    }
  }

  Future<Result<List<TEntity>>> _loadEntityList<TEntity extends Object,
      TModel extends TEntity>({
    required String memoryKey,
    required bool forceRefresh,
    required List<TModel> Function() readLocal,
    required Future<List<TModel>> Function() fetchRemote,
    required Future<void> Function(List<TModel> value)? writeLocal,
    List<TEntity> Function(List<TEntity> items)? filter,
  }) async {
    if (!forceRefresh) {
      final memory = _memoryCache.get<List<TEntity>>(memoryKey);
      if (memory != null) {
        return Success(filter?.call(memory) ?? memory);
      }
    }

    final isOnline = await _connectivity.isConnected;
    if (!isOnline) {
      final local = readLocal();
      if (local.isNotEmpty) {
        _memoryCache.set(memoryKey, local);
        return Success(filter?.call(local) ?? local);
      }
      return const Failure(
        'errorNoInternet',
        code: 'OFFLINE',
      );
    }

    try {
      final remote = await fetchRemote();
      if (writeLocal != null) {
        await writeLocal(remote);
        _memoryCache.set(memoryKey, remote);
      }
      return Success(remote);
    } on Object catch (error) {
      final local = readLocal();
      if (local.isNotEmpty) {
        _memoryCache.set(memoryKey, local);
        return Success(filter?.call(local) ?? local);
      }
      return NetworkErrorMapper.map(error);
    }
  }

  List<T> _filterBySearch<T>(
    List<T> items,
    String? search,
    List<String> Function(T item) fields,
  ) {
    final query = search?.trim().toLowerCase();
    if (query == null || query.isEmpty) {
      return items;
    }
    return items.where((item) {
      return fields(item).any((field) => field.toLowerCase().contains(query));
    }).toList();
  }
}
