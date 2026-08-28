import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/settings/data/datasources/technician_interface_local_datasource.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/usecases/settings_usecases.dart';

enum TechnicianInterfaceLoadStatus { initial, loading, ready, failure }

class TechnicianInterfaceState extends Equatable {
  const TechnicianInterfaceState({
    this.status = TechnicianInterfaceLoadStatus.initial,
    this.config = TechnicianInterfaceConfig.defaults,
    this.isRefreshing = false,
    this.message,
  });

  final TechnicianInterfaceLoadStatus status;
  final TechnicianInterfaceConfig config;
  final bool isRefreshing;
  final String? message;

  bool get isReady =>
      status == TechnicianInterfaceLoadStatus.ready ||
      (status == TechnicianInterfaceLoadStatus.failure &&
          config != TechnicianInterfaceConfig.defaults);

  TechnicianInterfaceState copyWith({
    TechnicianInterfaceLoadStatus? status,
    TechnicianInterfaceConfig? config,
    bool? isRefreshing,
    String? message,
  }) {
    return TechnicianInterfaceState(
      status: status ?? this.status,
      config: config ?? this.config,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, config, isRefreshing, message];
}

/// Runtime technician navigation config (effective flags for the signed-in user).
class TechnicianInterfaceCubit extends Cubit<TechnicianInterfaceState> {
  TechnicianInterfaceCubit({
    required GetTechnicianInterfaceConfigUseCase getConfig,
    required SessionQueryCache sessionQueryCache,
    required TechnicianInterfaceLocalDataSource localDataSource,
  })  : _getConfig = getConfig,
        _sessionQueryCache = sessionQueryCache,
        _localDataSource = localDataSource,
        super(const TechnicianInterfaceState());

  static const _cacheKey = 'settings:technician-interface:config';

  final GetTechnicianInterfaceConfigUseCase _getConfig;
  final SessionQueryCache _sessionQueryCache;
  final TechnicianInterfaceLocalDataSource _localDataSource;

  String? _activeCompanyId;

  /// Loads effective technician navigation flags.
  ///
  /// When [companyId] is provided, the last persisted configuration for that
  /// company is applied immediately (offline-safe) before the network fetch.
  Future<void> load({bool force = false, String? companyId}) async {
    if (companyId != null && companyId.isNotEmpty) {
      _activeCompanyId = companyId;
    }

    final persisted = _readPersistedConfig();
    final sessionCached =
        _sessionQueryCache.get<TechnicianInterfaceConfig>(_cacheKey);
    final immediate = persisted ?? sessionCached;

    if (!force) {
      if (immediate != null) {
        if (sessionCached == null) {
          _sessionQueryCache.set(_cacheKey, immediate);
        }
        emit(
          state.copyWith(
            status: TechnicianInterfaceLoadStatus.ready,
            config: immediate,
            isRefreshing: true,
          ),
        );
      } else if (state.status == TechnicianInterfaceLoadStatus.initial) {
        emit(
          state.copyWith(
            status: TechnicianInterfaceLoadStatus.loading,
            isRefreshing: false,
          ),
        );
      } else {
        emit(state.copyWith(isRefreshing: true));
      }
    } else if (immediate != null) {
      emit(
        state.copyWith(
          status: TechnicianInterfaceLoadStatus.ready,
          config: immediate,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: TechnicianInterfaceLoadStatus.loading,
          isRefreshing: false,
        ),
      );
    }

    final result = await _getConfig();
    switch (result) {
      case Success(data: final data):
        _sessionQueryCache.set(_cacheKey, data);
        final companyId = _activeCompanyId;
        if (companyId != null && companyId.isNotEmpty) {
          await _localDataSource.write(companyId, data);
        }
        emit(
          TechnicianInterfaceState(
            status: TechnicianInterfaceLoadStatus.ready,
            config: data,
            isRefreshing: false,
          ),
        );
      case Failure(:final message):
        final fallback = _readPersistedConfig() ??
            _sessionQueryCache.get<TechnicianInterfaceConfig>(_cacheKey);
        emit(
          TechnicianInterfaceState(
            status: fallback != null
                ? TechnicianInterfaceLoadStatus.ready
                : TechnicianInterfaceLoadStatus.failure,
            config: fallback ?? TechnicianInterfaceConfig.defaults,
            isRefreshing: false,
            message: message,
          ),
        );
    }
  }

  void clear() {
    _sessionQueryCache.invalidate(_cacheKey);
    _activeCompanyId = null;
    emit(const TechnicianInterfaceState());
  }

  TechnicianInterfaceConfig? _readPersistedConfig() {
    final companyId = _activeCompanyId;
    if (companyId == null || companyId.isEmpty) return null;
    return _localDataSource.read(companyId);
  }
}

enum TechnicianInterfaceSettingsStatus {
  initial,
  loading,
  saving,
  success,
  failure,
}

class TechnicianInterfaceSettingsState extends Equatable {
  const TechnicianInterfaceSettingsState({
    this.status = TechnicianInterfaceSettingsStatus.initial,
    this.config,
    this.message,
    this.isRefreshing = false,
  });

  final TechnicianInterfaceSettingsStatus status;
  final TechnicianInterfaceConfig? config;
  final String? message;
  final bool isRefreshing;

  TechnicianInterfaceSettingsState copyWith({
    TechnicianInterfaceSettingsStatus? status,
    TechnicianInterfaceConfig? config,
    String? message,
    bool? isRefreshing,
  }) {
    return TechnicianInterfaceSettingsState(
      status: status ?? this.status,
      config: config ?? this.config,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, config, message, isRefreshing];
}

/// Admin settings page cubit (read/write admin endpoints).
class TechnicianInterfaceSettingsCubit
    extends Cubit<TechnicianInterfaceSettingsState> {
  TechnicianInterfaceSettingsCubit({
    required GetTechnicianInterfaceSettingsUseCase getSettings,
    required UpdateTechnicianInterfaceSettingsUseCase updateSettings,
    required SessionQueryCache sessionQueryCache,
  })  : _getSettings = getSettings,
        _updateSettings = updateSettings,
        _sessionQueryCache = sessionQueryCache,
        super(const TechnicianInterfaceSettingsState());

  static const _cacheKey = 'settings:technician-interface:admin';

  final GetTechnicianInterfaceSettingsUseCase _getSettings;
  final UpdateTechnicianInterfaceSettingsUseCase _updateSettings;
  final SessionQueryCache _sessionQueryCache;

  Future<void> load() async {
    final cached = _sessionQueryCache.get<TechnicianInterfaceConfig>(_cacheKey);
    final hasData = cached != null || state.config != null;

    if (hasData) {
      emit(
        state.copyWith(
          status: TechnicianInterfaceSettingsStatus.success,
          config: cached ?? state.config,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: TechnicianInterfaceSettingsStatus.loading,
          isRefreshing: false,
        ),
      );
    }

    final result = await _getSettings();
    switch (result) {
      case Success(data: final data):
        _sessionQueryCache.set(_cacheKey, data);
        emit(
          TechnicianInterfaceSettingsState(
            status: TechnicianInterfaceSettingsStatus.success,
            config: data,
            isRefreshing: false,
          ),
        );
      case Failure(:final message):
        emit(
          TechnicianInterfaceSettingsState(
            status: hasData
                ? TechnicianInterfaceSettingsStatus.success
                : TechnicianInterfaceSettingsStatus.failure,
            config: state.config,
            message: message,
            isRefreshing: false,
          ),
        );
    }
  }

  Future<Result<TechnicianInterfaceConfig>> save(
    TechnicianInterfaceConfigUpdate input,
  ) async {
    emit(
      TechnicianInterfaceSettingsState(
        status: TechnicianInterfaceSettingsStatus.saving,
        config: state.config,
      ),
    );

    final result = await _updateSettings(input);
    switch (result) {
      case Success(data: final data):
        _sessionQueryCache.set(_cacheKey, data);
        emit(
          TechnicianInterfaceSettingsState(
            status: TechnicianInterfaceSettingsStatus.success,
            config: data,
          ),
        );
      case Failure(:final message):
        emit(
          TechnicianInterfaceSettingsState(
            status: TechnicianInterfaceSettingsStatus.failure,
            config: state.config,
            message: message,
          ),
        );
    }
    return result;
  }
}
