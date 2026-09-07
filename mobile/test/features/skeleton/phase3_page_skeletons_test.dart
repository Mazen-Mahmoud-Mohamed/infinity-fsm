import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';
import 'package:mobile/features/assets/presentation/widgets/assets_skeleton.dart';
import 'package:mobile/features/inventory/presentation/widgets/inventory_skeleton.dart';
import 'package:mobile/features/pm/presentation/widgets/preventive_maintenance_skeleton.dart';

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

  group('InventorySkeleton', () {
    testWidgets('mobile dashboard shows stats, movement bones, one scope',
        (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(
          const InventorySkeleton(
            itemCount: 7,
            semanticsLabel: 'Loading inventory',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InventorySkeleton), findsOneWidget);
      expect(find.byType(SkeletonScope), findsOneWidget);
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonCard), findsAtLeastNWidgets(4));
      expect(find.byType(SkeletonListTile), findsAtLeastNWidgets(3));
      expect(find.bySemanticsLabel('Loading inventory'), findsOneWidget);
    });

    testWidgets('desktop >=900 dashboard builds without overflow',
        (tester) async {
      await tester.pumpWidget(
        wrap(const InventorySkeleton(itemCount: 6), width: 900),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(InventorySkeleton), findsOneWidget);
    });

    testWidgets('list variant uses thumb bones and no network images',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const InventorySkeleton(
            variant: InventorySkeletonVariant.list,
            itemCount: 7,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppCachedNetworkImage), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(SkeletonCard), findsAtLeastNWidgets(3));
    });

    testWidgets('RTL builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(const InventorySkeleton(), direction: TextDirection.rtl),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('clamps item count to max 8', () {
      expect(20.clamp(1, InventorySkeleton.kMaxItems), 8);
      expect(0.clamp(1, InventorySkeleton.kMaxItems), 1);
    });
  });

  group('AssetsSkeleton', () {
    testWidgets('mobile dashboard shows five stat bones and one scope',
        (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(
          const AssetsSkeleton(semanticsLabel: 'Loading assets'),
        ),
      );
      await tester.pump();

      expect(find.byType(AssetsSkeleton), findsOneWidget);
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonCard), findsAtLeastNWidgets(5));
      expect(find.bySemanticsLabel('Loading assets'), findsOneWidget);
    });

    testWidgets('desktop >=900 dashboard builds without overflow',
        (tester) async {
      await tester.pumpWidget(
        wrap(const AssetsSkeleton(), width: 900),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('list variant has no network images', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AssetsSkeleton(
            variant: AssetsSkeletonVariant.list,
            itemCount: 7,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppCachedNetworkImage), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(SkeletonCard), findsAtLeastNWidgets(3));
    });

    testWidgets('RTL builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(const AssetsSkeleton(), direction: TextDirection.rtl),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('clamps item count to max 8', () {
      expect(20.clamp(1, AssetsSkeleton.kMaxItems), 8);
    });
  });

  group('PreventiveMaintenanceSkeleton', () {
    testWidgets('mobile dashboard shows stats and plan bones, one scope',
        (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(
          const PreventiveMaintenanceSkeleton(
            itemCount: 7,
            semanticsLabel: 'Loading preventive maintenance',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PreventiveMaintenanceSkeleton), findsOneWidget);
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonCard), findsAtLeastNWidgets(4));
      expect(
        find.bySemanticsLabel('Loading preventive maintenance'),
        findsOneWidget,
      );
    });

    testWidgets('desktop >=900 dashboard builds without overflow',
        (tester) async {
      await tester.pumpWidget(
        wrap(const PreventiveMaintenanceSkeleton(itemCount: 6), width: 900),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('list variant is bounded', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PreventiveMaintenanceSkeleton(
            variant: PreventiveMaintenanceSkeletonVariant.list,
            itemCount: 7,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SkeletonCard), findsAtLeastNWidgets(3));
    });

    testWidgets('RTL builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PreventiveMaintenanceSkeleton(),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('clamps item count to max 8', () {
      expect(20.clamp(1, PreventiveMaintenanceSkeleton.kMaxItems), 8);
    });
  });

  group('shared Phase 3 animation', () {
    testWidgets('one SkeletonScope controller for many list bones',
        (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(
          const InventorySkeleton(
            variant: InventorySkeletonVariant.list,
            itemCount: 8,
          ),
        ),
      );
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 1);
    });
  });
}
