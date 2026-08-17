import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_dense_widgets.dart';

void main() {
  Widget wrap(
    Widget child, {
    required double width,
    Locale locale = const Locale('ar'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900), textScaler: TextScaler.noScaling),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(child: child),
            ),
          ),
        ),
      ),
    );
  }

  const overview = DashboardWorkforceOverview(
    totalEmployees: 12,
    activeEmployees: 10,
    currentlyWorking: 0,
    averageWorkingHoursLabel: '8 hours',
  );

  group('DashboardWorkforceOverview mobile layout', () {
    Future<void> pumpMobile(WidgetTester tester, double width) async {
      await tester.pumpWidget(wrap(overview, width: width));
      await tester.pumpAndSettle();
    }

    for (final width in [360.0, 390.0, 430.0]) {
      testWidgets('compact 2x2 grid with icons at ${width.toInt()}px', (
        tester,
      ) async {
        await pumpMobile(tester, width);

        expect(find.text('القوى العاملة'), findsOneWidget);
        expect(find.text('إجمالي الموظفين'), findsOneWidget);
        expect(find.text('الموظفون النشطون'), findsOneWidget);
        expect(find.text('يعملون حالياً'), findsOneWidget);
        expect(find.text('متوسط ساعات العمل'), findsOneWidget);
        expect(find.text('12'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);

        expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
        expect(find.byIcon(Icons.people_alt_outlined), findsOneWidget);
        expect(find.byIcon(Icons.work_outline), findsOneWidget);
        expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);

        final cardHeight =
            tester.getSize(find.byType(DashboardWorkforceOverview)).height;
        expect(cardHeight, lessThan(220));
      });
    }
  });

  group('DashboardWorkforceOverview desktop layout', () {
    testWidgets('preserves desktop metric rows without icon cells at 900px', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          overview,
          width: 900,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workforce'), findsOneWidget);
      expect(find.text('Total employees'), findsOneWidget);
      expect(find.text('12'), findsWidgets);

      expect(
        find.descendant(
          of: find.byType(DashboardWorkforceOverview),
          matching: find.byIcon(Icons.groups_outlined),
        ),
        findsNothing,
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
