import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/settings/data/models/settings_models.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';

class SettingsRemoteDataSource {
  SettingsRemoteDataSource(this._client);
  final DioClient _client;

  Future<OrganizationSettings> getOrganizationSettings() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.settingsOrganization,
    );
    return OrganizationSettingsModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<OrganizationSettings> updateOrganizationSettings(
    OrganizationSettingsUpsert input,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      ApiConstants.settingsOrganization,
      data: {
        if (input.name != null) 'name': input.name,
        if (input.contactEmail != null) 'contactEmail': input.contactEmail,
        if (input.contactPhone != null) 'contactPhone': input.contactPhone,
        if (input.timezone != null) 'timezone': input.timezone,
        if (input.address != null)
          'address': {
            'line1': input.address!.line1,
            'line2': input.address!.line2,
            'city': input.address!.city,
            'governorate': input.address!.governorate,
            'country': input.address!.country,
            'postalCode': input.address!.postalCode,
          },
        if (input.workingHoursStart != null ||
            input.workingHoursEnd != null ||
            input.workingHoursTimezone != null)
          'workingHours': {
            if (input.workingHoursStart != null)
              'start': input.workingHoursStart,
            if (input.workingHoursEnd != null) 'end': input.workingHoursEnd,
            if (input.workingHoursTimezone != null)
              'timezone': input.workingHoursTimezone,
          },
      },
    );
    return OrganizationSettingsModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<OrganizationSettings> uploadOrganizationLogo({
    required List<int> bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'logo': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.settingsOrganizationLogo,
      data: formData,
    );
    return OrganizationSettingsModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<SystemInfo> getSystemInfo() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.settingsSystem,
    );
    return SystemInfoModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<OvertimeSettings> getOvertimeSettings() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.settingsOvertime,
    );
    return OvertimeSettingsModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<OvertimeSettings> updateOvertimeSettings(
    OvertimeSettingsUpdate input,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      ApiConstants.settingsOvertime,
      data: {
        if (input.voiceMaxDurationSeconds != null)
          'voiceMaxDurationSeconds': input.voiceMaxDurationSeconds,
        if (input.voiceRecordingQuality != null)
          'voiceRecordingQuality': input.voiceRecordingQuality,
        if (input.maxPhotoSize != null) 'maxPhotoSize': input.maxPhotoSize,
        if (input.uploadPolicy != null) 'uploadPolicy': input.uploadPolicy,
        if (input.configurationPreset != null)
          'configurationPreset': input.configurationPreset,
        if (input.restoreDefaults) 'restoreDefaults': true,
      },
    );
    return OvertimeSettingsModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<OvertimeMediaConfigEntity> getOvertimeMediaConfig() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.settingsOvertimeConfig,
    );
    return OvertimeMediaConfigModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  @Deprecated('Use getOvertimeMediaConfig')
  Future<OvertimeMediaConfigEntity> getOvertimeVoiceDurationConfig() async {
    return getOvertimeMediaConfig();
  }
}
