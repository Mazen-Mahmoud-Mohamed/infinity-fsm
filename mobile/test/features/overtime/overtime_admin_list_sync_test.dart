import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/geo/gps_snapshot.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/usecases/approve_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_overtime_by_id_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/list_admin_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/reject_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_admin_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_detail_cubit.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_admin_desktop_table.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_list_skeleton.dart';

GpsSnapshot _gps() => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 5,
      recordedAt: DateTime.utc(2026, 8, 12, 8),
      provider: 'gps',
    );

OvertimeSession _session(
  String id, {
  OvertimeStatus status = OvertimeStatus.pendingReview,
  double? approvedHours,
  String? rejectionReason,
}) {
  final start = DateTime.utc(2026, 8, 12, 8);
  return OvertimeSession(
    id: id,
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: status,
    startAt: start,
    startGps: _gps(),
    startDeviceId: 'd1',
    eligibleOvertimeMinutes: 180,
    approvedHours: approvedHours,
    rejectionReason: rejectionReason,
  );
}

class _PagingRepo extends Fake implements OvertimeRepository {
  _PagingRepo(this.pages);

  final Map<int, List<OvertimeSession>> pages;
  final calls = <({int page, OvertimeStatus? status})>[];
  Duration delay = Duration.zero;
  List<OvertimeSession>? nextItems;
  bool useHolds = false;
  final holds = <Completer<void>>[];
  final itemsByCall = <int, List<OvertimeSession>>{};

  @override
  Future<Result<OvertimeSessionPage>> listAdminSessions({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
    String? search,
  }) async {
    final callIndex = calls.length;
    calls.add((page: page, status: status));
    if (useHolds) {
      final hold = Completer<void>();
      holds.add(hold);
      await hold.future;
    } else if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final items = itemsByCall[callIndex] ??
        nextItems ??
        pages[page] ??
        const <OvertimeSession>[];
    final maxPage = pages.keys.fold<int>(0, (a, b) => a > b ? a : b);
    return Success(
      OvertimeSessionPage(
        items: items,
        page: page,
        limit: limit,
        total: pages.values.fold<int>(0, (sum, list) => sum + list.length),
        totalPages: maxPage,
      ),
    );
  }
}

class _NoopRepo extends Fake implements OvertimeRepository {}

class _FakeGetById extends GetOvertimeByIdUseCase {
  _FakeGetById(this.session) : super(_NoopRepo());
  OvertimeSession session;

  @override
  Future<Result<OvertimeSession>> call(String id) async => Success(session);
}

class _FakeApprove extends ApproveOvertimeUseCase {
  _FakeApprove() : super(_NoopRepo());
  Result<OvertimeSession> result =
      Success(_session('ot-1', status: OvertimeStatus.approved));
  var calls = 0;

  @override
  Future<Result<OvertimeSession>> call(
    String id, {
    String? reviewNotes,
    double? approvedHours,
  }) async {
    calls++;
    return result;
  }
}

class _FakeReject extends RejectOvertimeUseCase {
  _FakeReject() : super(_NoopRepo());
  Result<OvertimeSession> result =
      Success(_session('ot-1', status: OvertimeStatus.rejected));

  @override
  Future<Result<OvertimeSession>> call(
    String id, {
    String? rejectionReason,
    String? reviewNotes,
  }) async {
    return result;
  }
}

({OvertimeAdminCubit cubit, _PagingRepo repo, SessionQueryCache cache})
    _admin({
  Map<int, List<OvertimeSession>>? pages,
}) {
  final repo = _PagingRepo(
    pages ??
        {
          1: [_session('ot-1'), _session('ot-2'), _session('ot-3')],
          2: [_session('ot-4')],
        },
  );
  final cache = SessionQueryCache();
  final cubit = OvertimeAdminCubit(
    listAdmin: ListAdminOvertimeUseCase(repo),
    sessionQueryCache: cache,
  );
  return (cubit: cubit, repo: repo, cache: cache);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('accept success updates the existing list item in place', () async {
    final setup = _admin();
    await setup.cubit.loadFirstPage();
    final beforeCalls = setup.repo.calls.length;
    setup.cubit.applyUpdated(
      _session('ot-2', status: OvertimeStatus.approved),
    );

    expect(setup.cubit.state.items.map((e) => e.id), ['ot-1', 'ot-2', 'ot-3']);
    expect(setup.cubit.state.items[1].status, OvertimeStatus.approved);
    expect(setup.cubit.state.items[0].status, OvertimeStatus.pendingReview);
    expect(setup.cubit.state.items[2].status, OvertimeStatus.pendingReview);
    expect(setup.cubit.state.page, 1);
    expect(setup.cubit.state.hasMore, isTrue);
    expect(setup.cubit.state.status, OvertimeAdminStatus.success);
    expect(setup.cubit.state.isRefreshing, isFalse);
    expect(setup.repo.calls.length, beforeCalls);
    await setup.cubit.close();
  });

  test('partial accept success updates approved hours on the list item',
      () async {
    final setup = _admin();
    await setup.cubit.loadFirstPage();
    setup.cubit.applyUpdated(
      _session(
        'ot-1',
        status: OvertimeStatus.approved,
        approvedHours: 2.5,
      ),
    );

    expect(setup.cubit.state.items.first.status, OvertimeStatus.approved);
    expect(setup.cubit.state.items.first.approvedHours, 2.5);
    expect(setup.cubit.state.items.first.effectiveApprovedHours, 2.5);
    await setup.cubit.close();
  });

  test('reject success updates the existing list item in place', () async {
    final setup = _admin();
    await setup.cubit.loadFirstPage();
    setup.cubit.applyUpdated(
      _session(
        'ot-3',
        status: OvertimeStatus.rejected,
        rejectionReason: 'no',
      ),
    );

    expect(setup.cubit.state.items[2].status, OvertimeStatus.rejected);
    expect(setup.cubit.state.items[2].rejectionReason, 'no');
    expect(setup.cubit.state.items[0].status, OvertimeStatus.pendingReview);
    await setup.cubit.close();
  });

  test('unknown id is not inserted into the loaded list', () async {
    final setup = _admin();
    await setup.cubit.loadFirstPage();
    setup.cubit.applyUpdated(
      _session('missing', status: OvertimeStatus.approved),
    );
    expect(setup.cubit.state.items.map((e) => e.id), ['ot-1', 'ot-2', 'ot-3']);
    await setup.cubit.close();
  });

  test('stale in-flight refresh cannot overwrite a newer mutation', () async {
    final setup = _admin();
    await setup.cubit.loadFirstPage();
    setup.repo.delay = const Duration(milliseconds: 40);
    setup.repo.nextItems = [
      _session('ot-1'),
      _session('ot-2'),
      _session('ot-3'),
    ];
    final refresh = setup.cubit.loadFirstPage();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    setup.cubit.applyUpdated(
      _session('ot-1', status: OvertimeStatus.approved, approvedHours: 1),
    );
    await refresh;
    expect(setup.cubit.state.items.first.status, OvertimeStatus.approved);
    expect(setup.cubit.state.items.first.approvedHours, 1);
    await setup.cubit.close();
  });

  test('pull-to-refresh still reloads page 1', () async {
    final setup = _admin();
    await setup.cubit.loadFirstPage();
    setup.cubit.applyUpdated(
      _session('ot-1', status: OvertimeStatus.approved),
    );
    setup.repo.nextItems = [
      _session('ot-1', status: OvertimeStatus.approved),
      _session('ot-2'),
      _session('ot-3'),
    ];
    await setup.cubit.loadFirstPage();
    expect(setup.repo.calls.map((c) => c.page), [1, 1]);
    expect(setup.cubit.state.items.first.status, OvertimeStatus.approved);
    await setup.cubit.close();
  });

  test('load-more still appends', () async {
    final setup = _admin();
    await setup.cubit.loadFirstPage();
    await setup.cubit.loadMore();
    expect(setup.repo.calls.map((c) => c.page), [1, 2]);
    expect(setup.cubit.state.items.map((e) => e.id),
        ['ot-1', 'ot-2', 'ot-3', 'ot-4']);
    await setup.cubit.close();
  });

  test('detail accept/partial/reject sync the shared admin list without reload',
      () async {
    final setup = _admin();
    await setup.cubit.loadFirstPage();
    final listCalls = setup.repo.calls.length;
    final approve = _FakeApprove();
    final reject = _FakeReject();
    final detail = OvertimeDetailCubit(
      getById: _FakeGetById(_session('ot-1')),
      approve: approve,
      reject: reject,
      sessionId: 'ot-1',
      adminList: setup.cubit,
      sessionQueryCache: setup.cache,
    );
    await detail.load();

    approve.result = Success(
      _session('ot-1', status: OvertimeStatus.approved),
    );
    await detail.approve();
    expect(setup.cubit.state.items.first.status, OvertimeStatus.approved);

    approve.result = Success(
      _session('ot-1', status: OvertimeStatus.approved, approvedHours: 1.25),
    );
    await detail.approvePartial(approvedHours: 1.25);
    expect(setup.cubit.state.items.first.approvedHours, 1.25);

    reject.result = Success(
      _session('ot-1', status: OvertimeStatus.rejected, rejectionReason: 'x'),
    );
    await detail.reject(rejectionReason: 'x');
    expect(setup.cubit.state.items.first.status, OvertimeStatus.rejected);
    expect(setup.repo.calls.length, listCalls);

    await detail.close();
    await setup.cubit.close();
  });

  test('mutation failure leaves the list item unchanged and retry can succeed',
      () async {
    final setup = _admin();
    await setup.cubit.loadFirstPage();
    final approve = _FakeApprove()
      ..result = const Failure('denied', code: 'HTTP_400');
    final detail = OvertimeDetailCubit(
      getById: _FakeGetById(_session('ot-1')),
      approve: approve,
      reject: _FakeReject(),
      sessionId: 'ot-1',
      adminList: setup.cubit,
    );
    await detail.load();
    await detail.approve();
    expect(setup.cubit.state.items.first.status, OvertimeStatus.pendingReview);
    expect(detail.state.isError, isTrue);

    approve.result = Success(
      _session('ot-1', status: OvertimeStatus.approved),
    );
    await detail.approve();
    expect(setup.cubit.state.items.first.status, OvertimeStatus.approved);

    await detail.close();
    await setup.cubit.close();
  });

  testWidgets('mobile list reflects mutation without a skeleton or reload',
      (tester) async {
    final setup = _admin();
    await setup.cubit.loadFirstPage();
    final listCalls = setup.repo.calls.length;
    setup.cubit.applyUpdated(
      _session('ot-1', status: OvertimeStatus.approved, approvedHours: 3),
    );
    expect(setup.cubit.state.items.first.status, OvertimeStatus.approved);

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
        home: BlocProvider.value(
          value: setup.cubit,
          child: Scaffold(
            body: BlocBuilder<OvertimeAdminCubit, OvertimeAdminState>(
              builder: (context, state) {
                return Column(
                  children: [
                    for (final session in state.items)
                      Text('${session.id}:${session.status.name}'),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ot-1:approved'), findsOneWidget);
    expect(find.text('ot-2:pendingReview'), findsOneWidget);
    expect(find.byType(OvertimeListSkeleton), findsNothing);
    expect(setup.repo.calls.length, listCalls);

    await setup.cubit.close();
  });

  testWidgets('desktop table consumes the same updated cubit state',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = _admin();
    await setup.cubit.loadFirstPage();
    setup.cubit.applyUpdated(
      _session('ot-2', status: OvertimeStatus.rejected, rejectionReason: 'no'),
    );

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
        home: BlocProvider.value(
          value: setup.cubit,
          child: Scaffold(
            body: BlocBuilder<OvertimeAdminCubit, OvertimeAdminState>(
              builder: (context, state) {
                return OvertimeAdminDesktopTable(
                  sessions: state.items,
                  dateFormat: DateFormat('yyyy-MM-dd HH:mm'),
                  scrollController: ScrollController(),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Pending review'), findsNWidgets(2));
    await setup.cubit.close();
  });

  test(
    'cache-only remount shows reviewed item without a mutation list reload',
    () async {
      final setup = _admin();
      await setup.cubit.loadFirstPage();
      final listCallsAfterSeed = setup.repo.calls.length;
      await setup.cubit.close();

      final approve = _FakeApprove()
        ..result = Success(
          _session(
            'ot-2',
            status: OvertimeStatus.approved,
            approvedHours: 1.5,
          ),
        );
      final detail = OvertimeDetailCubit(
        getById: _FakeGetById(_session('ot-2')),
        approve: approve,
        reject: _FakeReject(),
        sessionId: 'ot-2',
        sessionQueryCache: setup.cache,
      );
      await detail.load();
      await detail.approve();
      expect(setup.repo.calls.length, listCallsAfterSeed);
      await detail.close();

      setup.repo.nextItems = [
        _session('ot-1'),
        _session('ot-2'),
        _session('ot-3'),
      ];
      final remounted = OvertimeAdminCubit(
        listAdmin: ListAdminOvertimeUseCase(setup.repo),
        sessionQueryCache: setup.cache,
      );
      await remounted.loadFirstPage();

      expect(remounted.state.items.map((e) => e.id), ['ot-1', 'ot-2', 'ot-3']);
      expect(remounted.state.items[1].status, OvertimeStatus.approved);
      expect(remounted.state.items[1].approvedHours, 1.5);
      expect(remounted.state.items[0].status, OvertimeStatus.pendingReview);
      expect(remounted.state.items.where((e) => e.id == 'ot-2').length, 1);
      await remounted.close();
    },
  );

  test('older loadFirstPage result cannot overwrite a newer request', () async {
    final setup = _admin();
    setup.repo.useHolds = true;
    setup.repo.itemsByCall[0] = [
      _session('ot-1'),
      _session('ot-2'),
      _session('ot-3'),
    ];
    setup.repo.itemsByCall[1] = [
      _session('ot-1', status: OvertimeStatus.approved, approvedHours: 4),
      _session('ot-2'),
      _session('ot-3'),
    ];

    final first = setup.cubit.loadFirstPage();
    await Future<void>.delayed(Duration.zero);
    expect(setup.repo.holds, hasLength(1));

    final second = setup.cubit.loadFirstPage();
    await Future<void>.delayed(Duration.zero);
    expect(setup.repo.holds, hasLength(2));

    setup.repo.holds[1].complete();
    await second;
    expect(setup.cubit.state.items.first.status, OvertimeStatus.approved);
    expect(setup.cubit.state.items.first.approvedHours, 4);

    setup.repo.holds[0].complete();
    await first;
    expect(setup.cubit.state.items.first.status, OvertimeStatus.approved);
    expect(setup.cubit.state.items.first.approvedHours, 4);

    setup.repo.useHolds = false;
    final probe = OvertimeAdminCubit(
      listAdmin: ListAdminOvertimeUseCase(setup.repo),
      sessionQueryCache: setup.cache,
    );
    setup.repo.useHolds = true;
    probe.loadFirstPage();
    await Future<void>.delayed(Duration.zero);
    expect(probe.state.items.first.status, OvertimeStatus.approved);
    expect(probe.state.items.first.approvedHours, 4);
    await probe.close();
    await setup.cubit.close();
  });

  test(
    'syncReviewedSession does not rewrite history, running, or unrelated cache',
    () async {
      final setup = _admin();
      await setup.cubit.loadFirstPage();

      const historyKey = 'overtime:history:mine:page1';
      const runningKey = 'overtime:running';
      const unrelatedKey = 'dashboard:executive';
      setup.cache.set(historyKey, 'history-marker');
      setup.cache.set(runningKey, 'running-marker');
      setup.cache.set(unrelatedKey, 'unrelated-marker');

      OvertimeAdminCubit.syncReviewedSession(
        setup.cache,
        _session('ot-1', status: OvertimeStatus.rejected, rejectionReason: 'no'),
      );

      expect(setup.cache.get<String>(historyKey), 'history-marker');
      expect(setup.cache.get<String>(runningKey), 'running-marker');
      expect(setup.cache.get<String>(unrelatedKey), 'unrelated-marker');

      await setup.cubit.close();
      final remounted = OvertimeAdminCubit(
        listAdmin: ListAdminOvertimeUseCase(setup.repo),
        sessionQueryCache: setup.cache,
      );
      setup.repo.useHolds = true;
      remounted.loadFirstPage();
      await Future<void>.delayed(Duration.zero);
      expect(remounted.state.items.first.status, OvertimeStatus.rejected);
      expect(remounted.state.items.first.rejectionReason, 'no');
      await remounted.close();
    },
  );

  test('cancelled filter requests CANCELLED and clears for operational All',
      () async {
    final setup = _admin(
      pages: {
        1: [_session('ot-c', status: OvertimeStatus.cancelled)],
      },
    );

    await setup.cubit.setFilter(OvertimeStatus.cancelled);
    expect(setup.cubit.state.filterStatus, OvertimeStatus.cancelled);
    expect(setup.cubit.state.items.single.status, OvertimeStatus.cancelled);
    expect(setup.repo.calls.last.status, OvertimeStatus.cancelled);

    await setup.cubit.setFilter(OvertimeStatus.approved);
    expect(setup.cubit.state.filterStatus, OvertimeStatus.approved);
    expect(setup.repo.calls.last.status, OvertimeStatus.approved);

    await setup.cubit.setFilter(null);
    expect(setup.cubit.state.filterStatus, isNull);
    expect(setup.repo.calls.last.status, isNull);

    await setup.cubit.close();
  });
}
