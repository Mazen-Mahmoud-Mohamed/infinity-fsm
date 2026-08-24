import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_phone_numbers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('WorkOrderPhoneNumbers', () {
    test('optional: empty input normalizes to empty list', () {
      expect(WorkOrderPhoneNumbers.normalize(const []), isEmpty);
      expect(WorkOrderPhoneNumbers.normalize(const ['', '  ']), isEmpty);
    });

    test('normalizes one and multiple numbers; skips empties; dedupes digits', () {
      expect(
        WorkOrderPhoneNumbers.normalize(const ['+201012345678']),
        ['+201012345678'],
      );
      expect(
        WorkOrderPhoneNumbers.normalize(const [
          '+201012345678',
          '',
          '+966501234567',
          '+2010 1234 5678',
        ]),
        ['+201012345678', '+966501234567'],
      );
    });

    test('dialerUri builds tel: URI without placing a call', () {
      final uri = WorkOrderPhoneNumbers.dialerUri('+2010 1234 5678');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'tel');
      expect(uri.path.contains('2010'), isTrue);
      expect(WorkOrderPhoneNumbers.dialerUri('bad'), isNull);
      expect(WorkOrderPhoneNumbers.dialerUri(''), isNull);
    });

    test('entity with zero phones has no call UI data', () {
      const wo = WorkOrder(
        id: '1',
        companyId: 'c',
        jobNumber: 'WO-1',
        jobTitle: 't',
        priority: WorkOrderPriority.medium,
        status: WorkOrderStatus.assigned,
      );
      expect(wo.customerPhoneNumbers, isEmpty);
    });

    test('entity exposes one and multiple phones', () {
      final one = WorkOrder(
        id: '1',
        companyId: 'c',
        jobNumber: 'WO-1',
        jobTitle: 't',
        priority: WorkOrderPriority.medium,
        status: WorkOrderStatus.assigned,
        customerPhoneNumbers: const ['+201011111111'],
      );
      final multi = WorkOrder(
        id: '2',
        companyId: 'c',
        jobNumber: 'WO-2',
        jobTitle: 't',
        priority: WorkOrderPriority.medium,
        status: WorkOrderStatus.assigned,
        customerPhoneNumbers: const ['+201011111111', '+201022222222'],
      );
      expect(one.customerPhoneNumbers.length, 1);
      expect(multi.customerPhoneNumbers.length, 2);
      expect(
        WorkOrderPhoneNumbers.dialerUri(one.customerPhoneNumbers.first),
        isNotNull,
      );
      expect(
        WorkOrderPhoneNumbers.dialerUri(multi.customerPhoneNumbers[1])!.path,
        contains('201022222222'),
      );
    });
  });

  group('Customer phone localization', () {
    testWidgets('Arabic and English phone labels', (tester) async {
      late AppLocalizations ar;
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
              ar = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(ar.workOrderCustomerPhoneNumbers, 'رقم العميل');
      expect(ar.workOrderAddPhoneNumber, 'إضافة رقم');
      expect(ar.workOrderChooseCustomerNumber, 'اختر رقم العميل');
      expect(ar.workOrderCall, 'اتصال');

      late AppLocalizations en;
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
              en = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(en.workOrderCustomerPhoneNumbers, 'Customer Phone Numbers');
      expect(en.workOrderAddPhoneNumber, 'Add Number');
      expect(en.workOrderChooseCustomerNumber, 'Choose a customer number');
      expect(en.workOrderCall, 'Call');
    });
  });
}
