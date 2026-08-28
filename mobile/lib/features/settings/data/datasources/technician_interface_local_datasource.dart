import 'dart:convert';

import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/settings/data/models/settings_models.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';

/// Persists the last known technician interface flags per company.
class TechnicianInterfaceLocalDataSource {
  TechnicianInterfaceLocalDataSource(this._preferences);

  final PreferencesService _preferences;

  static String cacheKeyFor(String companyId) =>
      '${StorageKeys.technicianInterfaceConfigPrefix}:$companyId';

  TechnicianInterfaceConfig? read(String companyId) {
    if (companyId.isEmpty) return null;
    final raw = _preferences.getString(cacheKeyFor(companyId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return TechnicianInterfaceConfigModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on Object {
      return null;
    }
  }

  Future<void> write(String companyId, TechnicianInterfaceConfig config) async {
    if (companyId.isEmpty) return;
    final model = config is TechnicianInterfaceConfigModel
        ? config
        : TechnicianInterfaceConfigModel(
            overtime: config.overtime,
            workOrders: config.workOrders,
            attendance: config.attendance,
            profile: config.profile,
          );
    await _preferences.setString(
      cacheKeyFor(companyId),
      jsonEncode(model.toJson()),
    );
  }

  Future<void> clear(String companyId) async {
    if (companyId.isEmpty) return;
    await _preferences.remove(cacheKeyFor(companyId));
  }
}
