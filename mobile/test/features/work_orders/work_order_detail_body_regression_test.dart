import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_split_view.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_voice_note_section.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_detail_cubit.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_execution_panel.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_section_card.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_timeline.dart';

WorkOrder _wo({
  WorkOrderVoiceNote? voice,
  List<WorkOrderTimelineEvent> timeline = const [],
  List<WorkOrderAttachment> attachments = const [],
}) {
  return WorkOrder(
    id: 'wo-detail-1',
    companyId: 'c1',
    jobNumber: 'WO-1001',
    jobTitle: 'Pump Inspection',
    priority: WorkOrderPriority.medium,
    status: WorkOrderStatus.inProgress,
    customerName: 'Acme Plant',
    locationLabel: 'Riyadh Site A',
    locationUrl: 'https://maps.app.goo.gl/example',
    notes: 'Bring spare gasket',
    description: 'Inspect pump and report',
    scheduledAt: DateTime(2026, 9, 4, 10),
    voiceNote: voice,
    timeline: timeline,
    attachments: attachments,
  );
}

WorkOrderDetailState _state(WorkOrder wo) => WorkOrderDetailState(
      status: WorkOrderDetailStatus.success,
      workOrder: wo,
    );

Future<List<Object>> _pumpDesktopDetailBody(
  WidgetTester tester, {
  required WorkOrder workOrder,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final exceptions = <Object>[];
  final oldOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    exceptions.add(details.exception);
    oldOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = oldOnError);

  final state = _state(workOrder);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            appBar: AppBar(title: Text(l10n.workOrderDetails)),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppDesktopSplitView(
                        startFlex: 13,
                        endFlex: 7,
                        start: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(workOrder.jobTitle),
                            const SizedBox(height: 12),
                            WorkOrderExecutionPanel(
                              workOrder: workOrder,
                              state: state,
                              canExecute: false,
                              showAdminDetails: true,
                              column: WorkOrderExecutionColumn.main,
                            ),
                          ],
                        ),
                        end: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            WorkOrderExecutionPanel(
                              workOrder: workOrder,
                              state: state,
                              canExecute: false,
                              showAdminDetails: true,
                              column: WorkOrderExecutionColumn.sidebar,
                            ),
                            const SizedBox(height: 8),
                            WorkOrderSectionCard(
                              icon: Icons.timeline,
                              title: l10n.workOrderTimeline,
                              subtitle: l10n.workOrderTimelineSubtitle,
                              initiallyExpanded: true,
                              child: WorkOrderTimelineSection(
                                events: workOrder.timeline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: const Text('FOOTER'),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  expect(
    exceptions,
    isEmpty,
    reason: 'Unexpected FlutterError(s): $exceptions',
  );
  expect(tester.takeException(), isNull);
  return exceptions;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WO details main body renders without voice note', (tester) async {
    await _pumpDesktopDetailBody(tester, workOrder: _wo());
    expect(find.text('Pump Inspection'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('FOOTER'), findsOneWidget);
  });

  testWidgets('WO details main body renders with valid voice note', (
    tester,
  ) async {
    await _pumpDesktopDetailBody(
      tester,
      workOrder: _wo(
        voice: const WorkOrderVoiceNote(
          url: 'https://res.cloudinary.com/demo/video/upload/voice.m4a',
          duration: 12,
        ),
        timeline: [
          WorkOrderTimelineEvent(
            type: WorkOrderTimelineType.created,
            at: DateTime(2026, 9, 1, 9),
            userName: 'Admin',
          ),
          WorkOrderTimelineEvent(
            type: WorkOrderTimelineType.started,
            at: DateTime(2026, 9, 4, 10),
            userName: 'Tech',
          ),
        ],
      ),
    );
    expect(find.text('Pump Inspection'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.byType(OvertimeVoiceNoteSection), findsOneWidget);
    expect(find.text('Voice Note'), findsWidgets);
    expect(find.text('FOOTER'), findsOneWidget);
  });

  testWidgets('WO details main body renders with invalid voice URL', (
    tester,
  ) async {
    await _pumpDesktopDetailBody(
      tester,
      workOrder: _wo(
        voice: const WorkOrderVoiceNote(
          url: 'not-a-valid-url',
          duration: 3,
        ),
      ),
    );
    expect(find.text('Pump Inspection'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    // v1.0.10 mounts the voice section whenever a URL string is present; the
    // shared voice widget must keep the parent page visible.
    expect(find.byType(OvertimeVoiceNoteSection), findsOneWidget);
    expect(find.text('FOOTER'), findsOneWidget);
  });

  testWidgets('WO details desktop split survives dense timeline + media', (
    tester,
  ) async {
    const photo = WorkOrderAttachment(
      url: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
      mimeType: 'image/jpeg',
      fileName: 'sample.jpg',
    );
    final exceptions = await _pumpDesktopDetailBody(
      tester,
      workOrder: _wo(
        voice: const WorkOrderVoiceNote(
          url: 'https://example.com/voice.m4a',
          duration: 9,
        ),
        attachments: [photo],
        timeline: List.generate(
          8,
          (i) => WorkOrderTimelineEvent(
            type: WorkOrderTimelineType
                .values[i % WorkOrderTimelineType.values.length],
            at: DateTime(2026, 9, 1).add(Duration(hours: i)),
            userName: 'User $i',
            note: 'Checkpoint note $i',
          ),
        ),
      ),
    );
    expect(exceptions, isEmpty);
    expect(find.text('Pump Inspection'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('FOOTER'), findsOneWidget);
  });
}
