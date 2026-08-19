import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';

abstract class SettingsRepository {
  Future<Result<OrganizationSettings>> getOrganizationSettings();

  Future<Result<OrganizationSettings>> updateOrganizationSettings(
    OrganizationSettingsUpsert input,
  );

  Future<Result<OrganizationSettings>> uploadOrganizationLogo({
    required List<int> bytes,
    required String fileName,
  });

  Future<Result<SystemInfo>> getSystemInfo();

  Future<Result<OvertimeSettings>> getOvertimeSettings();

  Future<Result<OvertimeSettings>> updateOvertimeSettings(
    OvertimeSettingsUpdate input,
  );

  Future<Result<OvertimeMediaConfigEntity>> getOvertimeMediaConfig();

  Future<Result<TechnicianInterfaceConfig>> getTechnicianInterfaceSettings();

  Future<Result<TechnicianInterfaceConfig>> updateTechnicianInterfaceSettings(
    TechnicianInterfaceConfigUpdate input,
  );

  Future<Result<TechnicianInterfaceConfig>> getTechnicianInterfaceConfig();
}
