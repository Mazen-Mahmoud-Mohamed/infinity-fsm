import 'dart:convert';

import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/organization/data/cache/organization_cache_keys.dart';
import 'package:mobile/features/organization/data/models/branch_model.dart';
import 'package:mobile/features/organization/data/models/company_model.dart';
import 'package:mobile/features/organization/data/models/department_model.dart';
import 'package:mobile/features/organization/data/models/organization_context_model.dart';
import 'package:mobile/features/organization/data/models/organization_summary_model.dart';
import 'package:mobile/features/organization/data/models/position_model.dart';
import 'package:mobile/features/organization/data/models/team_model.dart';
import 'package:mobile/features/organization/data/models/user_summary_model.dart';

class OrganizationLocalDataSource {
  OrganizationLocalDataSource(this._preferences);

  final PreferencesService _preferences;

  Future<void> saveContext(OrganizationContextModel context) {
    return _preferences.setString(
      OrganizationCacheKeys.context,
      jsonEncode(context.toJson()),
    );
  }

  OrganizationContextModel? readContext() {
    final raw = _preferences.getString(OrganizationCacheKeys.context);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return OrganizationContextModel.fromJson(decoded);
  }

  Future<void> saveSummary(OrganizationSummaryModel summary) {
    return _preferences.setString(
      OrganizationCacheKeys.summary,
      jsonEncode(summary.toJson()),
    );
  }

  OrganizationSummaryModel? readSummary() {
    final raw = _preferences.getString(OrganizationCacheKeys.summary);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return OrganizationSummaryModel.fromJson(decoded);
  }

  Future<void> saveCompanies(List<CompanyModel> items) {
    return _saveList(
      OrganizationCacheKeys.companies,
      items.map((item) => item.toJson()).toList(),
    );
  }

  List<CompanyModel> readCompanies() {
    return _readList(
      OrganizationCacheKeys.companies,
      CompanyModel.fromJson,
    );
  }

  Future<void> saveBranches(List<BranchModel> items) {
    return _saveList(
      OrganizationCacheKeys.branches,
      items.map((item) => item.toJson()).toList(),
    );
  }

  List<BranchModel> readBranches() {
    return _readList(
      OrganizationCacheKeys.branches,
      BranchModel.fromJson,
    );
  }

  Future<void> saveDepartments(List<DepartmentModel> items) {
    return _saveList(
      OrganizationCacheKeys.departments,
      items.map((item) => item.toJson()).toList(),
    );
  }

  List<DepartmentModel> readDepartments() {
    return _readList(
      OrganizationCacheKeys.departments,
      DepartmentModel.fromJson,
    );
  }

  Future<void> saveTeams(List<TeamModel> items) {
    return _saveList(
      OrganizationCacheKeys.teams,
      items.map((item) => item.toJson()).toList(),
    );
  }

  List<TeamModel> readTeams() {
    return _readList(OrganizationCacheKeys.teams, TeamModel.fromJson);
  }

  Future<void> savePositions(List<PositionModel> items) {
    return _saveList(
      OrganizationCacheKeys.positions,
      items.map((item) => item.toJson()).toList(),
    );
  }

  List<PositionModel> readPositions() {
    return _readList(
      OrganizationCacheKeys.positions,
      PositionModel.fromJson,
    );
  }

  Future<void> saveUsers(List<UserSummaryModel> items) {
    return _saveList(
      OrganizationCacheKeys.users,
      items.map((item) => item.toJson()).toList(),
    );
  }

  List<UserSummaryModel> readUsers() {
    return _readList(
      OrganizationCacheKeys.users,
      UserSummaryModel.fromJson,
    );
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> items) {
    return _preferences.setString(key, jsonEncode(items));
  }

  List<T> _readList<T>(
    String key,
    T Function(Map<String, dynamic> json) mapper,
  ) {
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(mapper)
        .toList();
  }
}
