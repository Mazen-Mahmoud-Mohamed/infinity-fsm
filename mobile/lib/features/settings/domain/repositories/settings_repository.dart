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
}
