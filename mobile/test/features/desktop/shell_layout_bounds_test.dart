import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_action_bar.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_constants.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_page_header.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_page_layout.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_shell_body.dart';

/// Mirrors [MainNavigationShell] desktop constraint chain without routing.
Widget _desktopShellReplica({required Widget branchContent}) {
  return MaterialApp(
    home: Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: AppDesktopConstants.sidebarCollapsedWidth,
            child: const ColoredBox(color: Color(0xFF111111)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: AppDesktopConstants.topBarHeight,
                  child: const ColoredBox(color: Color(0xFF222222)),
                ),
                Expanded(
                  child: AppDesktopShellBody(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox.shrink(),
                        Expanded(child: branchContent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('Desktop shell layout bounds', () {
    testWidgets('shell replica keeps action buttons on-screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _desktopShellReplica(
          branchContent: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDesktopListPageHeader(
                title: 'Work Orders',
                compactSpacing: true,
                actions: AppDesktopActionBar(
                  children: [
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Order'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                toolbar: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search job, customer, or location',
                  ),
                ),
              ),
              const Expanded(child: ColoredBox(color: Color(0xFF333333))),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleY = tester.getTopLeft(find.text('Work Orders')).dy;
      final createY = tester.getTopLeft(find.text('Create Order')).dy;
      final refreshY = tester.getTopLeft(find.text('Refresh')).dy;
      final searchY = tester.getTopLeft(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == 'Search job, customer, or location',
        ),
      ).dy;

      expect(titleY, greaterThan(0));
      expect(createY, greaterThan(0));
      expect(refreshY, greaterThan(0));
      expect(searchY, greaterThan(0));
      expect(titleY, lessThan(createY));
      expect(createY, lessThan(searchY));

      final refreshSize = tester.getSize(find.text('Refresh'));
      expect(refreshSize.height, greaterThan(0));
      expect(refreshSize.width, greaterThan(0));
    });

    testWidgets('reports global bounds for shell layers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final shellBodyKey = GlobalKey();
      final branchKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(width: AppDesktopConstants.sidebarCollapsedWidth),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: AppDesktopConstants.topBarHeight),
                      Expanded(
                        child: AppDesktopShellBody(
                          key: shellBodyKey,
                          child: Column(
                            children: [
                              Expanded(
                                child: ColoredBox(
                                  key: branchKey,
                                  color: Colors.blue,
                                  child: AppDesktopPageHeader(
                                    title: 'Work Orders',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shellBox = tester.renderObject<RenderBox>(
        find.byKey(shellBodyKey),
      );
      final branchBox = tester.renderObject<RenderBox>(
        find.byKey(branchKey),
      );
      final titleBox = tester.renderObject<RenderBox>(
        find.text('Work Orders'),
      );

      final shellGlobal = shellBox.localToGlobal(Offset.zero);
      final branchGlobal = branchBox.localToGlobal(Offset.zero);
      final titleGlobal = titleBox.localToGlobal(Offset.zero);

      expect(shellGlobal.dy, greaterThanOrEqualTo(0));
      expect(branchGlobal.dy, greaterThanOrEqualTo(0));
      expect(titleGlobal.dy, greaterThanOrEqualTo(0));
      expect(titleGlobal.dy, greaterThanOrEqualTo(branchGlobal.dy));
    });
  });
}
