import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/overtime/data/models/overtime_session_model.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/work_orders/data/models/work_order_model.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';

void main() {
  group('lightweight list JSON parsing', () {
    test('OvertimeSessionModel parses list projection without heavy fields', () {
      final session = OvertimeSessionModel.fromJson({
        'id': 'ot-1',
        'companyId': 'c1',
        'userId': 'u1',
        'technician': {
          'id': 'u1',
          'firstName': 'Ahmed',
          'lastName': 'Tech',
          'fullName': 'Ahmed Tech',
          'email': 'ahmed@example.com',
        },
        'type': 'NORMAL',
        'isOvernight': false,
        'status': 'PENDING_REVIEW',
        'startAt': '2026-08-12T08:00:00.000Z',
        'endAt': '2026-08-12T16:00:00.000Z',
        'createdAt': '2026-08-12T08:00:00.000Z',
        'eligibleOvertimeMinutes': 120,
        'approvedHours': null,
        'rejectionReason': null,
      });

      expect(session.id, 'ot-1');
      expect(session.type, OvertimeType.normal);
      expect(session.status, OvertimeStatus.pendingReview);
      expect(session.eligibleOvertimeMinutes, 120);
      expect(session.technician?.email, 'ahmed@example.com');
      expect(session.checkpoints, isNull);
      expect(session.startPhotoUrl, isNull);
      expect(session.rejectionReason, isNull);
    });

    test('OvertimeSessionModel still parses rejected reason on history cards', () {
      final session = OvertimeSessionModel.fromJson({
        'id': 'ot-2',
        'companyId': 'c1',
        'userId': 'u1',
        'type': 'TRAVEL',
        'isOvernight': true,
        'status': 'REJECTED',
        'startAt': '2026-08-12T08:00:00.000Z',
        'rejectionReason': 'Missing prior approval',
      });

      expect(session.status, OvertimeStatus.rejected);
      expect(session.isOvernight, isTrue);
      expect(session.rejectionReason, 'Missing prior approval');
    });

    test('WorkOrderModel parses list projection without photos/timeline', () {
      final order = WorkOrderModel.fromJson({
        'id': 'wo-1',
        'companyId': 'c1',
        'jobNumber': 'WO-20260812-0001',
        'jobTitle': 'HVAC repair',
        'customerName': 'Acme',
        'assignedTechnicianId': 'u1',
        'assignedTechnicianName': 'Ahmed Tech',
        'priority': 'HIGH',
        'status': 'IN_PROGRESS',
        'scheduledAt': '2026-08-12T11:00:00.000Z',
        'createdAt': '2026-08-12T09:00:00.000Z',
      });

      expect(order.jobNumber, 'WO-20260812-0001');
      expect(order.priority, WorkOrderPriority.high);
      expect(order.status, WorkOrderStatus.inProgress);
      expect(order.assignedTechnicianName, 'Ahmed Tech');
      expect(order.beforePhotos, isEmpty);
      expect(order.afterPhotos, isEmpty);
      expect(order.progressPhotos, isEmpty);
      expect(order.timeline, isEmpty);
      expect(order.attachments, isEmpty);
      expect(order.startedLocation, isNull);
    });
  });
}
