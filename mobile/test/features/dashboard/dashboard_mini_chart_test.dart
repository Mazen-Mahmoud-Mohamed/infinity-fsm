import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_mini_chart.dart';

void main() {
  Widget wrap(
    Widget child, {
    required double width,
    TextDirection direction = TextDirection.ltr,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: TextScaler.noScaling,
          ),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  const threeBarPoints = [
    DashboardChartPoint(label: 'First', value: 30),
    DashboardChartPoint(label: 'Second', value: 20),
    DashboardChartPoint(label: 'Third', value: 10),
  ];

  Finder barChartPaint(Finder chart) {
    return find.descendant(
      of: chart,
      matching: find.descendant(
        of: find.byType(GestureDetector),
        matching: find.byType(CustomPaint),
      ),
    );
  }

  Future<void> expectLabelBarAlignment(
    WidgetTester tester, {
    required Finder chart,
    required List<String> labels,
  }) async {
    final paintFinder = barChartPaint(chart);
    expect(paintFinder, findsOneWidget);

    final paintBox = tester.renderObject<RenderBox>(paintFinder);
    final plotWidth = paintBox.size.width;
    final plotLeft = paintBox.localToGlobal(Offset.zero).dx;
    final geometry = DashboardBarChartGeometry(
      plotWidth: plotWidth,
      barCount: labels.length,
    );

    for (var i = 0; i < labels.length; i++) {
      final expectedBarCenter = plotLeft + geometry.barCenterX(i);
      final labelBox = tester.renderObject<RenderBox>(find.text(labels[i]));
      final labelCenter = labelBox.localToGlobal(
        Offset(labelBox.size.width / 2, 0),
      ).dx;

      expect(
        labelCenter,
        closeTo(expectedBarCenter, 2.0),
        reason: 'Label "${labels[i]}" should center on bar $i',
      );
    }
  }

  group('DashboardMiniChart duration presentation', () {
    testWidgets('hours kind shows human-readable tooltip, not decimal', (
      tester,
    ) async {
      const points = [
        DashboardChartPoint(label: 'Field Technician', value: 122.7),
        DashboardChartPoint(label: 'Test User', value: 45.0),
      ];

      await tester.pumpWidget(
        wrap(
          const DashboardMiniChart(
            title: 'Hours per Technician',
            points: points,
            valueKind: DashboardChartValueKind.hours,
            embedded: true,
          ),
          width: 360,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('122.7'), findsNothing);

      final chart = find.byType(DashboardMiniChart);
      final paintBox =
          tester.renderObject<RenderBox>(barChartPaint(chart));
      final tapX = DashboardBarChartGeometry(
        plotWidth: paintBox.size.width,
        barCount: 2,
      ).barCenterX(0);
      await tester.tapAt(
        paintBox.localToGlobal(Offset(tapX, paintBox.size.height / 2)),
      );
      await tester.pumpAndSettle();

      expect(find.text('122 hours 42 minutes'), findsOneWidget);
      expect(find.textContaining('122.7'), findsNothing);
    });

    testWidgets('hours over time axis uses duration labels at 360px', (
      tester,
    ) async {
      final points = List<DashboardChartPoint>.generate(
        30,
        (i) => DashboardChartPoint(label: '${i + 1}', value: 88 - i * 2.0),
      );

      await tester.pumpWidget(
        wrap(
          DashboardMiniChart(
            title: 'Hours over Time',
            points: points,
            valueKind: DashboardChartValueKind.hours,
            embedded: true,
            height: 168,
          ),
          width: 360,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('88'), findsNothing);
      expect(find.textContaining('88 hours'), findsWidgets);
      expect(find.textContaining('8…'), findsNothing);
    });
  });

  group('DashboardMiniChart label/bar geometry alignment', () {
    for (final width in [360.0, 390.0, 430.0, 900.0]) {
      testWidgets('LTR label centers match bar centers at ${width.toInt()}px', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(
            const DashboardMiniChart(
              title: 'Hours per Technician',
              points: threeBarPoints,
              valueKind: DashboardChartValueKind.hours,
              embedded: true,
              height: 168,
            ),
            width: width,
            direction: TextDirection.ltr,
          ),
        );
        await tester.pumpAndSettle();

        final chart = find.byType(DashboardMiniChart);
        await expectLabelBarAlignment(
          tester,
          chart: chart,
          labels: const ['First', 'Second', 'Third'],
        );
      });

      testWidgets('RTL label centers match bar centers at ${width.toInt()}px', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(
            const DashboardMiniChart(
              title: 'Hours per Technician',
              points: threeBarPoints,
              valueKind: DashboardChartValueKind.hours,
              embedded: true,
              height: 168,
            ),
            width: width,
            direction: TextDirection.rtl,
          ),
        );
        await tester.pumpAndSettle();

        final chart = find.byType(DashboardMiniChart);
        await expectLabelBarAlignment(
          tester,
          chart: chart,
          labels: const ['First', 'Second', 'Third'],
        );
      });
    }
  });
}
