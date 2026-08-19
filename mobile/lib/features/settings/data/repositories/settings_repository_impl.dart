import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required this._remote});

  final SettingsRemoteDataSource _remote;

  @override
  Future<Result<OrganizationSettings>> getOrganizationSettings() async {
    try {
      return Success(await _remote.getOrganizationSettings());
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<OrganizationSettings>> updateOrganizationSettings(
    OrganizationSettingsUpsert input,
  ) async {
    try {
      return Success(await _remote.updateOrganizationSettings(input));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<OrganizationSettings>> uploadOrganizationLogo({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      return Success(
        await _remote.uploadOrganizationLogo(bytes: bytes, fileName: fileName),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<SystemInfo>> getSystemInfo() async {
    try {
      return Success(await _remote.getSystemInfo());
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<OvertimeSettings>> getOvertimeSettings() async {
    try {
      return Success(await _remote.getOvertimeSettings());
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<OvertimeSettings>> updateOvertimeSettings(
    OvertimeSettingsUpdate input,
  ) async {
    try {
      return Success(await _remote.updateOvertimeSettings(input));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<OvertimeMediaConfigEntity>> getOvertimeMediaConfig() async {
    try {
      return Success(await _remote.getOvertimeMediaConfig());
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<TechnicianInterfaceConfig>> getTechnicianInterfaceSettings() async {
    try {
      return Success(await _remote.getTechnicianInterfaceSettings());
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<TechnicianInterfaceConfig>> updateTechnicianInterfaceSettings(
    TechnicianInterfaceConfigUpdate input,
  ) async {
    try {
      return Success(
        await _remote.updateTechnicianInterfaceSettings(input),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<TechnicianInterfaceConfig>> getTechnicianInterfaceConfig() async {
    try {
      return Success(await _remote.getTechnicianInterfaceConfig());
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }
}
