import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/organization/domain/entities/branch.dart';
import 'package:mobile/features/organization/domain/entities/department.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/domain/usecases/users_usecases.dart';

enum UsersDashboardStatus { initial, loading, success, failure }

class UsersDashboardState extends Equatable {
  const UsersDashboardState({
    this.status = UsersDashboardStatus.initial,
    this.dashboard,
    this.message,
    this.isRefreshing = false,
  });

  final UsersDashboardStatus status;
  final UsersDashboard? dashboard;
  final String? message;
  final bool isRefreshing;

  UsersDashboardState copyWith({
    UsersDashboardStatus? status,
    UsersDashboard? dashboard,
    String? message,
    bool? isRefreshing,
  }) {
    return UsersDashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, message, isRefreshing];
}

class UsersDashboardCubit extends Cubit<UsersDashboardState> {
  UsersDashboardCubit({
    required GetUsersDashboardUseCase getDashboard,
    required SessionQueryCache queryCache,
  })  : _getDashboard = getDashboard,
        _queryCache = queryCache,
        super(const UsersDashboardState());

  static const _cacheKey = 'users:dashboard';

  final GetUsersDashboardUseCase _getDashboard;
  final SessionQueryCache _queryCache;

  Future<void> load() async {
    final cached = _queryCache.get<UsersDashboard>(_cacheKey);
    if (cached != null) {
      emit(UsersDashboardState(
        status: UsersDashboardStatus.success,
        dashboard: cached,
        isRefreshing: true,
      ));
    } else if (state.dashboard != null) {
      emit(state.copyWith(
        status: UsersDashboardStatus.success,
        isRefreshing: true,
      ));
    } else {
      emit(const UsersDashboardState(status: UsersDashboardStatus.loading));
    }

    final result = await _getDashboard();
    switch (result) {
      case Success(data: final data):
        _queryCache.set(_cacheKey, data);
        emit(UsersDashboardState(
          status: UsersDashboardStatus.success,
          dashboard: data,
        ));
      case Failure(message: final message):
        if (state.dashboard != null) {
          emit(UsersDashboardState(
            status: UsersDashboardStatus.success,
            dashboard: state.dashboard,
            message: message,
          ));
        } else {
          emit(UsersDashboardState(
            status: UsersDashboardStatus.failure,
            message: message,
          ));
        }
    }
  }
}

enum UsersListStatus { initial, loading, loadingMore, success, failure }

class UsersListState extends Equatable {
  const UsersListState({
    this.status = UsersListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.filterStatus,
    this.message,
    this.isRefreshing = false,
  });

  final UsersListStatus status;
  final List<ManagedUser> items;
  final int page;
  final bool hasMore;
  final String search;
  final ManagedUserStatus? filterStatus;
  final String? message;
  final bool isRefreshing;

  UsersListState copyWith({
    UsersListStatus? status,
    List<ManagedUser>? items,
    int? page,
    bool? hasMore,
    String? search,
    ManagedUserStatus? filterStatus,
    bool clearFilterStatus = false,
    String? message,
    bool? isRefreshing,
  }) {
    return UsersListState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, page, hasMore, search, filterStatus, message, isRefreshing];
}

class UsersListCubit extends Cubit<UsersListState> {
  UsersListCubit({
    required ListManagedUsersUseCase listUsers,
    required SessionQueryCache queryCache,
  })  : _listUsers = listUsers,
        _queryCache = queryCache,
        super(const UsersListState());

  static const int _pageSize = 20;
  final ListManagedUsersUseCase _listUsers;
  final SessionQueryCache _queryCache;

  String _cacheKey({
    required String search,
    ManagedUserStatus? status,
  }) =>
      'users:list:p1:s=$search:st=${status?.apiValue ?? ''}';

  Future<void> loadFirstPage({
    String? search,
    ManagedUserStatus? status,
    bool clearStatus = false,
  }) async {
    final nextSearch = search ?? state.search;
    final nextStatus = clearStatus ? null : (status ?? state.filterStatus);
    final key = _cacheKey(search: nextSearch, status: nextStatus);
    final cached = _queryCache.get<ManagedUserPage>(key);

    if (cached != null) {
      emit(UsersListState(
        status: UsersListStatus.success,
        items: cached.items,
        page: cached.page,
        hasMore: cached.hasMore,
        search: nextSearch,
        filterStatus: nextStatus,
        isRefreshing: true,
      ));
    } else if (state.items.isNotEmpty) {
      emit(state.copyWith(
        status: UsersListStatus.success,
        search: nextSearch,
        filterStatus: nextStatus,
        clearFilterStatus: nextStatus == null,
        isRefreshing: true,
      ));
    } else {
      emit(UsersListState(
        status: UsersListStatus.loading,
        search: nextSearch,
        filterStatus: nextStatus,
      ));
    }

    final result = await _listUsers(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
      status: nextStatus,
    );
    switch (result) {
      case Success(data: final page):
        _queryCache.set(key, page);
        emit(UsersListState(
          status: UsersListStatus.success,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          search: nextSearch,
          filterStatus: nextStatus,
        ));
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(state.copyWith(
            status: UsersListStatus.success,
            search: nextSearch,
            filterStatus: nextStatus,
            clearFilterStatus: nextStatus == null,
            message: message,
            isRefreshing: false,
          ));
        } else {
          emit(UsersListState(
            status: UsersListStatus.failure,
            search: nextSearch,
            filterStatus: nextStatus,
            message: message,
          ));
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == UsersListStatus.loading ||
        state.status == UsersListStatus.loadingMore ||
        state.isRefreshing) {
      return;
    }
    emit(state.copyWith(status: UsersListStatus.loadingMore));
    final result = await _listUsers(
      page: state.page + 1,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
      status: state.filterStatus,
    );
    switch (result) {
      case Success(data: final page):
        emit(state.copyWith(
          status: UsersListStatus.success,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          status: UsersListStatus.success,
          message: message,
        ));
    }
  }

  Future<void> setFilter(ManagedUserStatus? status) =>
      loadFirstPage(status: status, clearStatus: status == null);

  Future<void> search(String value) => loadFirstPage(search: value);
}

enum UserDetailStatus { initial, loading, success, failure }

class UserDetailState extends Equatable {
  const UserDetailState({
    this.status = UserDetailStatus.initial,
    this.user,
    this.message,
    this.isRefreshing = false,
  });

  final UserDetailStatus status;
  final ManagedUser? user;
  final String? message;
  final bool isRefreshing;

  UserDetailState copyWith({
    UserDetailStatus? status,
    ManagedUser? user,
    String? message,
    bool? isRefreshing,
  }) {
    return UserDetailState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, user, message, isRefreshing];
}

class UserDetailCubit extends Cubit<UserDetailState> {
  UserDetailCubit({
    required String userId,
    required GetManagedUserByIdUseCase getById,
    required SetManagedUserStatusUseCase setStatus,
    required DeleteManagedUserUseCase deleteUser,
    required ResetManagedUserPasswordUseCase resetPassword,
    required UploadUserAvatarUseCase uploadAvatar,
    required SessionQueryCache queryCache,
  })  : _userId = userId,
        _getById = getById,
        _setStatus = setStatus,
        _deleteUser = deleteUser,
        _resetPassword = resetPassword,
        _uploadAvatar = uploadAvatar,
        _queryCache = queryCache,
        super(const UserDetailState());

  final String _userId;
  final GetManagedUserByIdUseCase _getById;
  final SetManagedUserStatusUseCase _setStatus;
  final DeleteManagedUserUseCase _deleteUser;
  final ResetManagedUserPasswordUseCase _resetPassword;
  final UploadUserAvatarUseCase _uploadAvatar;
  final SessionQueryCache _queryCache;

  String get _cacheKey => 'users:detail:$_userId';

  Future<void> load() async {
    final cached = _queryCache.get<ManagedUser>(_cacheKey);
    if (cached != null) {
      emit(UserDetailState(
        status: UserDetailStatus.success,
        user: cached,
        isRefreshing: true,
      ));
    } else if (state.user != null) {
      emit(state.copyWith(
        status: UserDetailStatus.success,
        isRefreshing: true,
      ));
    } else {
      emit(const UserDetailState(status: UserDetailStatus.loading));
    }

    final result = await _getById(_userId);
    switch (result) {
      case Success(data: final user):
        _queryCache.set(_cacheKey, user);
        emit(UserDetailState(status: UserDetailStatus.success, user: user));
      case Failure(message: final message):
        if (state.user != null) {
          emit(UserDetailState(
            status: UserDetailStatus.success,
            user: state.user,
            message: message,
          ));
        } else {
          emit(UserDetailState(
            status: UserDetailStatus.failure,
            message: message,
          ));
        }
    }
  }

  Future<Result<ManagedUser>> setStatus(ManagedUserStatus status) async {
    final result = await _setStatus(_userId, status);
    if (result is Success<ManagedUser>) {
      _queryCache.invalidatePrefix('users:list:');
      _queryCache.invalidate('users:dashboard');
      await load();
    }
    return result;
  }

  Future<Result<ManagedUser>> delete() async {
    final result = await _deleteUser(_userId);
    if (result is Success<ManagedUser>) {
      _queryCache.invalidate(_cacheKey);
      _queryCache.invalidatePrefix('users:list:');
      _queryCache.invalidate('users:dashboard');
    }
    return result;
  }

  Future<Result<void>> resetPassword(String newPassword) =>
      _resetPassword(_userId, newPassword);

  Future<Result<ManagedUser>> uploadAvatar(AvatarUploadBytes avatar) async {
    final result = await _uploadAvatar(_userId, avatar);
    if (result is Success<ManagedUser>) await load();
    return result;
  }
}

enum UserFormStatus { initial, loading, saving, success, failure }

class UserFormState extends Equatable {
  const UserFormState({
    this.status = UserFormStatus.initial,
    this.user,
    this.branches = const [],
    this.departments = const [],
    this.message,
  });

  final UserFormStatus status;
  final ManagedUser? user;
  final List<Branch> branches;
  final List<Department> departments;
  final String? message;

  bool get isEditing => user != null;

  @override
  List<Object?> get props => [status, user, branches, departments, message];
}

class UserFormCubit extends Cubit<UserFormState> {
  UserFormCubit({
    required CreateManagedUserUseCase create,
    required UpdateManagedUserUseCase update,
    required GetManagedUserByIdUseCase getById,
    required OrganizationRepository organizationRepository,
    String? userId,
  })  : _create = create,
        _update = update,
        _getById = getById,
        _organizationRepository = organizationRepository,
        _userId = userId,
        super(const UserFormState());

  final CreateManagedUserUseCase _create;
  final UpdateManagedUserUseCase _update;
  final GetManagedUserByIdUseCase _getById;
  final OrganizationRepository _organizationRepository;
  final String? _userId;

  Future<void> load() async {
    emit(const UserFormState(status: UserFormStatus.loading));
    final branchesResult = await _organizationRepository.getBranches();
    final departmentsResult = await _organizationRepository.getDepartments();

    final branches = switch (branchesResult) {
      Success(data: final items) => items,
      Failure() => const <Branch>[],
    };
    final departments = switch (departmentsResult) {
      Success(data: final items) => items,
      Failure() => const <Department>[],
    };

    if (_userId == null || _userId.isEmpty) {
      emit(UserFormState(
        status: UserFormStatus.success,
        branches: branches,
        departments: departments,
      ));
      return;
    }

    final userResult = await _getById(_userId);
    switch (userResult) {
      case Success(data: final user):
        emit(UserFormState(
          status: UserFormStatus.success,
          user: user,
          branches: branches,
          departments: departments,
        ));
      case Failure(message: final message):
        emit(UserFormState(
          status: UserFormStatus.failure,
          branches: branches,
          departments: departments,
          message: message,
        ));
    }
  }

  Future<Result<ManagedUser>> save(ManagedUserUpsertInput input) async {
    emit(UserFormState(
      status: UserFormStatus.saving,
      user: state.user,
      branches: state.branches,
      departments: state.departments,
    ));
    final result = _userId == null || _userId.isEmpty
        ? await _create(input)
        : await _update(_userId, input);
    switch (result) {
      case Success(data: final user):
        emit(UserFormState(
          status: UserFormStatus.success,
          user: user,
          branches: state.branches,
          departments: state.departments,
        ));
      case Failure(message: final message):
        emit(UserFormState(
          status: UserFormStatus.failure,
          user: state.user,
          branches: state.branches,
          departments: state.departments,
          message: message,
        ));
    }
    return result;
  }
}

enum ChangePasswordStatus { initial, saving, success, failure }

class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    this.status = ChangePasswordStatus.initial,
    this.message,
  });

  final ChangePasswordStatus status;
  final String? message;

  @override
  List<Object?> get props => [status, message];
}

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit({required ChangeOwnPasswordUseCase changePassword})
      : _changePassword = changePassword,
        super(const ChangePasswordState());

  final ChangeOwnPasswordUseCase _changePassword;

  Future<Result<void>> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(const ChangePasswordState(status: ChangePasswordStatus.saving));
    final result = await _changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    switch (result) {
      case Success():
        emit(const ChangePasswordState(status: ChangePasswordStatus.success));
      case Failure(message: final message):
        emit(ChangePasswordState(
          status: ChangePasswordStatus.failure,
          message: message,
        ));
    }
    return result;
  }
}
