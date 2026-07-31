import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/domain/usecases/assets_usecases.dart';
import 'package:mobile/features/organization/domain/entities/team.dart';
import 'package:mobile/features/organization/domain/entities/user_summary.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/domain/usecases/pm_usecases.dart';

enum PmPlanDetailStatus { initial, loading, success, failure }

class PmPlanDetailState extends Equatable {
  const PmPlanDetailState({
    this.status = PmPlanDetailStatus.initial,
    this.plan,
    this.message,
    this.isRefreshing = false,
  });

  final PmPlanDetailStatus status;
  final MaintenancePlan? plan;
  final String? message;
  final bool isRefreshing;

  PmPlanDetailState copyWith({
    PmPlanDetailStatus? status,
    MaintenancePlan? plan,
    String? message,
    bool? isRefreshing,
  }) {
    return PmPlanDetailState(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, plan, message, isRefreshing];
}

class PmPlanDetailCubit extends Cubit<PmPlanDetailState> {
  PmPlanDetailCubit({
    required String planId,
    required GetPmPlanByIdUseCase getById,
    required DeletePmPlanUseCase deletePlan,
    required GeneratePmSchedulesUseCase generateSchedules,
    required SessionQueryCache queryCache,
  })  : _planId = planId,
        _getById = getById,
        _deletePlan = deletePlan,
        _generateSchedules = generateSchedules,
        _queryCache = queryCache,
        super(const PmPlanDetailState());

  final String _planId;
  final GetPmPlanByIdUseCase _getById;
  final DeletePmPlanUseCase _deletePlan;
  final GeneratePmSchedulesUseCase _generateSchedules;
  final SessionQueryCache _queryCache;

  String get _cacheKey => 'pm:plan:$_planId';

  Future<void> load() async {
    final cached = _queryCache.get<MaintenancePlan>(_cacheKey);
    if (cached != null) {
      emit(PmPlanDetailState(
        status: PmPlanDetailStatus.success,
        plan: cached,
        isRefreshing: true,
      ));
    } else if (state.plan != null) {
      emit(state.copyWith(
        status: PmPlanDetailStatus.success,
        isRefreshing: true,
      ));
    } else {
      emit(const PmPlanDetailState(status: PmPlanDetailStatus.loading));
    }

    final result = await _getById(_planId);
    switch (result) {
      case Success(data: final plan):
        _queryCache.set(_cacheKey, plan);
        emit(PmPlanDetailState(
          status: PmPlanDetailStatus.success,
          plan: plan,
        ));
      case Failure(message: final message):
        if (state.plan != null) {
          emit(PmPlanDetailState(
            status: PmPlanDetailStatus.success,
            plan: state.plan,
            message: message,
          ));
        } else {
          emit(PmPlanDetailState(
            status: PmPlanDetailStatus.failure,
            message: message,
          ));
        }
    }
  }

  Future<Result<MaintenancePlan>> delete() async {
    final result = await _deletePlan(_planId);
    if (result is Success<MaintenancePlan>) {
      _queryCache.invalidate(_cacheKey);
      _queryCache.invalidatePrefix('pm:plans:');
      _queryCache.invalidate('pm:dashboard');
    }
    return result;
  }

  Future<Result<int>> generateSchedules({int count = 6}) async {
    final result = await _generateSchedules(_planId, count: count);
    if (result is Success<int>) {
      _queryCache.invalidatePrefix('pm:schedules:');
      await load();
    }
    return result;
  }
}

enum PmPlanFormStatus { initial, loading, saving, success, failure }

class PmPlanFormState extends Equatable {
  const PmPlanFormState({
    this.status = PmPlanFormStatus.initial,
    this.plan,
    this.teams = const [],
    this.users = const [],
    this.assets = const [],
    this.message,
  });

  final PmPlanFormStatus status;
  final MaintenancePlan? plan;
  final List<Team> teams;
  final List<UserSummary> users;
  final List<Asset> assets;
  final String? message;

  bool get isEditing => plan != null;

  @override
  List<Object?> get props => [status, plan, teams, users, assets, message];
}

class PmPlanFormCubit extends Cubit<PmPlanFormState> {
  PmPlanFormCubit({
    required CreatePmPlanUseCase create,
    required UpdatePmPlanUseCase update,
    required GetPmPlanByIdUseCase getById,
    required OrganizationRepository organizationRepository,
    required ListAssetsUseCase listAssets,
    String? planId,
  })  : _create = create,
        _update = update,
        _getById = getById,
        _organizationRepository = organizationRepository,
        _listAssets = listAssets,
        _planId = planId,
        super(const PmPlanFormState());

  final CreatePmPlanUseCase _create;
  final UpdatePmPlanUseCase _update;
  final GetPmPlanByIdUseCase _getById;
  final OrganizationRepository _organizationRepository;
  final ListAssetsUseCase _listAssets;
  final String? _planId;

  Future<void> load() async {
    emit(const PmPlanFormState(status: PmPlanFormStatus.loading));

    final teamsResult = await _organizationRepository.getTeams();
    final usersResult = await _organizationRepository.getUsers();
    final assetsResult = await _listAssets(page: 1, limit: 100);

    final teams = switch (teamsResult) {
      Success(data: final items) => items,
      Failure() => const <Team>[],
    };
    final users = switch (usersResult) {
      Success(data: final items) => items,
      Failure() => const <UserSummary>[],
    };
    final assets = switch (assetsResult) {
      Success(data: final page) => page.items,
      Failure() => const <Asset>[],
    };

    if (_planId == null || _planId.isEmpty) {
      emit(PmPlanFormState(
        status: PmPlanFormStatus.success,
        teams: teams,
        users: users,
        assets: assets,
      ));
      return;
    }

    final planResult = await _getById(_planId);
    switch (planResult) {
      case Success(data: final plan):
        emit(PmPlanFormState(
          status: PmPlanFormStatus.success,
          plan: plan,
          teams: teams,
          users: users,
          assets: assets,
        ));
      case Failure(message: final message):
        emit(PmPlanFormState(
          status: PmPlanFormStatus.failure,
          teams: teams,
          users: users,
          assets: assets,
          message: message,
        ));
    }
  }

  Future<Result<MaintenancePlan>> save(MaintenancePlanUpsertInput input) async {
    emit(PmPlanFormState(
      status: PmPlanFormStatus.saving,
      plan: state.plan,
      teams: state.teams,
      users: state.users,
      assets: state.assets,
    ));

    final result = _planId == null || _planId.isEmpty
        ? await _create(input)
        : await _update(_planId, input);

    switch (result) {
      case Success(data: final plan):
        emit(PmPlanFormState(
          status: PmPlanFormStatus.success,
          plan: plan,
          teams: state.teams,
          users: state.users,
          assets: state.assets,
        ));
      case Failure(message: final message):
        emit(PmPlanFormState(
          status: PmPlanFormStatus.failure,
          plan: state.plan,
          teams: state.teams,
          users: state.users,
          assets: state.assets,
          message: message,
        ));
    }
    return result;
  }
}

enum PmChecklistBuilderStatus { initial, loading, saving, success, failure }

class PmChecklistBuilderState extends Equatable {
  const PmChecklistBuilderState({
    this.status = PmChecklistBuilderStatus.initial,
    this.plan,
    this.items = const [],
    this.message,
    this.isRefreshing = false,
  });

  final PmChecklistBuilderStatus status;
  final MaintenancePlan? plan;
  final List<PmChecklistItem> items;
  final String? message;
  final bool isRefreshing;

  @override
  List<Object?> get props => [status, plan, items, message, isRefreshing];
}

class PmChecklistBuilderCubit extends Cubit<PmChecklistBuilderState> {
  PmChecklistBuilderCubit({
    required String planId,
    required GetPmPlanByIdUseCase getById,
    required UpdatePmChecklistUseCase updateChecklist,
    required SessionQueryCache queryCache,
  })  : _planId = planId,
        _getById = getById,
        _updateChecklist = updateChecklist,
        _queryCache = queryCache,
        super(const PmChecklistBuilderState());

  final String _planId;
  final GetPmPlanByIdUseCase _getById;
  final UpdatePmChecklistUseCase _updateChecklist;
  final SessionQueryCache _queryCache;

  String get _cacheKey => 'pm:plan:$_planId';

  Future<void> load() async {
    final cached = _queryCache.get<MaintenancePlan>(_cacheKey);
    if (cached != null) {
      emit(PmChecklistBuilderState(
        status: PmChecklistBuilderStatus.success,
        plan: cached,
        items: List<PmChecklistItem>.from(cached.checklistItems),
        isRefreshing: true,
      ));
    } else if (state.plan != null || state.items.isNotEmpty) {
      emit(PmChecklistBuilderState(
        status: PmChecklistBuilderStatus.success,
        plan: state.plan,
        items: state.items,
        isRefreshing: true,
      ));
    } else {
      emit(const PmChecklistBuilderState(
        status: PmChecklistBuilderStatus.loading,
      ));
    }

    final result = await _getById(_planId);
    switch (result) {
      case Success(data: final plan):
        _queryCache.set(_cacheKey, plan);
        emit(PmChecklistBuilderState(
          status: PmChecklistBuilderStatus.success,
          plan: plan,
          items: List<PmChecklistItem>.from(plan.checklistItems),
        ));
      case Failure(message: final message):
        if (state.plan != null || state.items.isNotEmpty) {
          emit(PmChecklistBuilderState(
            status: PmChecklistBuilderStatus.success,
            plan: state.plan,
            items: state.items,
            message: message,
          ));
        } else {
          emit(PmChecklistBuilderState(
            status: PmChecklistBuilderStatus.failure,
            message: message,
          ));
        }
    }
  }

  void setItems(List<PmChecklistItem> items) {
    emit(PmChecklistBuilderState(
      status: PmChecklistBuilderStatus.success,
      plan: state.plan,
      items: items,
    ));
  }

  void addItem(PmChecklistItem item) {
    setItems([...state.items, item]);
  }

  void updateItem(int index, PmChecklistItem item) {
    final next = List<PmChecklistItem>.from(state.items);
    if (index < 0 || index >= next.length) return;
    next[index] = item;
    setItems(next);
  }

  void removeItem(int index) {
    final next = List<PmChecklistItem>.from(state.items)..removeAt(index);
    setItems(next);
  }

  void reorder(int oldIndex, int newIndex) {
    final next = List<PmChecklistItem>.from(state.items);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    setItems([
      for (var i = 0; i < next.length; i++)
        next[i].copyWith(sortOrder: i),
    ]);
  }

  Future<Result<MaintenancePlan>> save() async {
    emit(PmChecklistBuilderState(
      status: PmChecklistBuilderStatus.saving,
      plan: state.plan,
      items: state.items,
    ));
    final ordered = [
      for (var i = 0; i < state.items.length; i++)
        state.items[i].copyWith(sortOrder: i),
    ];
    final result = await _updateChecklist(
      planId: _planId,
      checklistItems: ordered,
    );
    switch (result) {
      case Success(data: final plan):
        _queryCache.set(_cacheKey, plan);
        _queryCache.invalidatePrefix('pm:plans:');
        emit(PmChecklistBuilderState(
          status: PmChecklistBuilderStatus.success,
          plan: plan,
          items: List<PmChecklistItem>.from(plan.checklistItems),
        ));
      case Failure(message: final message):
        emit(PmChecklistBuilderState(
          status: PmChecklistBuilderStatus.failure,
          plan: state.plan,
          items: state.items,
          message: message,
        ));
    }
    return result;
  }
}
