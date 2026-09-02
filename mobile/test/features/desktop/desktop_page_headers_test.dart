import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_action_bar.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_page_layout.dart';

void main() {
  group('Desktop list page layout', () {
    testWidgets('renders title, action row, toolbar, and body',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const SizedBox(height: 56),
                Expanded(
                  child: AppDesktopListPage(
                    title: 'Work Orders',
                    actions: AppDesktopActionBar(
                      children: [
                        FilledButton(
                          onPressed: () {},
                          child: const Text('Create'),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                    toolbar: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search job, customer, or location',
                      ),
                    ),
                    body: const Center(child: Text('Table body')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Work Orders'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(
        find.text('Search job, customer, or location'),
        findsOneWidget,
      );
      expect(find.text('Table body'), findsOneWidget);

      final titleY = tester.getTopLeft(find.text('Work Orders')).dy;
      final createY = tester.getTopLeft(find.text('Create')).dy;
      final searchY = tester.getTopLeft(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText ==
                  'Search job, customer, or location',
        ),
      ).dy;

      expect(titleY, lessThan(createY));
      expect(createY, lessThan(searchY));
      expect(titleY, lessThan(140));
    });

    testWidgets('AppDesktopListPageHeader action row has visible size',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppDesktopListPageHeader(
                  title: 'Work Orders',
                  compactSpacing: true,
                  actions: AppDesktopActionBar(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  toolbar: const TextField(
                    decoration: InputDecoration(hintText: 'Search'),
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final refreshSize = tester.getSize(find.text('Refresh'));
      expect(refreshSize.height, greaterThan(0));
      expect(refreshSize.width, greaterThan(0));
    });

    testWidgets('renders overtime title and export action row',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDesktopListPage(
              title: 'Overtime Management',
              actions: AppDesktopActionBar(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Export Excel'),
                  ),
                ],
              ),
              toolbar: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search technician name or email',
                ),
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Overtime Management'), findsOneWidget);
      expect(find.text('Export Excel'), findsOneWidget);
    });
  });
}
