import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/roles/domain/entities/role_entities.dart';
import 'package:mobile/features/roles/domain/usecases/roles_usecases.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/domain/usecases/users_usecases.dart';

enum RolesDashboardStatus { initial, loading, success, failure }

class RolesDashboardState extends Equatable {
  const RolesDashboardState({
    this.status = RolesDashboardStatus.initial,
    this.dashboard,
    this.message,
    this.isRefreshing = false,
  });

  final RolesDashboardStatus status;
  final RolesDashboard? dashboard;
  final String? message;
  final bool isRefreshing;

  RolesDashboardState copyWith({
    RolesDashboardStatus? status,
    RolesDashboard? dashboard,
    String? message,
    bool? isRefreshing,
  }) {
    return RolesDashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, message, isRefreshing];
}

class RolesDashboardCubit extends Cubit<RolesDashboardState> {
  RolesDashboardCubit({
    required GetRolesDashboardUseCase getDashboard,
    required SessionQueryCache queryCache,
  })  : _getDashboard = getDashboard,
        _queryCache = queryCache,
        super(const RolesDashboardState());

  static const _cacheKey = 'roles:dashboard';

  final GetRolesDashboardUseCase _getDashboard;
  final SessionQueryCache _queryCache;

  Future<void> load() async {
    final cached = _queryCache.get<RolesDashboard>(_cacheKey);
    if (cached != null) {
      emit(RolesDashboardState(
        status: RolesDashboardStatus.success,
        dashboard: cached,
        isRefreshing: true,
      ));
    } else if (state.dashboard != null) {
      emit(state.copyWith(
        status: RolesDashboardStatus.success,
        isRefreshing: true,
      ));
    } else {
      emit(const RolesDashboardState(status: RolesDashboardStatus.loading));
    }

    final result = await _getDashboard();
    switch (result) {
      case Success(data: final data):
        _queryCache.set(_cacheKey, data);
        emit(RolesDashboardState(
          status: RolesDashboardStatus.success,
          dashboard: data,
        ));
      case Failure(message: final message):
        if (state.dashboard != null) {
          emit(RolesDashboardState(
            status: RolesDashboardStatus.success,
            dashboard: state.dashboard,
            message: message,
          ));
        } else {
          emit(RolesDashboardState(
            status: RolesDashboardStatus.failure,
            message: message,
          ));
        }
    }
  }
}

enum RolesListStatus { initial, loading, loadingMore, success, failure }

class RolesListState extends Equatable {
  const RolesListState({
    this.status = RolesListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.filterActive,
    this.filterSystem,
    this.message,
    this.isRefreshing = false,
  });

  final RolesListStatus status;
  final List<RoleEntity> items;
  final int page;
  final bool hasMore;
  final String search;
  final bool? filterActive;
  final bool? filterSystem;
  final String? message;
  final bool isRefreshing;

  RolesListState copyWith({
    RolesListStatus? status,
    List<RoleEntity>? items,
    int? page,
    bool? hasMore,
    String? search,
    bool? filterActive,
    bool clearFilterActive = false,
    bool? filterSystem,
    bool clearFilterSystem = false,
    String? message,
    bool? isRefreshing,
  }) {
    return RolesListState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      filterActive:
          clearFilterActive ? null : (filterActive ?? this.filterActive),
      filterSystem:
          clearFilterSystem ? null : (filterSystem ?? this.filterSystem),
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        page,
        hasMore,
        search,
        filterActive,
        filterSystem,
        message,
        isRefreshing,
      ];
}

class RolesListCubit extends Cubit<RolesListState> {
  RolesListCubit({
    required ListRolesUseCase listRoles,
    required SessionQueryCache queryCache,
  })  : _listRoles = listRoles,
        _queryCache = queryCache,
        super(const RolesListState());

  static const int _pageSize = 20;
  final ListRolesUseCase _listRoles;
  final SessionQueryCache _queryCache;

  String _cacheKey({
    required String search,
    bool? isActive,
    bool? isSystem,
  }) =>
      'roles:list:p1:s=$search:active=${isActive ?? ''}:system=${isSystem ?? ''}';

  Future<void> loadFirstPage({
    String? search,
    bool? isActive,
    bool clearActive = false,
    bool? isSystem,
    bool clearSystem = false,
  }) async {
    final nextSearch = search ?? state.search;
    final nextActive = clearActive ? null : (isActive ?? state.filterActive);
    final nextSystem = clearSystem ? null : (isSystem ?? state.filterSystem);
    final key = _cacheKey(
      search: nextSearch,
      isActive: nextActive,
      isSystem: nextSystem,
    );
    final cached = _queryCache.get<RolePage>(key);

    if (cached != null) {
      emit(RolesListState(
        status: RolesListStatus.success,
        items: cached.items,
        page: cached.page,
        hasMore: cached.hasMore,
        search: nextSearch,
        filterActive: nextActive,
        filterSystem: nextSystem,
        isRefreshing: true,
      ));
    } else if (state.items.isNotEmpty) {
      emit(state.copyWith(
        status: RolesListStatus.success,
        search: nextSearch,
        filterActive: nextActive,
        clearFilterActive: nextActive == null,
        filterSystem: nextSystem,
        clearFilterSystem: nextSystem == null,
        isRefreshing: true,
      ));
    } else {
      emit(RolesListState(
        status: RolesListStatus.loading,
        search: nextSearch,
        filterActive: nextActive,
        filterSystem: nextSystem,
      ));
    }

    final result = await _listRoles(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
      isActive: nextActive,
      isSystem: nextSystem,
    );
    switch (result) {
      case Success(data: final page):
        _queryCache.set(key, page);
        emit(RolesListState(
          status: RolesListStatus.success,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          search: nextSearch,
          filterActive: nextActive,
          filterSystem: nextSystem,
        ));
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(state.copyWith(
            status: RolesListStatus.success,
            search: nextSearch,
            filterActive: nextActive,
            clearFilterActive: nextActive == null,
            filterSystem: nextSystem,
            clearFilterSystem: nextSystem == null,
            message: message,
            isRefreshing: false,
          ));
        } else {
          emit(RolesListState(
            status: RolesListStatus.failure,
            search: nextSearch,
            filterActive: nextActive,
            filterSystem: nextSystem,
            message: message,
          ));
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == RolesListStatus.loading ||
        state.status == RolesListStatus.loadingMore ||
        state.isRefreshing) {
      return;
    }
    emit(state.copyWith(status: RolesListStatus.loadingMore));
    final nextPage = state.page + 1;
    final result = await _listRoles(
      page: nextPage,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
      isActive: state.filterActive,
      isSystem: state.filterSystem,
    );
    switch (result) {
      case Success(data: final page):
        emit(state.copyWith(
          status: RolesListStatus.success,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          status: RolesListStatus.success,
          message: message,
        ));
    }
  }
}

class _RoleDetailCache {
  const _RoleDetailCache({required this.role, required this.users});

  final RoleEntity role;
  final List<RoleUserRef> users;
}

enum RoleDetailStatus { initial, loading, success, failure, mutating }

class RoleDetailState extends Equatable {
  const RoleDetailState({
    this.status = RoleDetailStatus.initial,
    this.role,
    this.users = const [],
    this.message,
    this.isRefreshing = false,
  });

  final RoleDetailStatus status;
  final RoleEntity? role;
  final List<RoleUserRef> users;
  final String? message;
  final bool isRefreshing;

  @override
  List<Object?> get props => [status, role, users, message, isRefreshing];
}

class RoleDetailCubit extends Cubit<RoleDetailState> {
  RoleDetailCubit({
    required GetRoleByIdUseCase getRole,
    required ListRoleUsersUseCase listUsers,
    required SetRoleStatusUseCase setStatus,
    required DeleteRoleUseCase deleteRole,
    required CloneRoleUseCase cloneRole,
    required SessionQueryCache queryCache,
  })  : _getRole = getRole,
        _listUsers = listUsers,
        _setStatus = setStatus,
        _deleteRole = deleteRole,
        _cloneRole = cloneRole,
        _queryCache = queryCache,
        super(const RoleDetailState());

  final GetRoleByIdUseCase _getRole;
  final ListRoleUsersUseCase _listUsers;
  final SetRoleStatusUseCase _setStatus;
  final DeleteRoleUseCase _deleteRole;
  final CloneRoleUseCase _cloneRole;
  final SessionQueryCache _queryCache;

  String _cacheKey(String id) => 'roles:detail:$id';

  Future<void> load(String id) async {
    final cached = _queryCache.get<_RoleDetailCache>(_cacheKey(id));
    if (cached != null) {
      emit(RoleDetailState(
        status: RoleDetailStatus.success,
        role: cached.role,
        users: cached.users,
        isRefreshing: true,
      ));
    } else if (state.role != null && state.role!.id == id) {
      emit(RoleDetailState(
        status: RoleDetailStatus.success,
        role: state.role,
        users: state.users,
        isRefreshing: true,
      ));
    } else {
      emit(const RoleDetailState(status: RoleDetailStatus.loading));
    }

    final roleResult = await _getRole(id);
    switch (roleResult) {
      case Failure(message: final message):
        if (state.role != null) {
          emit(RoleDetailState(
            status: RoleDetailStatus.success,
            role: state.role,
            users: state.users,
            message: message,
          ));
        } else {
          emit(RoleDetailState(
            status: RoleDetailStatus.failure,
            message: message,
          ));
        }
        return;
      case Success(data: final role):
        final usersResult = await _listUsers(id, limit: 10);
        final users = switch (usersResult) {
          Success(data: final page) => page.items,
          Failure() => state.users,
        };
        _queryCache.set(
          _cacheKey(id),
          _RoleDetailCache(role: role, users: users),
        );
        emit(RoleDetailState(
          status: RoleDetailStatus.success,
          role: role,
          users: users,
        ));
    }
  }

  Future<Result<RoleEntity>> toggleActive() async {
    final role = state.role;
    if (role == null) {
      return const Failure('rolesNotLoaded');
    }
    emit(RoleDetailState(
      status: RoleDetailStatus.mutating,
      role: role,
      users: state.users,
    ));
    final result = await _setStatus(role.id, !role.isActive);
    switch (result) {
      case Success(data: final updated):
        _queryCache.set(
          _cacheKey(updated.id),
          _RoleDetailCache(role: updated, users: state.users),
        );
        _queryCache.invalidatePrefix('roles:list:');
        _queryCache.invalidate('roles:dashboard');
        emit(RoleDetailState(
          status: RoleDetailStatus.success,
          role: updated,
          users: state.users,
        ));
      case Failure(message: final message):
        emit(RoleDetailState(
          status: RoleDetailStatus.failure,
          role: role,
          users: state.users,
          message: message,
        ));
    }
    return result;
  }

  Future<Result<void>> delete() async {
    final role = state.role;
    if (role == null) {
      return const Failure('rolesNotLoaded');
    }
    emit(RoleDetailState(
      status: RoleDetailStatus.mutating,
      role: role,
      users: state.users,
    ));
    final result = await _deleteRole(role.id);
    if (result case Failure(:final message)) {
      emit(RoleDetailState(
        status: RoleDetailStatus.failure,
        role: role,
        users: state.users,
        message: message,
      ));
    } else {
      _queryCache.invalidate(_cacheKey(role.id));
      _queryCache.invalidatePrefix('roles:list:');
      _queryCache.invalidate('roles:dashboard');
    }
    return result;
  }

  Future<Result<RoleEntity>> clone({String? name}) async {
    final role = state.role;
    if (role == null) {
      return const Failure('rolesNotLoaded');
    }
    emit(RoleDetailState(
      status: RoleDetailStatus.mutating,
      role: role,
      users: state.users,
    ));
    final result = await _cloneRole(role.id, name: name);
    final failureMessage = switch (result) {
      Failure(:final message) => message,
      Success() => null,
    };
    if (result is Success<RoleEntity>) {
      _queryCache.invalidatePrefix('roles:list:');
      _queryCache.invalidate('roles:dashboard');
    }
    emit(RoleDetailState(
      status: RoleDetailStatus.success,
      role: role,
      users: state.users,
      message: failureMessage,
    ));
    return result;
  }
}

enum RoleFormStatus { initial, loading, ready, saving, success, failure }

class RoleFormState extends Equatable {
  const RoleFormState({
    this.status = RoleFormStatus.initial,
    this.role,
    this.catalog = const [],
    this.message,
    this.savedRole,
  });

  final RoleFormStatus status;
  final RoleEntity? role;
  final List<PermissionCatalogItem> catalog;
  final String? message;
  final RoleEntity? savedRole;

  @override
  List<Object?> get props => [status, role, catalog, message, savedRole];
}

class RoleFormCubit extends Cubit<RoleFormState> {
  RoleFormCubit({
    required GetRoleByIdUseCase getRole,
    required GetPermissionCatalogUseCase getCatalog,
    required CreateRoleUseCase createRole,
    required UpdateRoleUseCase updateRole,
  })  : _getRole = getRole,
        _getCatalog = getCatalog,
        _createRole = createRole,
        _updateRole = updateRole,
        super(const RoleFormState());

  final GetRoleByIdUseCase _getRole;
  final GetPermissionCatalogUseCase _getCatalog;
  final CreateRoleUseCase _createRole;
  final UpdateRoleUseCase _updateRole;

  Future<void> load({String? roleId}) async {
    emit(const RoleFormState(status: RoleFormStatus.loading));
    final catalogResult = await _getCatalog();
    final catalog = switch (catalogResult) {
      Success(data: final items) => items,
      Failure() => const <PermissionCatalogItem>[],
    };

    if (roleId == null) {
      emit(RoleFormState(status: RoleFormStatus.ready, catalog: catalog));
      return;
    }

    final roleResult = await _getRole(roleId);
    switch (roleResult) {
      case Success(data: final role):
        emit(RoleFormState(
          status: RoleFormStatus.ready,
          role: role,
          catalog: catalog,
        ));
      case Failure(message: final message):
        emit(RoleFormState(
          status: RoleFormStatus.failure,
          catalog: catalog,
          message: message,
        ));
    }
  }

  Future<Result<RoleEntity>> save(RoleUpsertInput input) async {
    final existing = state.role;
    emit(RoleFormState(
      status: RoleFormStatus.saving,
      role: existing,
      catalog: state.catalog,
    ));
    final result = existing == null
        ? await _createRole(input)
        : await _updateRole(existing.id, input);
    switch (result) {
      case Success(data: final role):
        emit(RoleFormState(
          status: RoleFormStatus.success,
          role: role,
          catalog: state.catalog,
          savedRole: role,
        ));
      case Failure(message: final message):
        emit(RoleFormState(
          status: RoleFormStatus.failure,
          role: existing,
          catalog: state.catalog,
          message: message,
        ));
    }
    return result;
  }
}

enum AssignUsersStatus { initial, loading, saving, success, failure }

class AssignUsersState extends Equatable {
  const AssignUsersState({
    this.status = AssignUsersStatus.initial,
    this.candidates = const [],
    this.selectedIds = const {},
    this.search = '',
    this.message,
    this.isRefreshing = false,
  });

  final AssignUsersStatus status;
  final List<ManagedUser> candidates;
  final Set<String> selectedIds;
  final String search;
  final String? message;
  final bool isRefreshing;

  @override
  List<Object?> get props =>
      [status, candidates, selectedIds, search, message, isRefreshing];
}

class AssignUsersCubit extends Cubit<AssignUsersState> {
  AssignUsersCubit({
    required ListManagedUsersUseCase listUsers,
    required AssignRoleToUsersUseCase assignUsers,
    required SessionQueryCache queryCache,
  })  : _listUsers = listUsers,
        _assignUsers = assignUsers,
        _queryCache = queryCache,
        super(const AssignUsersState());

  final ListManagedUsersUseCase _listUsers;
  final AssignRoleToUsersUseCase _assignUsers;
  final SessionQueryCache _queryCache;

  String _cacheKey(String search) =>
      'roles:assignUsers:p1:s=$search:st=${ManagedUserStatus.active.apiValue}';

  Future<void> load({String? search}) async {
    final nextSearch = search ?? state.search;
    final key = _cacheKey(nextSearch);
    final cached = _queryCache.get<ManagedUserPage>(key);

    if (cached != null) {
      emit(AssignUsersState(
        status: AssignUsersStatus.success,
        candidates: cached.items,
        selectedIds: state.selectedIds,
        search: nextSearch,
        isRefreshing: true,
      ));
    } else if (state.candidates.isNotEmpty) {
      emit(AssignUsersState(
        status: AssignUsersStatus.success,
        candidates: state.candidates,
        selectedIds: state.selectedIds,
        search: nextSearch,
        isRefreshing: true,
      ));
    } else {
      emit(AssignUsersState(
        status: AssignUsersStatus.loading,
        search: nextSearch,
        selectedIds: state.selectedIds,
      ));
    }

    final result = await _listUsers(
      page: 1,
      limit: 50,
      search: nextSearch.isEmpty ? null : nextSearch,
      status: ManagedUserStatus.active,
    );
    switch (result) {
      case Success(data: final page):
        _queryCache.set(key, page);
        emit(AssignUsersState(
          status: AssignUsersStatus.success,
          candidates: page.items,
          selectedIds: state.selectedIds,
          search: nextSearch,
        ));
      case Failure(message: final message):
        if (state.candidates.isNotEmpty) {
          emit(AssignUsersState(
            status: AssignUsersStatus.success,
            candidates: state.candidates,
            selectedIds: state.selectedIds,
            search: nextSearch,
            message: message,
          ));
        } else {
          emit(AssignUsersState(
            status: AssignUsersStatus.failure,
            search: nextSearch,
            selectedIds: state.selectedIds,
            message: message,
          ));
        }
    }
  }

  void toggle(String userId) {
    final next = Set<String>.from(state.selectedIds);
    if (next.contains(userId)) {
      next.remove(userId);
    } else {
      next.add(userId);
    }
    emit(AssignUsersState(
      status: state.status,
      candidates: state.candidates,
      selectedIds: next,
      search: state.search,
    ));
  }

  Future<Result<RoleAssignResult>> submit(String roleId) async {
    if (state.selectedIds.isEmpty) {
      return const Failure('rolesSelectAtLeastOneUser');
    }
    emit(AssignUsersState(
      status: AssignUsersStatus.saving,
      candidates: state.candidates,
      selectedIds: state.selectedIds,
      search: state.search,
    ));
    final result = await _assignUsers(roleId, state.selectedIds.toList());
    switch (result) {
      case Success():
        _queryCache.invalidate('roles:detail:$roleId');
        _queryCache.invalidatePrefix('roles:list:');
        emit(AssignUsersState(
          status: AssignUsersStatus.success,
          candidates: state.candidates,
          selectedIds: const {},
          search: state.search,
        ));
      case Failure(message: final message):
        emit(AssignUsersState(
          status: AssignUsersStatus.failure,
          candidates: state.candidates,
          selectedIds: state.selectedIds,
          search: state.search,
          message: message,
        ));
    }
    return result;
  }
}
