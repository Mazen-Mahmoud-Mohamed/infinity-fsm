import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';
import 'package:mobile/features/notifications/presentation/widgets/notifications_skeleton.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_detail_skeleton.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_orders_list_skeleton.dart';

void main() {
  tearDown(SkeletonScope.resetDebugActiveControllerCount);

  Widget wrap(
    Widget child, {
    double width = 400,
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
          data: MediaQueryData(size: Size(width, 1400)),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('WorkOrdersListSkeleton', () {
    testWidgets('mobile shows bounded card bones and one scope', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(
          const WorkOrdersListSkeleton(
            itemCount: 7,
            semanticsLabel: 'Loading work orders',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(WorkOrdersListSkeleton), findsOneWidget);
      expect(find.byType(SkeletonScope), findsOneWidget);
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonCard), findsAtLeastNWidgets(3));
      expect(find.bySemanticsLabel('Loading work orders'), findsOneWidget);
    });

    testWidgets('desktop >=900 shows table rows', (tester) async {
      await tester.pumpWidget(
        wrap(
          const WorkOrdersListSkeleton(itemCount: 6, isAdminMode: true),
          width: 900,
        ),
      );
      await tester.pump();

      expect(find.byType(SkeletonTableRow), findsWidgets);
      expect(find.byType(SkeletonTableRow), findsAtLeastNWidgets(6));
    });

    testWidgets('RTL builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(
          const WorkOrdersListSkeleton(),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('clamps item count to max 8', () {
      expect(20.clamp(1, WorkOrdersListSkeleton.kMaxItems), 8);
      expect(0.clamp(1, WorkOrdersListSkeleton.kMaxItems), 1);
    });
  });

  group('WorkOrderDetailSkeleton', () {
    testWidgets('mobile shows header/gallery/notes bones', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(wrap(const WorkOrderDetailSkeleton()));
      await tester.pump();

      expect(find.byType(WorkOrderDetailSkeleton), findsOneWidget);
      expect(find.byType(SkeletonScope), findsOneWidget);
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonGalleryGrid), findsOneWidget);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('desktop split builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(const WorkOrderDetailSkeleton(), width: 1100),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(SkeletonGalleryGrid), findsOneWidget);
    });

    testWidgets('gallery tiles are bounded', (tester) async {
      await tester.pumpWidget(wrap(const WorkOrderDetailSkeleton()));
      await tester.pump();
      final grid = tester.widget<SkeletonGalleryGrid>(
        find.byType(SkeletonGalleryGrid),
      );
      expect(grid.tileCount, lessThanOrEqualTo(8));
    });
  });

  group('NotificationsSkeleton', () {
    testWidgets('mobile shows search/chips/list bones with one scope',
        (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(
          const NotificationsSkeleton(
            itemCount: 7,
            semanticsLabel: 'Loading notifications',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NotificationsSkeleton), findsOneWidget);
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonListTile), findsNWidgets(7));
      expect(find.byType(SkeletonChip), findsWidgets);
      expect(find.bySemanticsLabel('Loading notifications'), findsOneWidget);
    });

    testWidgets('desktop split builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(const NotificationsSkeleton(itemCount: 6), width: 900),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(SkeletonListTile), findsNWidgets(6));
    });

    testWidgets('RTL builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NotificationsSkeleton(),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('shared Phase 2 primitives', () {
    testWidgets('SkeletonListTile + TableRow share one scope controller',
        (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(
          SkeletonScope(
            child: ListView(
              children: [
                for (var i = 0; i < 5; i++) const SkeletonListTile(),
                for (var i = 0; i < 5; i++)
                  const SkeletonTableRow(columnCount: 4),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 1);
    });
  });
}
