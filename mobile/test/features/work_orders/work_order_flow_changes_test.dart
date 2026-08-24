import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_labels.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_location_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

WorkOrder _sample({
  String? locationUrl,
  String? locationLabel,
  List<String> assigneeIds = const ['tech-1'],
  List<String> assigneeNames = const ['Tech One'],
  String? assignedTechnicianId = 'tech-1',
  String? assignedTechnicianName = 'Tech One',
  DateTime? scheduledAt,
}) {
  return WorkOrder(
    id: 'wo-1',
    companyId: 'co-1',
    jobNumber: 'WO-0001',
    jobTitle: 'Job',
    priority: WorkOrderPriority.critical,
    status: WorkOrderStatus.assigned,
    locationUrl: locationUrl,
    locationLabel: locationLabel,
    assignedTechnicianId: assignedTechnicianId,
    assignedTechnicianName: assignedTechnicianName,
    assignedTechnicianIds: assigneeIds,
    assignedTechnicianNames: assigneeNames,
    scheduledAt: scheduledAt,
  );
}

void main() {
  group('WorkOrder localization labels', () {
    testWidgets('Arabic shows أمر الشغل and طارئ', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10n.workOrderJobTitle, 'أمر الشغل');
      expect(l10n.workOrderJobTitle.contains('عنوان أمر العمل'), isFalse);
      expect(workOrderPriorityLabel(l10n, WorkOrderPriority.critical), 'طارئ');
      expect(l10n.workOrderNotes, 'الملاحظات');
      expect(l10n.workOrderTechnicians, 'الفنيون');
      expect(l10n.workOrderVoiceNote, 'ملاحظة صوتية');
    });

    testWidgets('English shows Work Order and Urgent', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10n.workOrderJobTitle, 'Work Order');
      expect(workOrderPriorityLabel(l10n, WorkOrderPriority.critical), 'Urgent');
      expect(l10n.workOrderNotes, 'Notes');
      expect(l10n.workOrderTechnicians, 'Technicians');
    });
  });

  group('WorkOrder location URL', () {
    test('validates http(s) URLs', () {
      expect(
        WorkOrderLocationLauncher.isValidHttpUrl(
          'https://maps.google.com/?q=24.7,46.6',
        ),
        isTrue,
      );
      expect(
        WorkOrderLocationLauncher.isValidHttpUrl('not-a-url'),
        isFalse,
      );
      expect(WorkOrderLocationLauncher.isValidHttpUrl(''), isFalse);
      expect(WorkOrderLocationLauncher.isValidHttpUrl(null), isFalse);
    });

    test('effectiveLocationUrl and hasOpenableLocationUrl', () {
      final withUrl = _sample(
        locationUrl: 'https://maps.app.goo.gl/abc',
        locationLabel: 'legacy address',
      );
      expect(withUrl.hasOpenableLocationUrl, isTrue);
      expect(withUrl.effectiveLocationUrl, 'https://maps.app.goo.gl/abc');

      final labelOnlyUrl = _sample(
        locationUrl: null,
        locationLabel: 'https://maps.google.com/?q=1,2',
      );
      expect(labelOnlyUrl.hasOpenableLocationUrl, isTrue);

      final addressOnly = _sample(
        locationUrl: null,
        locationLabel: 'King Fahd Road',
      );
      expect(addressOnly.hasOpenableLocationUrl, isFalse);
      expect(addressOnly.locationDisplay, 'King Fahd Road');
    });
  });

  group('WorkOrder multi-technician', () {
    test('effectiveAssigneeIds supports legacy single assignee', () {
      final legacy = _sample(
        assigneeIds: const [],
        assigneeNames: const [],
        assignedTechnicianId: 'tech-legacy',
        assignedTechnicianName: 'Legacy Tech',
      );
      expect(legacy.effectiveAssigneeIds, ['tech-legacy']);
      expect(legacy.isAssignedTo('tech-legacy'), isTrue);
      expect(legacy.isAssignedTo('other'), isFalse);
      expect(legacy.assigneesDisplay, 'Legacy Tech');
    });

    test('multi assignees visible to each technician without duplication of ids', () {
      final multi = _sample(
        assigneeIds: const ['tech-1', 'tech-2'],
        assigneeNames: const ['A', 'B'],
      );
      expect(multi.isAssignedTo('tech-1'), isTrue);
      expect(multi.isAssignedTo('tech-2'), isTrue);
      expect(multi.effectiveAssigneeIds.toSet().length, 2);
      expect(multi.assigneesDisplay, 'A, B');
    });
  });

  group('WorkOrder scheduled datetime', () {
    test('preserves full DateTime including time', () {
      final at = DateTime.utc(2026, 8, 24, 10, 30);
      final wo = _sample(scheduledAt: at);
      expect(wo.scheduledAt, at);
      expect(wo.scheduledAt!.hour, 10);
      expect(wo.scheduledAt!.minute, 30);
    });

    test('null scheduledAt is safe', () {
      final wo = _sample(scheduledAt: null);
      expect(wo.scheduledAt, isNull);
    });
  });
}
