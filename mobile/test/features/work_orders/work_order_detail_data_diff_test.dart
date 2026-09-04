import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_split_view.dart';
import 'package:mobile/features/work_orders/data/models/work_order_model.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_detail_cubit.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_execution_panel.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_photo_gallery.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_section_card.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_timeline.dart';

/// Mimics a "legacy" WO (minimal fields) vs "newer feature" WO payloads.
Map<String, dynamic> _legacyJson() => {
      'id': 'legacy-1',
      'companyId': 'c1',
      'jobNumber': 'WO-OLD',
      'jobTitle': 'Legacy Job',
      'priority': 'MEDIUM',
      'status': 'ASSIGNED',
      'customerName': 'Old Customer',
      'locationLabel': 'Site A',
      'scheduledAt': '2026-01-01T10:00:00.000Z',
      'timeline': [
        {
          'type': 'CREATED',
          'at': '2026-01-01T09:00:00.000Z',
          'userName': 'Admin',
        },
      ],
      'createdAt': '2026-01-01T09:00:00.000Z',
      'updatedAt': '2026-01-01T09:00:00.000Z',
    };

Map<String, dynamic> _newerJson({
  required String id,
  required String jobNumber,
  bool withVoice = true,
  bool withPhones = true,
  bool withAttachments = true,
  bool duplicateAttachmentUrls = false,
  bool emptyAttachmentUrls = false,
  bool withLocations = true,
  String status = 'IN_PROGRESS',
}) {
  final url = 'https://res.cloudinary.com/demo/image/upload/sample.jpg';
  final attachments = <Map<String, dynamic>>[];
  if (withAttachments) {
    if (emptyAttachmentUrls) {
      attachments.addAll([
        {'url': null, 'fileName': 'a.jpg', 'mimeType': 'image/jpeg'},
        {'fileName': 'b.jpg', 'mimeType': 'image/jpeg'},
      ]);
    } else if (duplicateAttachmentUrls) {
      attachments.addAll([
        {'url': url, 'fileName': 'a.jpg', 'mimeType': 'image/jpeg'},
        {'url': url, 'fileName': 'b.jpg', 'mimeType': 'image/jpeg'},
      ]);
    } else {
      attachments.add({
        'url': url,
        'fileName': 'a.jpg',
        'mimeType': 'image/jpeg',
      });
    }
  }

  return {
    'id': id,
    'companyId': 'c1',
    'jobNumber': jobNumber,
    'jobTitle': 'Newer Job $jobNumber',
    'priority': 'HIGH',
    'status': status,
    'customerName': 'New Customer',
    'customerPhoneNumbers': withPhones ? ['+966500000001', '+966500000002'] : [],
    'customerAddress': {
      'street': 'King Fahd Rd',
      'city': 'Riyadh',
      'governorate': 'Riyadh',
      'lat': 24.7136,
      'lng': 46.6753,
    },
    'locationLabel': 'Riyadh HQ',
    'locationUrl': 'https://maps.app.goo.gl/example',
    'description': 'New feature work order',
    'notes': 'Internal',
    if (withVoice)
      'voiceNote': {
        'url': 'https://res.cloudinary.com/demo/video/upload/voice.m4a',
        'duration': 12.5,
        'format': 'm4a',
        'uploadedAt': '2026-09-04T08:00:00.000Z',
      },
    'attachments': attachments,
    'beforePhotos': attachments,
    'progressPhotos': const [],
    'afterPhotos': const [],
    'beforeNotes': 'Checked in',
    'progressNotes': [
      {
        'id': 'n1',
        'text': 'Progress update',
        'createdAt': '2026-09-04T09:00:00.000Z',
        'createdByName': 'Tech',
      },
    ],
    if (withLocations)
      'startedLocation': {
        'latitude': 24.71,
        'longitude': 46.67,
        'accuracy': 5,
        'address': 'Gate 1',
        'recordedAt': '2026-09-04T08:30:00.000Z',
      },
    'timeline': [
      {
        'type': 'CREATED',
        'at': '2026-09-03T10:00:00.000Z',
        'userName': 'Admin',
      },
      {
        'type': 'ASSIGNED',
        'at': '2026-09-03T11:00:00.000Z',
        'userName': 'Supervisor',
      },
      {
        'type': 'STARTED',
        'at': '2026-09-04T08:30:00.000Z',
        'userName': 'Tech',
      },
    ],
    'createdAt': '2026-09-03T10:00:00.000Z',
    'updatedAt': '2026-09-04T09:00:00.000Z',
  };
}

Future<List<Object>> _pumpDesktop(
  WidgetTester tester,
  WorkOrder wo,
) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final exceptions = <Object>[];
  final old = FlutterError.onError;
  FlutterError.onError = (d) {
    exceptions.add(d.exception);
    old?.call(d);
  };
  addTearDown(() => FlutterError.onError = old);

  final state = WorkOrderDetailState(
    status: WorkOrderDetailStatus.success,
    workOrder: wo,
  );

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
      home: Scaffold(
        appBar: AppBar(title: const Text('Work order details')),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  AppDesktopSplitView(
                    startFlex: 13,
                    endFlex: 7,
                    start: Column(
                      children: [
                        Text(wo.jobTitle),
                        WorkOrderExecutionPanel(
                          workOrder: wo,
                          state: state,
                          canExecute: false,
                          showAdminDetails: true,
                          column: WorkOrderExecutionColumn.main,
                        ),
                      ],
                    ),
                    end: Column(
                      children: [
                        WorkOrderExecutionPanel(
                          workOrder: wo,
                          state: state,
                          canExecute: false,
                          showAdminDetails: true,
                          column: WorkOrderExecutionColumn.sidebar,
                        ),
                        WorkOrderSectionCard(
                          icon: Icons.timeline,
                          title: 'Timeline',
                          initiallyExpanded: true,
                          child: WorkOrderTimelineSection(events: wo.timeline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48, child: Text('FOOTER')),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  return exceptions;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parser accepts legacy and newer payloads', () {
    final legacy = WorkOrderModel.fromJson(_legacyJson());
    final newer = WorkOrderModel.fromJson(
      _newerJson(id: 'new-1', jobNumber: 'WO-NEW-1'),
    );
    expect(legacy.voiceNote, isNull);
    expect(legacy.customerPhoneNumbers, isEmpty);
    expect(legacy.attachments, isEmpty);
    expect(newer.voiceNote?.url, contains('cloudinary'));
    expect(newer.customerPhoneNumbers, hasLength(2));
    expect(newer.attachments, isNotEmpty);
    expect(newer.startedLocation, isNotNull);
  });

  test('parser tolerates null/missing attachment urls', () {
    final wo = WorkOrderModel.fromJson(
      _newerJson(
        id: 'new-empty-url',
        jobNumber: 'WO-EMPTY',
        emptyAttachmentUrls: true,
      ),
    );
    expect(wo.attachments, hasLength(2));
    expect(wo.attachments.every((a) => a.url.isEmpty), isTrue);
  });

  testWidgets('legacy minimal WO renders desktop body', (tester) async {
    final wo = WorkOrderModel.fromJson(_legacyJson());
    final exceptions = await _pumpDesktop(tester, wo);
    expect(find.text('Legacy Job'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(exceptions, isEmpty, reason: '$exceptions');
  });

  testWidgets('newer WO with voice/phones/locations/attachments renders', (
    tester,
  ) async {
    final wo = WorkOrderModel.fromJson(
      _newerJson(id: 'new-1', jobNumber: 'WO-NEW-1'),
    );
    final exceptions = await _pumpDesktop(tester, wo);
    debugPrint('newer exceptions: $exceptions');
    expect(find.textContaining('Newer Job'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(exceptions, isEmpty, reason: '$exceptions');
  });

  testWidgets('duplicate attachment URLs no longer blank the body', (
    tester,
  ) async {
    final wo = WorkOrderModel.fromJson(
      _newerJson(
        id: 'new-dup',
        jobNumber: 'WO-DUP',
        duplicateAttachmentUrls: true,
        status: 'ASSIGNED',
        withVoice: false,
        withLocations: false,
      ),
    );
    final exceptions = await _pumpDesktop(tester, wo);
    expect(find.textContaining('Newer Job'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(exceptions, isEmpty, reason: '$exceptions');
  });

  testWidgets('empty attachment URLs no longer blank the body', (tester) async {
    final wo = WorkOrderModel.fromJson(
      _newerJson(
        id: 'new-empty',
        jobNumber: 'WO-EMPTY',
        emptyAttachmentUrls: true,
        status: 'ASSIGNED',
        withVoice: false,
        withLocations: false,
      ),
    );
    final exceptions = await _pumpDesktop(tester, wo);
    expect(find.textContaining('Newer Job'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(exceptions, isEmpty, reason: '$exceptions');
  });

  testWidgets('photo gallery allows duplicate urls with indexed hero tags', (
    tester,
  ) async {
    final exceptions = <Object>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      exceptions.add(d.exception);
      old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);

    const url = 'https://res.cloudinary.com/demo/image/upload/sample.jpg';
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WorkOrderPhotoGallery(
            title: 'Dup',
            heroPrefix: 'wo-attach-side',
            photos: const [
              WorkOrderAttachment(url: url, mimeType: 'image/jpeg'),
              WorkOrderAttachment(url: url, mimeType: 'image/jpeg'),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(exceptions, isEmpty, reason: '$exceptions');
  });
}
