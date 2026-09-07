import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';

void main() {
  tearDown(SkeletonScope.resetDebugActiveControllerCount);

  Widget wrap(
    Widget child, {
    ThemeData? theme,
    MediaQueryData? mediaQuery,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      theme: theme ?? ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: MediaQuery(
        data: mediaQuery ?? const MediaQueryData(size: Size(400, 800)),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('primitives render under SkeletonScope', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SkeletonScope(
          child: Column(
            children: [
              SkeletonBox(width: 40, height: 12),
              SkeletonText(lines: 2),
              SkeletonCircle(size: 24),
              SkeletonChip(),
              SkeletonCard(child: SkeletonBox(height: 20)),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.byType(SkeletonText), findsOneWidget);
    expect(find.byType(SkeletonCircle), findsOneWidget);
    expect(find.byType(SkeletonChip), findsOneWidget);
    expect(find.byType(SkeletonCard), findsOneWidget);
  });

  testWidgets('light theme bones use ColorScheme surfaces', (tester) async {
    Color? base;
    Color? highlight;
    await tester.pumpWidget(
      wrap(
        SkeletonScope(
          child: Builder(
            builder: (context) {
              final scope = SkeletonAnimation.of(context);
              base = scope.baseColor;
              highlight = scope.highlightColor;
              return const SkeletonBox(width: 20, height: 20);
            },
          ),
        ),
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
      ),
    );

    expect(base, isNotNull);
    expect(highlight, isNotNull);
    expect(base, isNot(equals(highlight)));
  });

  testWidgets('dark theme bones use ColorScheme surfaces', (tester) async {
    Color? painted;
    await tester.pumpWidget(
      wrap(
        SkeletonScope(
          child: Builder(
            builder: (context) {
              painted = SkeletonAnimation.of(context).baseColor;
              return const SkeletonBox(width: 20, height: 20);
            },
          ),
        ),
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          ),
        ),
        mediaQuery: const MediaQueryData(
          size: Size(400, 800),
          platformBrightness: Brightness.dark,
        ),
      ),
    );

    expect(painted, isNotNull);
  });

  testWidgets('reduced motion uses static bones (no animation)', (tester) async {
    SkeletonScope.resetDebugActiveControllerCount();
    await tester.pumpWidget(
      wrap(
        const SkeletonScope(
          child: SkeletonBox(width: 40, height: 12),
        ),
        mediaQuery: const MediaQueryData(
          size: Size(400, 800),
          disableAnimations: true,
        ),
      ),
    );
    await tester.pump();

    expect(SkeletonScope.debugActiveControllerCount, 0);
    final scope = tester.widget<SkeletonScope>(find.byType(SkeletonScope));
    expect(scope, isNotNull);

    final anim = tester
        .element(find.byType(SkeletonBox))
        .dependOnInheritedWidgetOfExactType<SkeletonAnimation>();
    expect(anim?.animation, isNull);
  });

  testWidgets('SkeletonScope uses one controller for many bones', (tester) async {
    SkeletonScope.resetDebugActiveControllerCount();
    await tester.pumpWidget(
      wrap(
        SkeletonScope(
          child: Column(
            children: [
              for (var i = 0; i < 12; i++)
                const SkeletonBox(width: 80, height: 10),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(SkeletonScope.debugActiveControllerCount, 1);
    expect(find.byType(SkeletonBox), findsNWidgets(12));
  });

  testWidgets('nested scopes each own one controller', (tester) async {
    SkeletonScope.resetDebugActiveControllerCount();
    await tester.pumpWidget(
      wrap(
        const Column(
          children: [
            SkeletonScope(child: SkeletonBox(width: 10, height: 10)),
            SkeletonScope(child: SkeletonBox(width: 10, height: 10)),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(SkeletonScope.debugActiveControllerCount, 2);
  });
}
