import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/settings/data/datasources/technician_interface_local_datasource.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_navigation.dart';

class _MemoryPreferences implements PreferencesService {
  final Map<String, Object> _store = {};

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => _store[key] as bool?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _store[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => _store[key] as int?;

  @override
  Future<bool> setInt(String key, int value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }
}

void main() {
  group('TechnicianInterfaceLocalDataSource', () {
    late _MemoryPreferences preferences;
    late TechnicianInterfaceLocalDataSource dataSource;

    setUp(() {
      preferences = _MemoryPreferences();
      dataSource = TechnicianInterfaceLocalDataSource(preferences);
    });

    test('persists and restores config per company', () async {
      const companyId = 'company-1';
      const config = TechnicianInterfaceConfig(
        overtime: true,
        workOrders: true,
        attendance: false,
        profile: false,
      );

      await dataSource.write(companyId, config);
      final restored = dataSource.read(companyId);

      expect(restored?.overtime, config.overtime);
      expect(restored?.workOrders, config.workOrders);
      expect(restored?.attendance, config.attendance);
      expect(restored?.profile, config.profile);
    });

    test('cached two-tab config filters navigation offline', () async {
      const companyId = 'company-1';
      const config = TechnicianInterfaceConfig(
        overtime: true,
        workOrders: true,
        attendance: false,
        profile: false,
      );

      await dataSource.write(companyId, config);
      final restored = dataSource.read(companyId)!;

      final branches =
          TechnicianInterfaceNavigation.filteredPhoneBranches(restored);

      expect(branches, [
        TechnicianInterfaceNavigation.branchWorkOrders,
        TechnicianInterfaceNavigation.branchOvertime,
      ]);
      expect(branches, isNot(contains(TechnicianInterfaceNavigation.branchAttendance)));
      expect(branches, isNot(contains(TechnicianInterfaceNavigation.branchProfile)));
    });

    test('stores JSON under company-scoped key', () async {
      const companyId = 'company-42';
      const config = const TechnicianInterfaceConfig(
        workOrders: true,
        attendance: true,
        overtime: false,
        profile: false,
      );

      await dataSource.write(companyId, config);
      final raw = preferences.getString(
        '${StorageKeys.technicianInterfaceConfigPrefix}:$companyId',
      );

      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded['workOrders'], isTrue);
      expect(decoded['profile'], isFalse);
    });
  });
}
