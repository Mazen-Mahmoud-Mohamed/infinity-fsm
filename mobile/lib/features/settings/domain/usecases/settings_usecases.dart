import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/repositories/settings_repository.dart';

class GetOrganizationSettingsUseCase {
  GetOrganizationSettingsUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<OrganizationSettings>> call() =>
      _repository.getOrganizationSettings();
}

class UpdateOrganizationSettingsUseCase {
  UpdateOrganizationSettingsUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<OrganizationSettings>> call(OrganizationSettingsUpsert input) =>
      _repository.updateOrganizationSettings(input);
}

class UploadOrganizationLogoUseCase {
  UploadOrganizationLogoUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<OrganizationSettings>> call({
    required List<int> bytes,
    required String fileName,
  }) =>
      _repository.uploadOrganizationLogo(bytes: bytes, fileName: fileName);
}

class GetSystemInfoUseCase {
  GetSystemInfoUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<SystemInfo>> call() => _repository.getSystemInfo();
}

class GetOvertimeSettingsUseCase {
  GetOvertimeSettingsUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<OvertimeSettings>> call() => _repository.getOvertimeSettings();
}

class UpdateOvertimeSettingsUseCase {
  UpdateOvertimeSettingsUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<OvertimeSettings>> call(OvertimeSettingsUpdate input) =>
      _repository.updateOvertimeSettings(input);
}

class GetOvertimeMediaConfigUseCase {
  GetOvertimeMediaConfigUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<OvertimeMediaConfigEntity>> call() =>
      _repository.getOvertimeMediaConfig();
}

@Deprecated('Use GetOvertimeMediaConfigUseCase')
typedef GetOvertimeVoiceMaxDurationUseCase = GetOvertimeMediaConfigUseCase;
