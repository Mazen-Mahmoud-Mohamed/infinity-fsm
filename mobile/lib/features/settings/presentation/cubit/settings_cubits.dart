import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_configuration_presets.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';
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
    required this._getSettings,
    required this._updateSettings,
    required this._uploadLogo,
    required this._sessionQueryCache,
  }) : super(const OrganizationSettingsState());

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
    required this._getSystemInfo,
    required this._sessionQueryCache,
  }) : super(const SystemInfoState());

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

enum OvertimeSettingsStatus { initial, loading, saving, success, failure }

class OvertimeSettingsState extends Equatable {
  const OvertimeSettingsState({
    this.status = OvertimeSettingsStatus.initial,
    this.settings,
    this.message,
    this.isRefreshing = false,
    this.activePresetId = OvertimeConfigurationPreset.customId,
  });

  final OvertimeSettingsStatus status;
  final OvertimeSettings? settings;
  final String? message;
  final bool isRefreshing;
  final String activePresetId;

  OvertimeSettingsState copyWith({
    OvertimeSettingsStatus? status,
    OvertimeSettings? settings,
    String? message,
    bool? isRefreshing,
    String? activePresetId,
  }) {
    return OvertimeSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }

  @override
  List<Object?> get props =>
      [status, settings, message, isRefreshing, activePresetId];
}

class OvertimeSettingsCubit extends Cubit<OvertimeSettingsState> {
  OvertimeSettingsCubit({
    required this._getSettings,
    required this._updateSettings,
    required this._sessionQueryCache,
  }) : super(const OvertimeSettingsState());

  static const String _cacheKey = 'settings:overtime';

  final GetOvertimeSettingsUseCase _getSettings;
  final UpdateOvertimeSettingsUseCase _updateSettings;
  final SessionQueryCache _sessionQueryCache;

  Future<void> load() async {
    final cached = _sessionQueryCache.get<OvertimeSettings>(_cacheKey);
    final hasData = cached != null || state.settings != null;

    if (hasData) {
      emit(
        state.copyWith(
          status: OvertimeSettingsStatus.success,
          settings: cached ?? state.settings,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: OvertimeSettingsStatus.loading,
          isRefreshing: false,
        ),
      );
    }

    final result = await _getSettings();
    switch (result) {
      case Success(data: final data):
        _sessionQueryCache.set(_cacheKey, data);
        emit(
          OvertimeSettingsState(
            status: OvertimeSettingsStatus.success,
            settings: data,
            isRefreshing: false,
            activePresetId: OvertimeConfigurationPreset.detectPresetId(data),
          ),
        );
      case Failure(:final message):
        emit(
          OvertimeSettingsState(
            status: hasData
                ? OvertimeSettingsStatus.success
                : OvertimeSettingsStatus.failure,
            settings: state.settings,
            message: message,
            isRefreshing: false,
          ),
        );
    }
  }

  Future<Result<OvertimeSettings>> _save(OvertimeSettingsUpdate update) async {
    emit(
      OvertimeSettingsState(
        status: OvertimeSettingsStatus.saving,
        settings: state.settings,
      ),
    );
    final result = await _updateSettings(update);
    switch (result) {
      case Success(data: final data):
        _sessionQueryCache.set(_cacheKey, data);
        _sessionQueryCache.invalidate('settings:overtime:media_config');
        _sessionQueryCache.invalidate('settings:overtime:voice_max_duration_seconds');
        emit(
          OvertimeSettingsState(
            status: OvertimeSettingsStatus.success,
            settings: data,
            activePresetId: OvertimeConfigurationPreset.detectPresetId(data),
          ),
        );
      case Failure(:final message):
        emit(
          OvertimeSettingsState(
            status: OvertimeSettingsStatus.failure,
            settings: state.settings,
            message: message,
          ),
        );
    }
    return result;
  }

  Future<Result<OvertimeSettings>> saveVoiceMaxDuration(int minutes) =>
      _save(
        OvertimeSettingsUpdate(
          voiceMaxDurationSeconds:
              OvertimeMediaConfig.secondsFromMinutes(minutes),
          configurationPreset: OvertimeConfigurationPreset.customId,
        ),
      );

  Future<Result<OvertimeSettings>> saveVoiceQuality(String quality) => _save(
        OvertimeSettingsUpdate(
          voiceRecordingQuality: quality,
          configurationPreset: OvertimeConfigurationPreset.customId,
        ),
      );

  Future<Result<OvertimeSettings>> saveMaxPhotoSize(Object size) => _save(
        OvertimeSettingsUpdate(
          maxPhotoSize: size,
          configurationPreset: OvertimeConfigurationPreset.customId,
        ),
      );

  Future<Result<OvertimeSettings>> saveUploadPolicy(String policy) => _save(
        OvertimeSettingsUpdate(
          uploadPolicy: policy,
          configurationPreset: OvertimeConfigurationPreset.customId,
        ),
      );

  Future<Result<OvertimeSettings>> applyPreset(
    OvertimeConfigurationPreset preset,
  ) =>
      _save(preset.toUpdate());

  Future<Result<OvertimeSettings>> restoreDefaults() =>
      _save(OvertimeConfigurationPreset.defaultSettingsUpdate());
}
