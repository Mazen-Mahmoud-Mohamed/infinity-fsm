import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_overtime_section.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.window.physicalSizeTestValue = const Size(800, 1600);
  binding.window.devicePixelRatioTestValue = 1.0;

  late AppLocalizations ar;
  setUpAll(() async {
    ar = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  Widget wrap({
    required double width,
    required Widget child,
  }) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(width: width, child: child),
      ),
    );
  }

  const overtime = DashboardOvertimeSummary(
    approvedOvertimeHours: 126.5, // 126h 30m
    totalOvertimeHours: 168.7, // 168h 42m
    totalTrips: 10,
    overnightTrips: 2,
    totalTechnicians: 5,
    averageHoursPerTrip: 0,
    averageOtHoursPerEmployee: 0,
    topOvertimeEmployees: [],
    hoursPerTechnician: [],
    tripsPerTechnician: [],
  );

  testWidgets('dashboard shows approved vs total overtime (phone width)',
      (tester) async {
    final approvedText = DurationFormatter.fromHours(126.5, ar);
    final totalText = DurationFormatter.fromHours(168.7, ar);

    await tester.pumpWidget(
      wrap(
        width: 360,
        child: const DashboardOvertimeSection(
          overtime: overtime,
          hoursOverTime: [],
          sectionGap: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إجمالي الساعات المعتمدة'), findsOneWidget);
    expect(find.text(approvedText), findsOneWidget);
    expect(find.text('إجمالي الساعات'), findsOneWidget);
    expect(find.text(totalText), findsOneWidget);

    // Regression: pending/unapproved must not inflate approved tile.
    expect(approvedText, isNot(totalText));
  });

  testWidgets('dashboard shows approved vs total overtime (desktop width)',
      (tester) async {
    final approvedText = DurationFormatter.fromHours(126.5, ar);
    final totalText = DurationFormatter.fromHours(168.7, ar);

    await tester.pumpWidget(
      wrap(
        width: 900,
        child: const DashboardOvertimeSection(
          overtime: overtime,
          hoursOverTime: [],
          sectionGap: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إجمالي الساعات المعتمدة'), findsOneWidget);
    expect(find.text(approvedText), findsOneWidget);
    expect(find.text('إجمالي الساعات'), findsOneWidget);
    expect(find.text(totalText), findsOneWidget);

    expect(approvedText, isNot(totalText));
  });
}

