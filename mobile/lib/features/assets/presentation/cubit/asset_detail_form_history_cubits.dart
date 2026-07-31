import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/domain/entities/asset_category.dart';
import 'package:mobile/features/assets/domain/entities/asset_history.dart';
import 'package:mobile/features/assets/domain/services/asset_qr_scanner.dart';
import 'package:mobile/features/assets/domain/usecases/assets_usecases.dart';
import 'package:mobile/features/organization/domain/entities/branch.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';

enum AssetDetailStatus { initial, loading, success, failure }

class AssetDetailState extends Equatable {
  const AssetDetailState({
    this.status = AssetDetailStatus.initial,
    this.asset,
    this.history = const [],
    this.message,
  });

  final AssetDetailStatus status;
  final Asset? asset;
  final List<AssetHistory> history;
  final String? message;

  @override
  List<Object?> get props => [status, asset, history, message];
}

class AssetDetailCubit extends Cubit<AssetDetailState> {
  AssetDetailCubit({
    required String assetId,
    required GetAssetByIdUseCase getById,
    required DeleteAssetUseCase deleteAsset,
    required ListAssetHistoryUseCase listHistory,
    required AddAssetHistoryUseCase addHistory,
    required AssetQrScanner qrScanner,
  })  : _assetId = assetId,
        _getById = getById,
        _deleteAsset = deleteAsset,
        _listHistory = listHistory,
        _addHistory = addHistory,
        _qrScanner = qrScanner,
        super(const AssetDetailState());

  final String _assetId;
  final GetAssetByIdUseCase _getById;
  final DeleteAssetUseCase _deleteAsset;
  final ListAssetHistoryUseCase _listHistory;
  final AddAssetHistoryUseCase _addHistory;
  final AssetQrScanner _qrScanner;

  Future<void> load() async {
    emit(const AssetDetailState(status: AssetDetailStatus.loading));
    final assetResult = await _getById(_assetId);
    final historyResult = await _listHistory(assetId: _assetId, limit: 10);
    switch (assetResult) {
      case Success(data: final asset):
        final history = switch (historyResult) {
          Success(data: final page) => page.items,
          Failure() => const <AssetHistory>[],
        };
        emit(AssetDetailState(
          status: AssetDetailStatus.success,
          asset: asset,
          history: history,
        ));
      case Failure(message: final message):
        emit(AssetDetailState(
          status: AssetDetailStatus.failure,
          message: message,
        ));
    }
  }

  Future<Result<Asset>> delete() => _deleteAsset(_assetId);

  Future<Result<AssetHistory>> addHistory(AssetHistoryCreateInput input) async {
    final result = await _addHistory(input);
    if (result is Success<AssetHistory>) {
      await load();
    }
    return result;
  }

  /// Architecture hook for QR scanning — stubbed in Phase 1.
  Future<Result<String>> scanQr() => _qrScanner.scan();
}

enum AssetFormStatus { initial, loading, saving, success, failure }

class AssetFormState extends Equatable {
  const AssetFormState({
    this.status = AssetFormStatus.initial,
    this.asset,
    this.categories = const [],
    this.branches = const [],
    this.message,
  });

  final AssetFormStatus status;
  final Asset? asset;
  final List<AssetCategory> categories;
  final List<Branch> branches;
  final String? message;

  bool get isEditing => asset != null;

  @override
  List<Object?> get props => [status, asset, categories, branches, message];
}

class AssetFormCubit extends Cubit<AssetFormState> {
  AssetFormCubit({
    required CreateAssetUseCase create,
    required UpdateAssetUseCase update,
    required GetAssetByIdUseCase getById,
    required ListAssetCategoriesUseCase listCategories,
    required OrganizationRepository organizationRepository,
    required AssetQrScanner qrScanner,
    String? assetId,
  })  : _create = create,
        _update = update,
        _getById = getById,
        _listCategories = listCategories,
        _organizationRepository = organizationRepository,
        _qrScanner = qrScanner,
        _assetId = assetId,
        super(const AssetFormState());

  final CreateAssetUseCase _create;
  final UpdateAssetUseCase _update;
  final GetAssetByIdUseCase _getById;
  final ListAssetCategoriesUseCase _listCategories;
  final OrganizationRepository _organizationRepository;
  final AssetQrScanner _qrScanner;
  final String? _assetId;

  Future<void> load() async {
    emit(const AssetFormState(status: AssetFormStatus.loading));
    final categoriesResult = await _listCategories(page: 1, limit: 100, isActive: true);
    final branchesResult = await _organizationRepository.getBranches();

    final categories = switch (categoriesResult) {
      Success(data: final page) => page.items,
      Failure() => const <AssetCategory>[],
    };
    final branches = switch (branchesResult) {
      Success(data: final items) => items,
      Failure() => const <Branch>[],
    };

    final assetId = _assetId;
    if (assetId == null || assetId.isEmpty) {
      emit(AssetFormState(
        status: AssetFormStatus.success,
        categories: categories,
        branches: branches,
      ));
      return;
    }

    final assetResult = await _getById(assetId);
    switch (assetResult) {
      case Success(data: final asset):
        emit(AssetFormState(
          status: AssetFormStatus.success,
          asset: asset,
          categories: categories,
          branches: branches,
        ));
      case Failure(message: final message):
        emit(AssetFormState(
          status: AssetFormStatus.failure,
          categories: categories,
          branches: branches,
          message: message,
        ));
    }
  }

  Future<Result<Asset>> save(AssetUpsertInput input) async {
    emit(AssetFormState(
      status: AssetFormStatus.saving,
      asset: state.asset,
      categories: state.categories,
      branches: state.branches,
    ));
    final assetId = _assetId;
    final result = (assetId == null || assetId.isEmpty)
        ? await _create(input)
        : await _update(assetId, input);
    switch (result) {
      case Success(data: final asset):
        emit(AssetFormState(
          status: AssetFormStatus.success,
          asset: asset,
          categories: state.categories,
          branches: state.branches,
        ));
      case Failure(message: final message):
        emit(AssetFormState(
          status: AssetFormStatus.success,
          asset: state.asset,
          categories: state.categories,
          branches: state.branches,
          message: message,
        ));
    }
    return result;
  }

  Future<Result<String>> scanQr() => _qrScanner.scan();
}

enum AssetHistoryStatus { initial, loading, loadingMore, success, failure }

class AssetHistoryListState extends Equatable {
  const AssetHistoryListState({
    this.status = AssetHistoryStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.type,
    this.assetId,
    this.message,
    this.isRefreshing = false,
  });

  final AssetHistoryStatus status;
  final List<AssetHistory> items;
  final int page;
  final bool hasMore;
  final String search;
  final AssetHistoryType? type;
  final String? assetId;
  final String? message;
  final bool isRefreshing;

  AssetHistoryListState copyWith({
    AssetHistoryStatus? status,
    List<AssetHistory>? items,
    int? page,
    bool? hasMore,
    String? search,
    AssetHistoryType? type,
    bool clearType = false,
    String? message,
    bool? isRefreshing,
  }) {
    return AssetHistoryListState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      type: clearType ? null : (type ?? this.type),
      assetId: assetId,
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
        type,
        assetId,
        message,
        isRefreshing,
      ];
}

class AssetHistoryCubit extends Cubit<AssetHistoryListState> {
  AssetHistoryCubit({
    required ListAssetHistoryUseCase listHistory,
    required SessionQueryCache sessionCache,
    String? assetId,
  })  : _listHistory = listHistory,
        _sessionCache = sessionCache,
        super(AssetHistoryListState(assetId: assetId));

  static const int _pageSize = 20;
  final ListAssetHistoryUseCase _listHistory;
  final SessionQueryCache _sessionCache;

  String _cacheKey(
    String search,
    AssetHistoryType? type,
    String? assetId,
  ) =>
      'assets:history:p1:s=$search:t=${type?.name ?? ''}:a=${assetId ?? ''}';

  Future<void> loadFirstPage({
    String? search,
    AssetHistoryType? type,
    bool clearType = false,
  }) async {
    final nextSearch = search ?? state.search;
    final nextType = clearType ? null : (type ?? state.type);
    final assetId = state.assetId;
    final cacheKey = _cacheKey(nextSearch, nextType, assetId);
    final cached = _sessionCache.get<AssetHistoryPage>(cacheKey);

    if (cached != null) {
      emit(AssetHistoryListState(
        status: AssetHistoryStatus.success,
        items: cached.items,
        page: cached.page,
        hasMore: cached.hasMore,
        search: nextSearch,
        type: nextType,
        assetId: assetId,
        isRefreshing: true,
      ));
    } else if (state.items.isNotEmpty) {
      emit(state.copyWith(
        search: nextSearch,
        type: nextType,
        clearType: clearType,
        isRefreshing: true,
        message: null,
      ));
    } else {
      emit(AssetHistoryListState(
        status: AssetHistoryStatus.loading,
        search: nextSearch,
        type: nextType,
        assetId: assetId,
      ));
    }

    final result = await _listHistory(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
      type: nextType,
      assetId: assetId,
    );
    switch (result) {
      case Success(data: final page):
        _sessionCache.set(cacheKey, page);
        emit(AssetHistoryListState(
          status: AssetHistoryStatus.success,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          search: nextSearch,
          type: nextType,
          assetId: assetId,
        ));
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(state.copyWith(
            status: AssetHistoryStatus.success,
            search: nextSearch,
            type: nextType,
            clearType: clearType,
            isRefreshing: false,
            message: message,
          ));
        } else {
          emit(AssetHistoryListState(
            status: AssetHistoryStatus.failure,
            search: nextSearch,
            type: nextType,
            assetId: assetId,
            message: message,
          ));
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == AssetHistoryStatus.loading ||
        state.status == AssetHistoryStatus.loadingMore) {
      return;
    }
    emit(state.copyWith(status: AssetHistoryStatus.loadingMore));
    final result = await _listHistory(
      page: state.page + 1,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
      type: state.type,
      assetId: state.assetId,
    );
    switch (result) {
      case Success(data: final page):
        emit(state.copyWith(
          status: AssetHistoryStatus.success,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          status: AssetHistoryStatus.success,
          message: message,
        ));
    }
  }

  Future<void> setFilter(AssetHistoryType? type) =>
      loadFirstPage(type: type, clearType: type == null);

  Future<void> search(String value) => loadFirstPage(search: value);
}
