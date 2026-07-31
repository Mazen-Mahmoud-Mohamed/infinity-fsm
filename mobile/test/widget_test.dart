import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/permissions.dart';
import 'package:mobile/core/utils/device_id_generator.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/data/models/attendance_status_snapshot_model.dart';
import 'package:mobile/features/attendance/data/models/pending_attendance_action_model.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_event.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/attendance/domain/services/attendance_rules.dart';
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
      'attendance': 0,
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

  group('AttendanceRules', () {
    test('clock in only allowed when not started', () {
      expect(
        () => AttendanceRules.assertCanClockIn(AttendanceStatus.notStarted),
        returnsNormally,
      );
      expect(
        () => AttendanceRules.assertCanClockIn(AttendanceStatus.clockedIn),
        throwsA(isA<AttendanceRuleViolation>()),
      );
    });

    test('clock out blocked while on break or before clock in', () {
      expect(
        () => AttendanceRules.assertCanClockOut(AttendanceStatus.notStarted),
        throwsA(isA<AttendanceRuleViolation>()),
      );
      expect(
        () => AttendanceRules.assertCanClockOut(AttendanceStatus.onBreak),
        throwsA(isA<AttendanceRuleViolation>()),
      );
      expect(
        () => AttendanceRules.assertCanClockOut(AttendanceStatus.clockedIn),
        returnsNormally,
      );
    });

    test('break start rejects double breaks', () {
      expect(
        () => AttendanceRules.assertCanStartBreak(AttendanceStatus.onBreak),
        throwsA(isA<AttendanceRuleViolation>()),
      );
      expect(
        () => AttendanceRules.assertCanStartBreak(AttendanceStatus.clockedIn),
        returnsNormally,
      );
    });

    test('break end requires an active break', () {
      expect(
        () => AttendanceRules.assertCanEndBreak(AttendanceStatus.clockedIn),
        throwsA(isA<AttendanceRuleViolation>()),
      );
      expect(
        () => AttendanceRules.assertCanEndBreak(AttendanceStatus.onBreak),
        returnsNormally,
      );
    });

    test('GPS accuracy beyond threshold is rejected', () {
      final gps = GpsSnapshot(
        latitude: 33.3,
        longitude: 44.4,
        accuracy: 250,
        recordedAt: DateTime.now(),
      );

      expect(
        () => AttendanceRules.assertGpsAccuracy(gps, 100),
        throwsA(isA<AttendanceGpsRejected>()),
      );
    });
  });

  test('AttendanceStatusSnapshotModel round-trips through JSON', () {
    final snapshot = AttendanceStatusSnapshotModel(
      status: AttendanceStatus.onBreak,
      date: '2026-07-30',
      workingMinutes: 120,
      breakMinutes: 15,
      breakCount: 1,
      liveWorkingSeconds: 7200,
      serverTime: DateTime.utc(2026, 7, 30, 12),
      clockInAt: DateTime.utc(2026, 7, 30, 9),
      activeBreakStartAt: DateTime.utc(2026, 7, 30, 12),
    );

    final parsed = AttendanceStatusSnapshotModel.fromJson(snapshot.toJson());

    expect(parsed.status, AttendanceStatus.onBreak);
    expect(parsed.workingMinutes, 120);
    expect(parsed.breakCount, 1);
  });

  test('PendingAttendanceActionModel round-trips selfie bytes via base64', () {
    final action = PendingAttendanceActionModel(
      clientEventId: 'evt-1',
      type: AttendanceEventType.clockIn,
      gps: GpsSnapshot(
        latitude: 33.3,
        longitude: 44.4,
        accuracy: 12,
        recordedAt: DateTime.utc(2026, 7, 30, 9),
      ),
      selfieBytes: Uint8List.fromList([1, 2, 3, 4]),
      deviceId: 'device-1',
      clientRecordedAt: DateTime.utc(2026, 7, 30, 9),
      createdAt: DateTime.utc(2026, 7, 30, 9, 1),
    );

    final parsed = PendingAttendanceActionModel.fromJson(action.toJson());

    expect(parsed.clientEventId, 'evt-1');
    expect(parsed.type, AttendanceEventType.clockIn);
    expect(parsed.selfieBytes, [1, 2, 3, 4]);
  });
}
