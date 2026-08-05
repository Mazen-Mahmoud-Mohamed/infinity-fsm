import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';
import 'package:mobile/features/global_search/domain/entities/global_search_hit.dart';
import 'package:mobile/features/global_search/domain/usecases/search_globally_usecase.dart';

enum GlobalSearchStatus { idle, loading, ready, failure }

class GlobalSearchState extends Equatable {
  const GlobalSearchState({
    this.status = GlobalSearchStatus.idle,
    this.query = '',
    this.hits = const [],
    this.message,
  });

  final GlobalSearchStatus status;
  final String query;
  final List<GlobalSearchHit> hits;
  final String? message;

  Map<GlobalSearchModule, List<GlobalSearchHit>> get groupedHits {
    final map = <GlobalSearchModule, List<GlobalSearchHit>>{};
    for (final hit in hits) {
      map.putIfAbsent(hit.module, () => <GlobalSearchHit>[]).add(hit);
    }
    return map;
  }

  bool get isEmptyQuery => query.trim().length < 2;

  GlobalSearchState copyWith({
    GlobalSearchStatus? status,
    String? query,
    List<GlobalSearchHit>? hits,
    String? message,
    bool clearMessage = false,
  }) {
    return GlobalSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      hits: hits ?? this.hits,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, query, hits, message];
}

class GlobalSearchCubit extends Cubit<GlobalSearchState> {
  GlobalSearchCubit({
    required SearchGloballyUseCase searchGlobally,
    required PermissionChecker Function() permissionsProvider,
  })  : _searchGlobally = searchGlobally,
        _permissionsProvider = permissionsProvider,
        super(const GlobalSearchState());

  static const Duration _debounce = Duration(milliseconds: 350);

  final SearchGloballyUseCase _searchGlobally;
  final PermissionChecker Function() _permissionsProvider;
  Timer? _debounceTimer;
  int _requestId = 0;

  void onQueryChanged(String value) {
    emit(state.copyWith(query: value, clearMessage: true));
    _debounceTimer?.cancel();

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      emit(
        state.copyWith(
          status: GlobalSearchStatus.idle,
          hits: const [],
          clearMessage: true,
        ),
      );
      return;
    }

    emit(state.copyWith(status: GlobalSearchStatus.loading));
    _debounceTimer = Timer(_debounce, () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query) async {
    final requestId = ++_requestId;
    final result = await _searchGlobally(
      query: query,
      permissions: _permissionsProvider(),
    );
    if (isClosed || requestId != _requestId) return;

    switch (result) {
      case Success(data: final hits):
        emit(
          state.copyWith(
            status: GlobalSearchStatus.ready,
            hits: hits,
            clearMessage: true,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: GlobalSearchStatus.failure,
            hits: const [],
            message: message,
          ),
        );
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
