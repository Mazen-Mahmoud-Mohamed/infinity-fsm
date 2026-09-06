import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/gps_service.dart';
import 'package:mobile/core/utils/media_url.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:mobile/features/work_orders/domain/usecases/accept_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/add_after_photos_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/add_progress_note_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/add_progress_photos_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/assign_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/cancel_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/complete_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/delete_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/get_work_order_by_id_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/reject_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/remove_work_order_photo_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/save_before_work_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/start_work_order_usecase.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_detail_cubit.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_execution_panel.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_photo_gallery.dart';

class _FakeRepo extends Fake implements WorkOrderRepository {}

WorkOrderDetailCubit _harnessCubit(WorkOrder workOrder) {
  final repo = _FakeRepo();
  return WorkOrderDetailCubit(
    getById: GetWorkOrderByIdUseCase(repo),
    accept: AcceptWorkOrderUseCase(repo),
    reject: RejectWorkOrderUseCase(repo),
    start: StartWorkOrderUseCase(repo),
    complete: CompleteWorkOrderUseCase(repo),
    cancel: CancelWorkOrderUseCase(repo),
    delete: DeleteWorkOrderUseCase(repo),
    assign: AssignWorkOrderUseCase(repo),
    saveBeforeWork: SaveBeforeWorkUseCase(repo),
    addProgressNote: AddProgressNoteUseCase(repo),
    addProgressPhotos: AddProgressPhotosUseCase(repo),
    addAfterPhotos: AddAfterPhotosUseCase(repo),
    removePhoto: RemoveWorkOrderPhotoUseCase(repo),
    gpsService: GpsService(),
    addressResolverService: AddressResolverService(),
    workOrderId: workOrder.id,
  )..debugEmitState(
      WorkOrderDetailState(
        status: WorkOrderDetailStatus.success,
        workOrder: workOrder,
      ),
    );
}

WorkOrder _wo({
  List<WorkOrderAttachment> beforePhotos = const [],
  List<WorkOrderAttachment> progressPhotos = const [],
  List<WorkOrderAttachment> afterPhotos = const [],
  WorkOrderStatus status = WorkOrderStatus.inProgress,
}) {
  return WorkOrder(
    id: 'wo-photo-perf',
    companyId: 'c1',
    jobNumber: 'WO-PERF',
    jobTitle: 'Photo Perf Job',
    priority: WorkOrderPriority.medium,
    status: status,
    beforePhotos: beforePhotos,
    progressPhotos: progressPhotos,
    afterPhotos: afterPhotos,
    assignedTechnicianId: 'tech-1',
    assignedTechnicianIds: const ['tech-1'],
  );
}

WorkOrderAttachment _photo(String id) => WorkOrderAttachment(
      url: 'https://cdn.example.com/photos/$id.jpg',
      fileName: '$id.jpg',
      mimeType: 'image/jpeg',
    );

WorkOrderAttachment _cloudinaryPhoto(String id) => WorkOrderAttachment(
      url:
          'https://res.cloudinary.com/demo/image/upload/v1710000000/work-orders/c1/$id.jpg',
      fileName: '$id.jpg',
      mimeType: 'image/jpeg',
    );

Future<void> _pumpLocalized(
  WidgetTester tester, {
  required Widget home,
  Size size = const Size(390, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
      home: home,
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    WorkOrderPhotoGallery.trackBuilds = false;
    WorkOrderPhotoGallery.resetDebugBuildCount();
    AppCachedNetworkImage.debugForceDesktopImagePath = false;
  });

  group('AppCachedNetworkImage desktop decode limits', () {
    testWidgets('forwards memCacheWidth/Height as cacheWidth/Height on desktop',
        (tester) async {
      AppCachedNetworkImage.debugForceDesktopImagePath = true;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 120,
              child: AppCachedNetworkImage(
                imageUrl: 'https://cdn.example.com/full.jpg',
                memCacheWidth: 400,
                memCacheHeight: 320,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<ResizeImage>());
      final resized = image.image! as ResizeImage;
      expect(resized.width, 400);
      expect(resized.height, 320);
    });

    testWidgets('fullscreen path omits cacheWidth when memCache* unset',
        (tester) async {
      AppCachedNetworkImage.debugForceDesktopImagePath = true;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedNetworkImage(
              imageUrl: 'https://cdn.example.com/full.jpg',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<NetworkImage>());
    });
  });

  group('WorkOrderPhotoGallery Wrap layout', () {
    test('cross-axis counts preserve 600/900 breakpoints', () {
      expect(workOrderPhotoGalleryCrossAxisCount(390), 3);
      expect(workOrderPhotoGalleryCrossAxisCount(600), 4);
      expect(workOrderPhotoGalleryCrossAxisCount(899), 4);
      expect(workOrderPhotoGalleryCrossAxisCount(900), 5);
      expect(workOrderPhotoGalleryCrossAxisCount(1280), 5);
    });

    testWidgets('uses non-scrolling Wrap instead of shrinkWrap GridView',
        (tester) async {
      final photos = [_photo('a'), _photo('b'), _photo('c')];
      await _pumpLocalized(
        tester,
        size: const Size(900, 800),
        home: Scaffold(
          body: WorkOrderPhotoGallery(
            title: 'Before',
            photos: photos,
          ),
        ),
      );

      expect(find.byType(GridView), findsNothing);
      expect(find.byType(Wrap), findsOneWidget);
      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.spacing, AppSpacing.sm);
      expect(wrap.runSpacing, AppSpacing.sm);
      expect(wrap.children.length, 3);

      // Desktop ≥900 → 5 columns; tile size = (900 - 4*spacing) / 5
      final expectedTile =
          (900 - AppSpacing.sm * (5 - 1)) / 5;
      final firstTile = wrap.children.first as SizedBox;
      expect(firstTile.width, closeTo(expectedTile, 0.01));
      expect(firstTile.height, closeTo(expectedTile, 0.01));
    });

    testWidgets('preserves photo order and empty state', (tester) async {
      await _pumpLocalized(
        tester,
        home: const Scaffold(
          body: WorkOrderPhotoGallery(
            title: 'Progress',
            photos: [],
          ),
        ),
      );
      expect(find.textContaining('No photos'), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);

      await _pumpLocalized(
        tester,
        home: Scaffold(
          body: WorkOrderPhotoGallery(
            title: 'Progress',
            photos: [_photo('1'), _photo('2')],
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.children.length, 2);
    });

    testWidgets('tap opens fullscreen route', (tester) async {
      await _pumpLocalized(
        tester,
        home: Scaffold(
          body: WorkOrderPhotoGallery(
            title: 'After',
            photos: [_photo('tap')],
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(WorkOrderFullscreenImagePage), findsOneWidget);
      expect(find.text('tap.jpg'), findsOneWidget);
    });

    testWidgets('G/H: gallery loads thumb URL; fullscreen keeps original',
        (tester) async {
      AppCachedNetworkImage.debugForceDesktopImagePath = true;
      final photo = _cloudinaryPhoto('tile');
      final expectedThumb = cloudinaryGalleryThumbUrl(photo.url);
      expect(expectedThumb.contains('c_fill,w_400,h_400'), isTrue);
      expect(photo.url.contains('c_fill'), isFalse);

      await _pumpLocalized(
        tester,
        home: Scaffold(
          body: WorkOrderPhotoGallery(
            title: 'Before',
            photos: [photo],
          ),
        ),
      );

      final tileImage = tester.widget<Image>(find.byType(Image).first);
      final provider = tileImage.image!;
      final tileUrl = provider is ResizeImage
          ? (provider.imageProvider as NetworkImage).url
          : (provider as NetworkImage).url;
      expect(tileUrl, contains('c_fill,w_400,h_400'));
      expect(tileUrl, isNot(photo.url));

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WorkOrderFullscreenImagePage), findsOneWidget);
      final fullscreenImages = tester.widgetList<Image>(find.byType(Image));
      // Last Image is fullscreen (tile may still be under route).
      final fsProvider = fullscreenImages.last.image!;
      final fsUrl = fsProvider is ResizeImage
          ? (fsProvider.imageProvider as NetworkImage).url
          : (fsProvider as NetworkImage).url;
      expect(fsUrl.contains('c_fill,w_400,h_400'), isFalse);
      expect(fsUrl, contains('/upload/'));
      expect(photo.url.endsWith('tile.jpg'), isTrue);
    });

    testWidgets('I: remove callback receives original attachment URL',
        (tester) async {
      final photo = _cloudinaryPhoto('rm');
      String? removedUrl;
      final cubit = _harnessCubit(
        _wo(beforePhotos: [photo], status: WorkOrderStatus.inProgress),
      );
      addTearDown(cubit.close);

      await _pumpLocalized(
        tester,
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: WorkOrderPhotoGallery(
              title: 'Before',
              photos: [photo],
              canRemove: true,
              onRemove: (p) => removedUrl = p.url,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(removedUrl, photo.url);
      expect(removedUrl!.contains('c_fill'), isFalse);
    });

    test('J: keep/filter identity uses original URL equality', () {
      final photo = _cloudinaryPhoto('keep');
      final thumb = cloudinaryGalleryThumbUrl(photo.url);
      final keep = <String>{photo.url};
      expect(keep.contains(photo.url), isTrue);
      expect(keep.contains(thumb), isFalse);
    });
  });

  group('Work Order Detail gallery rebuild isolation', () {
    testWidgets('action/busy emit does not rebuild unchanged gallery',
        (tester) async {
      final before = [_photo('before-1')];
      final wo = _wo(beforePhotos: before);
      final cubit = _harnessCubit(wo);
      addTearDown(cubit.close);

      WorkOrderPhotoGallery.trackBuilds = true;
      WorkOrderPhotoGallery.resetDebugBuildCount();

      await _pumpLocalized(
        tester,
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: SingleChildScrollView(
              child: WorkOrderExecutionPanel(
                workOrder: wo,
                canExecute: true,
              ),
            ),
          ),
        ),
      );

      final buildsAfterMount = WorkOrderPhotoGallery.debugBuildCount;
      expect(buildsAfterMount, greaterThan(0));

      cubit.debugEmitState(
        cubit.state.copyWith(action: WorkOrderAction.beforeWork),
      );
      await tester.pump();
      cubit.debugEmitState(cubit.state.copyWith(clearAction: true));
      await tester.pump();

      expect(
        WorkOrderPhotoGallery.debugBuildCount,
        buildsAfterMount,
        reason: 'busy/action must not rebuild photo galleries',
      );
    });

    testWidgets('photo list change rebuilds the affected gallery',
        (tester) async {
      final before = [_photo('before-1')];
      final wo = _wo(beforePhotos: before);
      final cubit = _harnessCubit(wo);
      addTearDown(cubit.close);

      WorkOrderPhotoGallery.trackBuilds = true;
      WorkOrderPhotoGallery.resetDebugBuildCount();

      await _pumpLocalized(
        tester,
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: SingleChildScrollView(
              child: WorkOrderExecutionPanel(
                workOrder: wo,
                canExecute: true,
              ),
            ),
          ),
        ),
      );

      final buildsAfterMount = WorkOrderPhotoGallery.debugBuildCount;

      final updated = _wo(
        beforePhotos: [...before, _photo('before-2')],
        progressPhotos: wo.progressPhotos,
        afterPhotos: wo.afterPhotos,
      );
      cubit.debugEmitState(
        WorkOrderDetailState(
          status: WorkOrderDetailStatus.success,
          workOrder: updated,
        ),
      );
      await tester.pump();

      expect(
        WorkOrderPhotoGallery.debugBuildCount,
        greaterThan(buildsAfterMount),
      );
      expect(find.text('2'), findsWidgets);
    });
  });
}
