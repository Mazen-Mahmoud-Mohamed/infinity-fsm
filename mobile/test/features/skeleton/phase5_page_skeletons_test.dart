import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';
import 'package:mobile/features/global_search/presentation/widgets/global_search_results_skeleton.dart';
import 'package:mobile/features/organization/presentation/widgets/profile_skeleton.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_detail_skeleton.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_list_skeleton.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_form_skeleton.dart';

void main() {
  tearDown(SkeletonScope.resetDebugActiveControllerCount);

  Widget wrap(
    Widget child, {
    double width = 400,
    TextDirection direction = TextDirection.ltr,
    bool disableAnimations = false,
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
            size: Size(width, 1400),
            disableAnimations: disableAnimations,
          ),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('ProfileSkeleton', () {
    testWidgets('one scope, no images, mobile', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(const ProfileSkeleton(semanticsLabel: 'Loading profile...')),
      );
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(AppCachedNetworkImage), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.bySemanticsLabel('Loading profile...'), findsOneWidget);
    });

    testWidgets('desktop and RTL without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(const ProfileSkeleton(), width: 900, direction: TextDirection.rtl),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion uses no controller', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(const ProfileSkeleton(), disableAnimations: true),
      );
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 0);
    });

    test('clamps permission rows', () {
      expect(20.clamp(1, ProfileSkeleton.kMaxPermissionRows), 6);
    });
  });

  group('SettingsFormSkeleton', () {
    testWidgets('one scope and bounded fields', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(const SettingsFormSkeleton(semanticsLabel: 'Loading settings...')),
      );
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(4));
    });

    testWidgets('RTL builds', (tester) async {
      await tester.pumpWidget(
        wrap(const SettingsFormSkeleton(), direction: TextDirection.rtl),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('GlobalSearchResultsSkeleton', () {
    testWidgets('bounded rows one scope', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(const GlobalSearchResultsSkeleton(itemCount: 7)),
      );
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonListTile), findsAtLeastNWidgets(5));
      expect(find.byType(SkeletonListTile), findsNWidgets(7));
    });

    testWidgets('desktop and RTL', (tester) async {
      await tester.pumpWidget(
        wrap(
          const GlobalSearchResultsSkeleton(),
          width: 900,
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('clamps to max 7', () {
      expect(20.clamp(1, GlobalSearchResultsSkeleton.kMaxItems), 7);
    });
  });

  group('OvertimeListSkeleton', () {
    testWidgets('mobile cards one scope', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(wrap(const OvertimeListSkeleton(itemCount: 7)));
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonListTile), findsAtLeastNWidgets(5));
    });

    testWidgets('desktop table rows', (tester) async {
      await tester.pumpWidget(
        wrap(const OvertimeListSkeleton(itemCount: 6), width: 900),
      );
      await tester.pump();
      expect(find.byType(SkeletonTableRow), findsAtLeastNWidgets(6));
    });

    testWidgets('RTL builds', (tester) async {
      await tester.pumpWidget(
        wrap(const OvertimeListSkeleton(), direction: TextDirection.rtl),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('OvertimeDetailSkeleton', () {
    testWidgets('mobile one scope matching detail sections', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(
          const OvertimeDetailSkeleton(semanticsLabel: 'Loading details...'),
        ),
      );
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonPanel), findsAtLeastNWidgets(3));
      expect(find.byType(SkeletonChip), findsOneWidget);
      expect(find.byType(SkeletonCircle), findsNWidgets(4));
      expect(find.byType(AppCachedNetworkImage), findsNothing);
      expect(find.bySemanticsLabel('Loading details...'), findsOneWidget);
    });

    testWidgets('desktop split and overview without overflow', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(const OvertimeDetailSkeleton(), width: 1100),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(SkeletonScope.debugActiveControllerCount, 1);
      expect(find.byType(SkeletonPanel), findsAtLeastNWidgets(4));
    });

    testWidgets('tablet and RTL without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(
          const OvertimeDetailSkeleton(),
          width: 720,
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion uses no controller', (tester) async {
      SkeletonScope.resetDebugActiveControllerCount();
      await tester.pumpWidget(
        wrap(const OvertimeDetailSkeleton(), disableAnimations: true),
      );
      await tester.pump();
      expect(SkeletonScope.debugActiveControllerCount, 0);
    });
  });
}
