import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/settings/data/datasources/holiday_local_datasource.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:mobile/features/settings/domain/services/holiday_calendar_cache.dart';

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

class GetTechnicianInterfaceSettingsUseCase {
  GetTechnicianInterfaceSettingsUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<TechnicianInterfaceConfig>> call() =>
      _repository.getTechnicianInterfaceSettings();
}

class UpdateTechnicianInterfaceSettingsUseCase {
  UpdateTechnicianInterfaceSettingsUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<TechnicianInterfaceConfig>> call(
    TechnicianInterfaceConfigUpdate input,
  ) =>
      _repository.updateTechnicianInterfaceSettings(input);
}

class GetTechnicianInterfaceConfigUseCase {
  GetTechnicianInterfaceConfigUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<TechnicianInterfaceConfig>> call() =>
      _repository.getTechnicianInterfaceConfig();
}

class ListCompanyHolidaysUseCase {
  ListCompanyHolidaysUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<CompanyHolidays>> call({String? from, String? to}) =>
      _repository.listHolidays(from: from, to: to);
}

class ReplaceCompanyHolidaysUseCase {
  ReplaceCompanyHolidaysUseCase(this._repository);
  final SettingsRepository _repository;
  Future<Result<CompanyHolidays>> call(CompanyHolidaysReplace input) =>
      _repository.replaceHolidays(input);
}

/// Sync holiday dates into durable + in-memory cache for offline OT preview.
class SyncCompanyHolidaysUseCase {
  SyncCompanyHolidaysUseCase({
    required SettingsRepository repository,
    required HolidayLocalDataSource localDataSource,
    required HolidayCalendarCache calendarCache,
  })  : _repository = repository,
        _localDataSource = localDataSource,
        _calendarCache = calendarCache;

  final SettingsRepository _repository;
  final HolidayLocalDataSource _localDataSource;
  final HolidayCalendarCache _calendarCache;

  /// Load cached dates into memory (no network). Returns cached dates.
  List<String> hydrateFromLocal(String companyId) {
    final cached = _localDataSource.readDates(companyId);
    _calendarCache.setDates(cached);
    return cached;
  }

  Future<void> persistLocal(String companyId, List<String> dates) async {
    if (companyId.isNotEmpty) {
      await _localDataSource.writeDates(companyId, dates);
    }
    _calendarCache.setDates(dates);
  }

  Future<Result<CompanyHolidays>> call({
    required String companyId,
    String? from,
    String? to,
  }) async {
    if (companyId.isNotEmpty) {
      hydrateFromLocal(companyId);
    }

    final now = DateTime.now();
    final resolvedFrom = from ??
        '${(now.year - 1).toString().padLeft(4, '0')}-01-01';
    final resolvedTo = to ??
        '${(now.year + 2).toString().padLeft(4, '0')}-12-31';

    final result = await _repository.listHolidays(
      from: resolvedFrom,
      to: resolvedTo,
    );
    switch (result) {
      case Success(data: final data):
        await persistLocal(companyId, data.dates);
        return Success(data);
      case Failure():
        // Keep Friday-only behavior when sync fails; leave any prior cache.
        return result;
    }
  }
}

@Deprecated('Use GetOvertimeMediaConfigUseCase')
typedef GetOvertimeVoiceMaxDurationUseCase = GetOvertimeMediaConfigUseCase;
