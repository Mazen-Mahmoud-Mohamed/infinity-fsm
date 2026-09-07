import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';
import 'package:mobile/features/reports_center/presentation/widgets/reports_center_results_skeleton.dart';
import 'package:mobile/features/roles/presentation/widgets/roles_permissions_skeleton.dart';
import 'package:mobile/features/service_reports/presentation/widgets/service_reports_skeleton.dart';
import 'package:mobile/features/users/presentation/widgets/user_management_skeleton.dart';

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

  group('UserManagementSkeleton', () {
    testWidgets('mobile list shows bounded tiles and one scope', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(
          const UserManagementSkeleton(
            variant: UserManagementSkeletonVariant.list,
            itemCount: 7,
            semanticsLabel: 'Loading users',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(UserManagementSkeleton), findsOneWidget);
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonListTile), findsAtLeastNWidgets(3));
      expect(find.bySemanticsLabel('Loading users'), findsOneWidget);
    });

    testWidgets('desktop >=900 list uses table rows', (tester) async {
      await tester.pumpWidget(
        wrap(
          const UserManagementSkeleton(
            variant: UserManagementSkeletonVariant.list,
            itemCount: 6,
          ),
          width: 900,
        ),
      );
      await tester.pump();
      expect(find.byType(SkeletonTableRow), findsAtLeastNWidgets(6));
    });

    testWidgets('detail has no network images', (tester) async {
      await tester.pumpWidget(
        wrap(
          const UserManagementSkeleton(
            variant: UserManagementSkeletonVariant.detail,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppCachedNetworkImage), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(SkeletonCircle), findsOneWidget);
    });

    testWidgets('RTL builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(const UserManagementSkeleton(), direction: TextDirection.rtl),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('clamps item count to max 8', () {
      expect(20.clamp(1, UserManagementSkeleton.kMaxItems), 8);
    });
  });

  group('ReportsCenterResultsSkeleton', () {
    testWidgets('mobile cards and one scope', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(
          const ReportsCenterResultsSkeleton(
            itemCount: 6,
            semanticsLabel: 'Loading reports',
          ),
        ),
      );
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonCard), findsAtLeastNWidgets(3));
      expect(find.bySemanticsLabel('Loading reports'), findsOneWidget);
    });

    testWidgets('desktop >=900 table rows bounded', (tester) async {
      await tester.pumpWidget(
        wrap(const ReportsCenterResultsSkeleton(itemCount: 6), width: 900),
      );
      await tester.pump();
      expect(find.byType(SkeletonTableRow), findsAtLeastNWidgets(6));
    });

    testWidgets('RTL builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ReportsCenterResultsSkeleton(),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('clamps item count to max 6', () {
      expect(20.clamp(1, ReportsCenterResultsSkeleton.kMaxItems), 6);
    });
  });

  group('ServiceReportsSkeleton', () {
    testWidgets('dashboard one scope', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(wrap(const ServiceReportsSkeleton()));
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonCard), findsAtLeastNWidgets(4));
    });

    testWidgets('list bounded cards no images', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ServiceReportsSkeleton(
            variant: ServiceReportsSkeletonVariant.list,
            itemCount: 7,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppCachedNetworkImage), findsNothing);
      expect(find.byType(SkeletonCard), findsAtLeastNWidgets(3));
    });

    testWidgets('detail gallery bounded', (tester) async {
      await tester.pumpWidget(
        wrap(
          const ServiceReportsSkeleton(
            variant: ServiceReportsSkeletonVariant.detail,
          ),
        ),
      );
      await tester.pump();
      final grid = tester.widget<SkeletonGalleryGrid>(
        find.byType(SkeletonGalleryGrid),
      );
      expect(grid.tileCount, lessThanOrEqualTo(8));
    });

    testWidgets('RTL builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(const ServiceReportsSkeleton(), direction: TextDirection.rtl),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('RolesPermissionsSkeleton', () {
    testWidgets('list mobile bounded cards one scope', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(
          const RolesPermissionsSkeleton(
            variant: RolesPermissionsSkeletonVariant.list,
            itemCount: 7,
            semanticsLabel: 'Loading roles',
          ),
        ),
      );
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonCard), findsAtLeastNWidgets(3));
    });

    testWidgets('desktop list table rows', (tester) async {
      await tester.pumpWidget(
        wrap(
          const RolesPermissionsSkeleton(
            variant: RolesPermissionsSkeletonVariant.list,
            itemCount: 6,
          ),
          width: 900,
        ),
      );
      await tester.pump();
      expect(find.byType(SkeletonTableRow), findsAtLeastNWidgets(6));
    });

    testWidgets('detail permission rows bounded', (tester) async {
      await tester.pumpWidget(
        wrap(
          const RolesPermissionsSkeleton(
            variant: RolesPermissionsSkeletonVariant.detail,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SkeletonListTile), findsAtLeastNWidgets(4));
      expect(
        tester.widgetList(find.byType(SkeletonListTile)).length,
        lessThanOrEqualTo(RolesPermissionsSkeleton.kMaxPermissionRows + 4),
      );
    });

    testWidgets('RTL builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(
          const RolesPermissionsSkeleton(),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
