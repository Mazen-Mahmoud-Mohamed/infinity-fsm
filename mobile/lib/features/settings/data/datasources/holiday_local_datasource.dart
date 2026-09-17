import 'dart:convert';

import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/storage/preferences_service.dart';

/// Durable per-company holiday date keys for offline overtime calculation.
class HolidayLocalDataSource {
  HolidayLocalDataSource(this._preferences);

  final PreferencesService _preferences;

  static String cacheKeyFor(String companyId) =>
      '${StorageKeys.holidayDatesPrefix}:$companyId';

  List<String> readDates(String companyId) {
    if (companyId.isEmpty) return const [];
    final raw = _preferences.getString(cacheKeyFor(companyId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  Future<void> writeDates(String companyId, List<String> dates) async {
    if (companyId.isEmpty) return;
    final unique = <String>{
      for (final d in dates)
        if (d.trim().isNotEmpty) d.trim(),
    }.toList()
      ..sort();
    await _preferences.setString(cacheKeyFor(companyId), jsonEncode(unique));
  }

  Future<void> clear(String companyId) async {
    if (companyId.isEmpty) return;
    await _preferences.remove(cacheKeyFor(companyId));
  }
}
