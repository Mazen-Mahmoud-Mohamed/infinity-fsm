import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/permissions.dart';
import 'package:mobile/core/utils/device_id_generator.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/data/models/current_user_model.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';
import 'package:mobile/features/organization/data/models/branch_model.dart';
import 'package:mobile/features/organization/data/models/company_model.dart';
import 'package:mobile/features/organization/data/models/organization_summary_model.dart';

void main() {
  test('DeviceIdGenerator produces a 32 character id', () {
    final deviceId = DeviceIdGenerator.generate();
    expect(deviceId.length, 32);
  });

  test('CurrentUserModel parses backend user payload', () {
    const user = CurrentUserModel(
      id: 'user-1',
      companyId: 'company-1',
      email: 'tech@example.com',
      firstName: 'Tech',
      lastName: 'User',
      fullName: 'Tech User',
      roles: ['TECHNICIAN'],
      permissions: [Permissions.overtimeViewOwn],
    );

    final parsed = CurrentUserModel.fromJson({
      'id': user.id,
      'companyId': user.companyId,
      'email': user.email,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'fullName': user.fullName,
      'roles': user.roles,
      'permissions': user.permissions,
      'organization': <String, dynamic>{
        'positionId': 'pos-1',
      },
    });

    expect(parsed.email, user.email);
    expect(parsed.roles, user.roles);
    expect(parsed.positionId, 'pos-1');
  });

  test('PermissionChecker evaluates permissions from user list', () {
    const checker = PermissionChecker([
      Permissions.overtimeViewOwn,
      Permissions.overtimeApprove,
      Permissions.workOrdersCreate,
      Permissions.organizationManageUsers,
    ]);

    expect(checker.canViewOvertime(), isTrue);
    expect(checker.canApproveOvertime(), isTrue);
    expect(checker.canCreateWorkOrder(), isTrue);
    expect(checker.canManageUsers(), isTrue);
  });

  test('Organization models parse master data payloads', () {
    final company = CompanyModel.fromJson({
      'id': 'c1',
      'code': 'infinity-tech',
      'name': 'Infinity Tech',
      'status': 'ACTIVE',
      'enabledModules': ['overtime'],
    });

    final branch = BranchModel.fromJson({
      'id': 'b1',
      'companyId': 'c1',
      'code': 'BGW-HQ',
      'name': 'Baghdad HQ',
      'status': 'ACTIVE',
      'address': {'city': 'Baghdad', 'country': 'Iraq'},
    });

    final summary = OrganizationSummaryModel.fromJson({
      'employees': 2,
      'departments': 1,
      'teams': 1,
      'branches': 1,
      'positions': 3,
      'assets': 0,
      'workOrders': 0,
      'overtime': 0,
    });

    expect(company.name, 'Infinity Tech');
    expect(branch.addressCity, 'Baghdad');
    expect(summary.employees, 2);
  });

  test('Result variants preserve values', () {
    const success = Success<int>(42);
    const failure = Failure<int>('failed');

    expect(success.data, 42);
    expect(failure.message, 'failed');
  });
}
