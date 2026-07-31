import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/organization/domain/entities/branch.dart';
import 'package:mobile/features/organization/domain/entities/company.dart';
import 'package:mobile/features/organization/domain/entities/department.dart';
import 'package:mobile/features/organization/domain/entities/organization_context.dart';
import 'package:mobile/features/organization/domain/entities/organization_summary.dart';
import 'package:mobile/features/organization/domain/entities/position.dart';
import 'package:mobile/features/organization/domain/entities/team.dart';
import 'package:mobile/features/organization/domain/entities/user_summary.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';

enum OrganizationStatus {
  initial,
  loading,
  success,
  failure,
}

class OrganizationState extends Equatable {
  const OrganizationState({
    this.status = OrganizationStatus.initial,
    this.context,
    this.summary,
    this.companies = const [],
    this.branches = const [],
    this.departments = const [],
    this.teams = const [],
    this.positions = const [],
    this.users = const [],
    this.searchQuery = '',
    this.isOffline = false,
    this.message,
    this.isRefreshing = false,
  });

  final OrganizationStatus status;
  final OrganizationContext? context;
  final OrganizationSummary? summary;
  final List<Company> companies;
  final List<Branch> branches;
  final List<Department> departments;
  final List<Team> teams;
  final List<Position> positions;
  final List<UserSummary> users;
  final String searchQuery;
  final bool isOffline;
  final String? message;
  final bool isRefreshing;

  OrganizationState copyWith({
    OrganizationStatus? status,
    OrganizationContext? context,
    OrganizationSummary? summary,
    List<Company>? companies,
    List<Branch>? branches,
    List<Department>? departments,
    List<Team>? teams,
    List<Position>? positions,
    List<UserSummary>? users,
    String? searchQuery,
    bool? isOffline,
    String? message,
    bool? isRefreshing,
  }) {
    return OrganizationState(
      status: status ?? this.status,
      context: context ?? this.context,
      summary: summary ?? this.summary,
      companies: companies ?? this.companies,
      branches: branches ?? this.branches,
      departments: departments ?? this.departments,
      teams: teams ?? this.teams,
      positions: positions ?? this.positions,
      users: users ?? this.users,
      searchQuery: searchQuery ?? this.searchQuery,
      isOffline: isOffline ?? this.isOffline,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        context,
        summary,
        companies,
        branches,
        departments,
        teams,
        positions,
        users,
        searchQuery,
        isOffline,
        message,
        isRefreshing,
      ];
}

class OrganizationCubit extends Cubit<OrganizationState> {
  OrganizationCubit({
    required OrganizationRepository repository,
    required SessionQueryCache sessionQueryCache,
  })  : _repository = repository,
        _sessionQueryCache = sessionQueryCache,
        super(const OrganizationState());

  final OrganizationRepository _repository;
  final SessionQueryCache _sessionQueryCache;

  Future<void> loadDashboard({bool forceRefresh = false}) async {
    final cachedContext =
        _sessionQueryCache.get<OrganizationContext>('org:context');
    final cachedSummary =
        _sessionQueryCache.get<OrganizationSummary>('org:summary');
    final hasData = cachedContext != null ||
        cachedSummary != null ||
        state.context != null ||
        state.summary != null;

    if (hasData) {
      emit(
        state.copyWith(
          status: OrganizationStatus.success,
          context: cachedContext ?? state.context,
          summary: cachedSummary ?? state.summary,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: OrganizationStatus.loading,
          isRefreshing: false,
        ),
      );
    }

    final contextResult =
        await _repository.getMyContext(forceRefresh: forceRefresh);
    final summaryResult =
        await _repository.getSummary(forceRefresh: forceRefresh);

    OrganizationContext? context;
    OrganizationSummary? summary;
    String? message;
    var isOffline = false;

    switch (contextResult) {
      case Success(data: final data):
        context = data;
        _sessionQueryCache.set('org:context', data);
      case Failure(message: final error, code: final code):
        isOffline = code == 'OFFLINE' ||
            code == 'TIMEOUT' ||
            code == 'NETWORK_ERROR';
        if (!isOffline) {
          message = error;
        }
    }

    switch (summaryResult) {
      case Success(data: final data):
        summary = data;
        _sessionQueryCache.set('org:summary', data);
      case Failure(message: final error, code: final code):
        final offline = code == 'OFFLINE' ||
            code == 'TIMEOUT' ||
            code == 'NETWORK_ERROR';
        isOffline = isOffline || offline;
        if (!offline) {
          message ??= error;
        }
    }

    if (context == null && summary == null) {
      emit(
        state.copyWith(
          status: hasData
              ? OrganizationStatus.success
              : OrganizationStatus.failure,
          isOffline: isOffline,
          message: message,
          isRefreshing: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: OrganizationStatus.success,
        context: context,
        summary: summary,
        isOffline: isOffline,
        message: message,
        isRefreshing: false,
      ),
    );
  }

  Future<void> loadCompanies({bool forceRefresh = false}) async {
    await _loadCollection(
      cacheKey: 'org:companies',
      forceRefresh: forceRefresh,
      currentItems: state.companies,
      loader: () => _repository.getCompanies(forceRefresh: forceRefresh),
      onSuccess: (items) => state.copyWith(companies: items),
    );
  }

  Future<void> loadBranches({
    String? search,
    bool forceRefresh = false,
  }) async {
    await _loadCollection(
      cacheKey: 'org:branches:${search ?? ''}',
      forceRefresh: forceRefresh,
      search: search,
      currentItems: state.branches,
      loader: () => _repository.getBranches(
        search: search,
        forceRefresh: forceRefresh,
      ),
      onSuccess: (items) => state.copyWith(branches: items),
    );
  }

  Future<void> loadDepartments({
    String? search,
    bool forceRefresh = false,
  }) async {
    await _loadCollection(
      cacheKey: 'org:departments:${search ?? ''}',
      forceRefresh: forceRefresh,
      search: search,
      currentItems: state.departments,
      loader: () => _repository.getDepartments(
        search: search,
        forceRefresh: forceRefresh,
      ),
      onSuccess: (items) => state.copyWith(departments: items),
    );
  }

  Future<void> loadTeams({
    String? search,
    bool forceRefresh = false,
  }) async {
    await _loadCollection(
      cacheKey: 'org:teams:${search ?? ''}',
      forceRefresh: forceRefresh,
      search: search,
      currentItems: state.teams,
      loader: () => _repository.getTeams(
        search: search,
        forceRefresh: forceRefresh,
      ),
      onSuccess: (items) => state.copyWith(teams: items),
    );
  }

  Future<void> loadPositions({
    String? search,
    bool forceRefresh = false,
  }) async {
    await _loadCollection(
      cacheKey: 'org:positions:${search ?? ''}',
      forceRefresh: forceRefresh,
      search: search,
      currentItems: state.positions,
      loader: () => _repository.getPositions(
        search: search,
        forceRefresh: forceRefresh,
      ),
      onSuccess: (items) => state.copyWith(positions: items),
    );
  }

  Future<void> loadUsers({
    String? search,
    bool forceRefresh = false,
  }) async {
    await _loadCollection(
      cacheKey: 'org:users:${search ?? ''}',
      forceRefresh: forceRefresh,
      search: search,
      currentItems: state.users,
      loader: () => _repository.getUsers(
        search: search,
        forceRefresh: forceRefresh,
      ),
      onSuccess: (items) => state.copyWith(users: items),
    );
  }

  Future<void> _loadCollection<T>({
    required String cacheKey,
    required bool forceRefresh,
    required List<T> currentItems,
    required Future<Result<List<T>>> Function() loader,
    required OrganizationState Function(List<T> items) onSuccess,
    String? search,
  }) async {
    final cached = _sessionQueryCache.get<List<T>>(cacheKey);
    final seeded = cached ?? (currentItems.isNotEmpty ? currentItems : null);
    final hasData = seeded != null && seeded.isNotEmpty;

    if (hasData) {
      emit(
        onSuccess(seeded).copyWith(
          status: OrganizationStatus.success,
          searchQuery: search ?? state.searchQuery,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: OrganizationStatus.loading,
          searchQuery: search ?? state.searchQuery,
          isRefreshing: false,
        ),
      );
    }

    final result = await loader();
    switch (result) {
      case Success(data: final items):
        _sessionQueryCache.set(cacheKey, items);
        emit(
          onSuccess(items).copyWith(
            status: OrganizationStatus.success,
            isOffline: false,
            message: null,
            searchQuery: search ?? state.searchQuery,
            isRefreshing: false,
          ),
        );
      case Failure(message: final message, code: final code):
        final offline = code == 'OFFLINE' ||
            code == 'TIMEOUT' ||
            code == 'NETWORK_ERROR';
        emit(
          state.copyWith(
            status: hasData
                ? OrganizationStatus.success
                : OrganizationStatus.failure,
            isOffline: offline,
            message: offline ? null : message,
            searchQuery: search ?? state.searchQuery,
            isRefreshing: false,
          ),
        );
    }
  }
}
