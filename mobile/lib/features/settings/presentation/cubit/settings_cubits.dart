import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/usecases/settings_usecases.dart';

enum OrganizationSettingsStatus { initial, loading, saving, success, failure }

class OrganizationSettingsState extends Equatable {
  const OrganizationSettingsState({
    this.status = OrganizationSettingsStatus.initial,
    this.settings,
    this.message,
    this.isRefreshing = false,
  });

  final OrganizationSettingsStatus status;
  final OrganizationSettings? settings;
  final String? message;
  final bool isRefreshing;

  OrganizationSettingsState copyWith({
    OrganizationSettingsStatus? status,
    OrganizationSettings? settings,
    String? message,
    bool? isRefreshing,
  }) {
    return OrganizationSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, settings, message, isRefreshing];
}

class OrganizationSettingsCubit extends Cubit<OrganizationSettingsState> {
  OrganizationSettingsCubit({
    required GetOrganizationSettingsUseCase getSettings,
    required UpdateOrganizationSettingsUseCase updateSettings,
    required UploadOrganizationLogoUseCase uploadLogo,
    required SessionQueryCache sessionQueryCache,
  })  : _getSettings = getSettings,
        _updateSettings = updateSettings,
        _uploadLogo = uploadLogo,
        _sessionQueryCache = sessionQueryCache,
        super(const OrganizationSettingsState());

  static const String _cacheKey = 'settings:organization';

  final GetOrganizationSettingsUseCase _getSettings;
  final UpdateOrganizationSettingsUseCase _updateSettings;
  final UploadOrganizationLogoUseCase _uploadLogo;
  final SessionQueryCache _sessionQueryCache;

  Future<void> load() async {
    final cached = _sessionQueryCache.get<OrganizationSettings>(_cacheKey);
    final hasData = cached != null || state.settings != null;

    if (hasData) {
      emit(
        state.copyWith(
          status: OrganizationSettingsStatus.success,
          settings: cached ?? state.settings,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: OrganizationSettingsStatus.loading,
          isRefreshing: false,
        ),
      );
    }

    final result = await _getSettings();
    switch (result) {
      case Success(data: final data):
        _sessionQueryCache.set(_cacheKey, data);
        emit(
          OrganizationSettingsState(
            status: OrganizationSettingsStatus.success,
            settings: data,
            isRefreshing: false,
          ),
        );
      case Failure(:final message):
        emit(
          OrganizationSettingsState(
            status: hasData
                ? OrganizationSettingsStatus.success
                : OrganizationSettingsStatus.failure,
            settings: state.settings,
            message: message,
            isRefreshing: false,
          ),
        );
    }
  }

  Future<Result<OrganizationSettings>> save(
    OrganizationSettingsUpsert input,
  ) async {
    emit(
      OrganizationSettingsState(
        status: OrganizationSettingsStatus.saving,
        settings: state.settings,
      ),
    );
    final result = await _updateSettings(input);
    switch (result) {
      case Success(data: final data):
        _sessionQueryCache.set(_cacheKey, data);
        emit(
          OrganizationSettingsState(
            status: OrganizationSettingsStatus.success,
            settings: data,
          ),
        );
      case Failure(:final message):
        emit(
          OrganizationSettingsState(
            status: OrganizationSettingsStatus.failure,
            settings: state.settings,
            message: message,
          ),
        );
    }
    return result;
  }

  Future<Result<OrganizationSettings>> uploadLogo({
    required List<int> bytes,
    required String fileName,
  }) async {
    emit(
      OrganizationSettingsState(
        status: OrganizationSettingsStatus.saving,
        settings: state.settings,
      ),
    );
    final result = await _uploadLogo(bytes: bytes, fileName: fileName);
    switch (result) {
      case Success(data: final data):
        _sessionQueryCache.set(_cacheKey, data);
        emit(
          OrganizationSettingsState(
            status: OrganizationSettingsStatus.success,
            settings: data,
          ),
        );
      case Failure(:final message):
        emit(
          OrganizationSettingsState(
            status: OrganizationSettingsStatus.failure,
            settings: state.settings,
            message: message,
          ),
        );
    }
    return result;
  }
}

enum SystemInfoStatus { initial, loading, success, failure }

class SystemInfoState extends Equatable {
  const SystemInfoState({
    this.status = SystemInfoStatus.initial,
    this.info,
    this.message,
    this.isRefreshing = false,
  });

  final SystemInfoStatus status;
  final SystemInfo? info;
  final String? message;
  final bool isRefreshing;

  SystemInfoState copyWith({
    SystemInfoStatus? status,
    SystemInfo? info,
    String? message,
    bool? isRefreshing,
  }) {
    return SystemInfoState(
      status: status ?? this.status,
      info: info ?? this.info,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, info, message, isRefreshing];
}

class SystemInfoCubit extends Cubit<SystemInfoState> {
  SystemInfoCubit({
    required GetSystemInfoUseCase getSystemInfo,
    required SessionQueryCache sessionQueryCache,
  })  : _getSystemInfo = getSystemInfo,
        _sessionQueryCache = sessionQueryCache,
        super(const SystemInfoState());

  static const String _cacheKey = 'settings:system';

  final GetSystemInfoUseCase _getSystemInfo;
  final SessionQueryCache _sessionQueryCache;

  Future<void> load() async {
    final cached = _sessionQueryCache.get<SystemInfo>(_cacheKey);
    final hasData = cached != null || state.info != null;

    if (hasData) {
      emit(
        state.copyWith(
          status: SystemInfoStatus.success,
          info: cached ?? state.info,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: SystemInfoStatus.loading,
          isRefreshing: false,
        ),
      );
    }

    final result = await _getSystemInfo();
    switch (result) {
      case Success(data: final data):
        _sessionQueryCache.set(_cacheKey, data);
        emit(
          SystemInfoState(
            status: SystemInfoStatus.success,
            info: data,
            isRefreshing: false,
          ),
        );
      case Failure(:final message):
        emit(
          SystemInfoState(
            status: hasData ? SystemInfoStatus.success : SystemInfoStatus.failure,
            info: state.info,
            message: message,
            isRefreshing: false,
          ),
        );
    }
  }
}
