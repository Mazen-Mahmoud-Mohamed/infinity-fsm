import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/push/notification_navigation.dart';
import 'package:mobile/core/push/pending_notification_store.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification_realtime.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnreadRepo extends Fake implements NotificationsRepository {
  @override
  Future<Result<int>> getUnreadCount() async => const Success(0);

  @override
  int unreadCountFromActivity(List<DashboardLiveActivityItem> activity) => 0;
}

class _PagingGet implements GetNotificationsUseCase {
  _PagingGet(this.pages, {this.unreadMeta = 7, this.unreadByPage});

  final Map<int, List<AppNotification>> pages;
  int unreadMeta;
  final Map<int, int>? unreadByPage;
  final calls = <int>[];
  Duration delay = Duration.zero;
  final failPages = <int>{};

  @override
  Future<Result<NotificationsPageResult>> call({
    int page = 1,
    int limit = 50,
  }) async {
    calls.add(page);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (failPages.contains(page)) {
      return const Failure('page failed', code: 'HTTP_500');
    }
    final items = pages[page] ?? const <AppNotification>[];
    final maxPage = pages.keys.fold<int>(0, (a, b) => a > b ? a : b);
    return Success(
      (
        items: items,
        unreadCount: unreadByPage?[page] ?? unreadMeta,
        page: page,
        hasMore: page < maxPage,
      ),
    );
  }
}

class _NoopMark implements MarkNotificationReadUseCase {
  @override
  Future<Result<void>> call(String id) async => const Success(null);
}

class _MarkResult implements MarkNotificationReadUseCase {
  Result<void> result = const Success(null);

  @override
  Future<Result<void>> call(String id) async => result;
}

class _NoopMarkAll implements MarkAllNotificationsReadUseCase {
  @override
  Future<Result<void>> call(Iterable<String> ids) async => const Success(null);
}

AppNotification _item(
  String id, {
  bool isRead = false,
  String module = 'work_orders',
  String title = 'Assigned',
}) {
  return AppNotification(
    id: id,
    title: title,
    body: 'Body $id',
    category: AppNotification.categoryFromModule(module),
    module: module,
    isRead: isRead,
  );
}

({NotificationsCubit cubit, NotificationsUnreadCubit unread}) _setup(
  _PagingGet get, {
  MarkNotificationReadUseCase? mark,
}) {
  final unread = NotificationsUnreadCubit(
    getUnreadCount: GetNotificationsUnreadCountUseCase(_UnreadRepo()),
    repository: _UnreadRepo(),
    refreshDebounce: Duration.zero,
  )..applyExactCount(0);
  final cubit = NotificationsCubit(
    getNotifications: get,
    markNotificationRead: mark ?? _NoopMark(),
    markAllNotificationsRead: _NoopMarkAll(),
    unreadCubit: unread,
  );
  return (cubit: cubit, unread: unread);
}

List<AppNotification> _pageItems(int page, int count) {
  return List.generate(count, (i) => _item('p${page}_$i'));
}

void _ingestSelf(
  NotificationsCubit cubit,
  AppNotification item, {
  String userId = 'user-a',
}) {
  cubit.bindAuthenticatedUser(userId);
  cubit.ingestRealtime(
    item,
    recipientUserId: userId,
    authenticatedUserId: userId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('inbox pagination', () {
    test('first page loads correctly', () async {
      final get = _PagingGet({
        1: _pageItems(1, 50),
        2: _pageItems(2, 50),
      });
      final setup = _setup(get);
      await setup.cubit.load();

      expect(get.calls, [1]);
      expect(setup.cubit.state.items, hasLength(50));
      expect(setup.cubit.state.page, 1);
      expect(setup.cubit.state.hasMore, isTrue);
      expect(setup.cubit.state.status, NotificationsStatus.ready);
      expect(setup.unread.state.count, 7);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('second and third pages append without replacing', () async {
      final get = _PagingGet({
        1: _pageItems(1, 50),
        2: _pageItems(2, 50),
        3: _pageItems(3, 10),
      });
      final setup = _setup(get);
      await setup.cubit.load();
      await setup.cubit.loadMore();
      await setup.cubit.loadMore();

      expect(get.calls, [1, 2, 3]);
      expect(setup.cubit.state.items, hasLength(110));
      expect(setup.cubit.state.items.first.id, 'p1_0');
      expect(setup.cubit.state.items[50].id, 'p2_0');
      expect(setup.cubit.state.page, 3);
      expect(setup.cubit.state.hasMore, isFalse);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('duplicate notification IDs are not duplicated when merging pages',
        () async {
      final overlap = _item('shared');
      final get = _PagingGet({
        1: [overlap, _item('a')],
        2: [overlap, _item('b')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      await setup.cubit.loadMore();

      expect(setup.cubit.state.items.map((e) => e.id), ['shared', 'a', 'b']);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('concurrent loadMore calls produce only one request', () async {
      final get = _PagingGet({
        1: _pageItems(1, 50),
        2: _pageItems(2, 50),
      })
        ..delay = const Duration(milliseconds: 40);
      final setup = _setup(get);
      await setup.cubit.load();
      await Future.wait([
        setup.cubit.loadMore(),
        setup.cubit.loadMore(),
        setup.cubit.loadMore(),
      ]);

      expect(get.calls.where((page) => page == 2), hasLength(1));
      expect(setup.cubit.state.items, hasLength(100));
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('hasMore=false prevents additional requests', () async {
      final get = _PagingGet({1: _pageItems(1, 10)});
      final setup = _setup(get);
      await setup.cubit.load();
      await setup.cubit.loadMore();
      await setup.cubit.loadMore();

      expect(get.calls, [1]);
      expect(setup.cubit.state.hasMore, isFalse);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('refresh reloads page 1 and resets pagination', () async {
      final get = _PagingGet({
        1: _pageItems(1, 50),
        2: _pageItems(2, 50),
      });
      final setup = _setup(get);
      await setup.cubit.load();
      await setup.cubit.loadMore();
      expect(setup.cubit.state.items, hasLength(100));

      await setup.cubit.load();
      expect(get.calls, [1, 2, 1]);
      expect(setup.cubit.state.items, hasLength(50));
      expect(setup.cubit.state.page, 1);
      expect(setup.cubit.state.hasMore, isTrue);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('search/filter resets pagination via category reload', () async {
      final get = _PagingGet({
        1: [
          _item('wo1'),
          _item('ot1', module: 'overtime', title: 'Overtime'),
        ],
        2: [_item('wo2')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      await setup.cubit.loadMore();
      expect(setup.cubit.state.page, 2);

      setup.cubit.setSearchQuery('Overtime');
      expect(setup.cubit.state.visibleItems.map((e) => e.id), ['ot1']);
      expect(get.calls, [1, 2]);

      setup.cubit.setCategory(NotificationCategory.overtime);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(get.calls.last, 1);
      expect(setup.cubit.state.page, 1);
      expect(
        setup.cubit.state.visibleItems.every(
          (item) => item.category == NotificationCategory.overtime,
        ),
        isTrue,
      );
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('failed loadMore does not destroy existing items', () async {
      final get = _PagingGet({
        1: _pageItems(1, 50),
        2: _pageItems(2, 50),
      })
        ..failPages.add(2);
      final setup = _setup(get);
      await setup.cubit.load();
      await setup.cubit.loadMore();

      expect(setup.cubit.state.items, hasLength(50));
      expect(setup.cubit.state.hasMore, isTrue);
      expect(setup.cubit.state.isLoadingMore, isFalse);

      get.failPages.clear();
      await setup.cubit.loadMore();
      expect(setup.cubit.state.items, hasLength(100));
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('unread count meta remains correct across pages', () async {
      final get = _PagingGet({
        1: _pageItems(1, 50),
        2: _pageItems(2, 50),
      }, unreadMeta: 4);
      final setup = _setup(get);
      await setup.cubit.load();
      expect(setup.unread.state.count, 4);
      await setup.cubit.loadMore();
      expect(setup.unread.state.count, 4);
      await setup.cubit.close();
      await setup.unread.close();
    });
  });

  group('realtime inbox insert', () {
    test('new realtime notification prepends', () async {
      final get = _PagingGet({
        1: [_item('old')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      _ingestSelf(setup.cubit, _item('new', title: 'Fresh'));

      expect(setup.cubit.state.items.map((e) => e.id), ['new', 'old']);
      expect(setup.cubit.state.page, 1);
      expect(get.calls, [1]);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('duplicate realtime notification is ignored', () async {
      final get = _PagingGet({
        1: [_item('n1')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      _ingestSelf(setup.cubit, _item('n1', title: 'Again'));

      expect(setup.cubit.state.items, hasLength(1));
      expect(setup.cubit.state.items.single.title, 'Assigned');
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('realtime notification does not reset pagination', () async {
      final get = _PagingGet({
        1: _pageItems(1, 50),
        2: _pageItems(2, 50),
      });
      final setup = _setup(get);
      await setup.cubit.load();
      await setup.cubit.loadMore();
      _ingestSelf(setup.cubit, _item('live'));

      expect(setup.cubit.state.page, 2);
      expect(setup.cubit.state.hasMore, isFalse);
      expect(setup.cubit.state.items.first.id, 'live');
      expect(setup.cubit.state.items, hasLength(101));
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('realtime notification during refresh is not lost', () async {
      final get = _PagingGet({
        1: [_item('server')],
      })
        ..delay = const Duration(milliseconds: 40);
      final setup = _setup(get);
      final first = setup.cubit.load();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      _ingestSelf(setup.cubit, _item('live'));
      await first;

      expect(setup.cubit.state.items.map((e) => e.id), ['live', 'server']);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('read notification does not incorrectly increment unread', () async {
      final get = _PagingGet({
        1: [_item('old', isRead: true)],
      }, unreadMeta: 2);
      final setup = _setup(get);
      await setup.cubit.load();
      expect(setup.unread.state.count, 2);
      _ingestSelf(setup.cubit, _item('read-live', isRead: true));
      expect(setup.unread.state.count, 2);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('malformed realtime payload does not fabricate an item', () async {
      final get = _PagingGet({
        1: [_item('old')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.bindAuthenticatedUser('user-a');
      final ingested = setup.cubit.ingestRealtimePayload(
        {'titleEn': 'Nope'},
        localeCode: 'en',
        authenticatedUserId: 'user-a',
      );
      expect(ingested, isFalse);
      expect(setup.cubit.state.items.map((e) => e.id), ['old']);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('filtered list does not show a non-matching realtime item', () async {
      final get = _PagingGet({
        1: [_item('wo1')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.setSearchQuery('Assigned');
      _ingestSelf(
        setup.cubit,
        _item('ot-live', module: 'overtime', title: 'OT'),
      );

      expect(
        setup.cubit.state.items.any((item) => item.id == 'ot-live'),
        isTrue,
      );
      expect(
        setup.cubit.state.visibleItems.any((item) => item.id == 'ot-live'),
        isFalse,
      );
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('other-user recipient is not ingested', () async {
      final get = _PagingGet({
        1: [_item('old')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.bindAuthenticatedUser('user-a');
      setup.cubit.ingestRealtime(
        _item('foreign'),
        recipientUserId: 'user-b',
        authenticatedUserId: 'user-a',
      );
      expect(setup.cubit.state.items.map((e) => e.id), ['old']);
      await setup.cubit.close();
      await setup.unread.close();
    });
  });

  group('fail-closed realtime ingest', () {
    test('valid recipient matching captured user is inserted', () async {
      final get = _PagingGet({
        1: [_item('old')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      _ingestSelf(setup.cubit, _item('ok'));
      expect(setup.cubit.state.items.map((e) => e.id), ['ok', 'old']);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('recipient different from captured user is ignored', () async {
      final get = _PagingGet({
        1: [_item('old')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.bindAuthenticatedUser('user-a');
      setup.cubit.ingestRealtime(
        _item('skip'),
        recipientUserId: 'user-b',
        authenticatedUserId: 'user-a',
      );
      expect(setup.cubit.state.items.map((e) => e.id), ['old']);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('missing recipientUserId is ignored', () async {
      final get = _PagingGet({
        1: [_item('old')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.bindAuthenticatedUser('user-a');
      setup.cubit.ingestRealtime(
        _item('skip'),
        authenticatedUserId: 'user-a',
      );
      expect(setup.cubit.state.items.map((e) => e.id), ['old']);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('missing authenticated user is ignored', () async {
      final get = _PagingGet({
        1: [_item('old')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.bindAuthenticatedUser('user-a');
      setup.cubit.ingestRealtime(
        _item('skip'),
        recipientUserId: 'user-a',
      );
      expect(setup.cubit.state.items.map((e) => e.id), ['old']);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('User A callback cannot insert into User B after account switch',
        () async {
      final get = _PagingGet({
        1: [_item('old')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.bindAuthenticatedUser('user-a');
      setup.cubit.bindAuthenticatedUser('user-b');
      setup.cubit.ingestRealtime(
        _item('from-a'),
        recipientUserId: 'user-a',
        authenticatedUserId: 'user-a',
      );
      expect(setup.cubit.state.items.map((e) => e.id), ['old']);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('nested data.recipientUserId cannot bypass top-level requirement',
        () async {
      final get = _PagingGet({
        1: [_item('old')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.bindAuthenticatedUser('user-a');
      final ingested = setup.cubit.ingestRealtimePayload(
        {
          'id': 'hijack',
          'titleEn': 'Hi',
          'bodyEn': 'There',
          'data': {'recipientUserId': 'user-a'},
        },
        localeCode: 'en',
        authenticatedUserId: 'user-a',
      );
      expect(ingested, isFalse);
      expect(setup.cubit.state.items.map((e) => e.id), ['old']);
      expect(realtimeRecipientUserId({
        'data': {'recipientUserId': 'user-a'},
      }), isNull);
      await setup.cubit.close();
      await setup.unread.close();
    });
  });

  group('search pagination UX', () {
    test('search with visible matches keeps those items', () async {
      final get = _PagingGet({
        1: [
          _item('wo1', title: 'Assigned'),
          _item('ot1', module: 'overtime', title: 'Overtime'),
        ],
        2: [_item('wo2')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.setSearchQuery('Overtime');
      expect(setup.cubit.state.visibleItems.map((e) => e.id), ['ot1']);
      expect(setup.cubit.state.showSearchLoadMore, isFalse);
      expect(setup.unread.state.count, 7);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('search with no visible matches and hasMore shows load-more path',
        () async {
      final get = _PagingGet({
        1: [_item('wo1', title: 'Assigned')],
        2: [_item('ot2', module: 'overtime', title: 'Overtime later')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.setSearchQuery('Overtime later');
      expect(setup.cubit.state.visibleItems, isEmpty);
      expect(setup.cubit.state.hasMore, isTrue);
      expect(setup.cubit.state.showSearchLoadMore, isTrue);
      await setup.cubit.loadMore();
      expect(get.calls, [1, 2]);
      expect(setup.cubit.state.visibleItems.map((e) => e.id), ['ot2']);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('search with no matches and hasMore false is a normal empty search',
        () async {
      final get = _PagingGet({
        1: [_item('wo1', title: 'Assigned')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.setSearchQuery('zzzz');
      expect(setup.cubit.state.visibleItems, isEmpty);
      expect(setup.cubit.state.hasMore, isFalse);
      expect(setup.cubit.state.showSearchLoadMore, isFalse);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('loadMore failure preserves existing items during search', () async {
      final get = _PagingGet({
        1: [_item('wo1', title: 'Assigned')],
        2: [_item('ot2', title: 'Overtime')],
      })
        ..failPages.add(2);
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.setSearchQuery('Overtime');
      await setup.cubit.loadMore();
      expect(setup.cubit.state.items.map((e) => e.id), ['wo1']);
      expect(setup.cubit.state.hasMore, isTrue);
      expect(setup.cubit.state.showSearchLoadMore, isTrue);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('changing category resets pagination', () async {
      final get = _PagingGet({
        1: [_item('wo1')],
        2: [_item('wo2')],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      await setup.cubit.loadMore();
      expect(setup.cubit.state.page, 2);
      setup.cubit.setCategory(NotificationCategory.workOrders);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(get.calls.last, 1);
      expect(setup.cubit.state.page, 1);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('clearing search restores loaded items', () async {
      final get = _PagingGet({
        1: [
          _item('wo1', title: 'Assigned'),
          _item('ot1', module: 'overtime', title: 'Overtime'),
        ],
      });
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.setSearchQuery('Overtime');
      expect(setup.cubit.state.visibleItems, hasLength(1));
      setup.cubit.setSearchQuery('');
      expect(setup.cubit.state.visibleItems.map((e) => e.id), ['wo1', 'ot1']);
      await setup.cubit.close();
      await setup.unread.close();
    });
  });

  group('authoritative inbox unread count', () {
    test('page 1 uses server unread count', () async {
      final get = _PagingGet({
        1: _pageItems(1, 50),
        2: _pageItems(2, 50),
      }, unreadMeta: 12);
      final setup = _setup(get);
      await setup.cubit.load();
      expect(setup.unread.state.count, 12);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('page 2 and page 3 do not change unread from loaded items', () async {
      final get = _PagingGet(
        {
          1: _pageItems(1, 50),
          2: _pageItems(2, 50),
          3: _pageItems(3, 10),
        },
        unreadMeta: 3,
        unreadByPage: {1: 3, 2: 99, 3: 1},
      );
      final setup = _setup(get);
      await setup.cubit.load();
      expect(setup.unread.state.count, 3);
      await setup.cubit.loadMore();
      expect(setup.unread.state.count, 3);
      await setup.cubit.loadMore();
      expect(setup.unread.state.count, 3);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('search does not change unreadCount', () async {
      final get = _PagingGet({
        1: [
          _item('a', isRead: false),
          _item('b', isRead: true, title: 'Other'),
        ],
      }, unreadMeta: 8);
      final setup = _setup(get);
      await setup.cubit.load();
      setup.cubit.setSearchQuery('Other');
      expect(setup.unread.state.count, 8);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('category filter updates unread only from page-1 server meta',
        () async {
      final get = _PagingGet({
        1: [_item('wo1')],
        2: [_item('wo2')],
      }, unreadMeta: 5);
      final setup = _setup(get);
      await setup.cubit.load();
      await setup.cubit.loadMore();
      expect(setup.unread.state.count, 5);
      get.unreadMeta = 11;
      setup.cubit.setCategory(NotificationCategory.workOrders);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(setup.unread.state.count, 11);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('realtime insert does not derive unread from items', () async {
      final get = _PagingGet({
        1: [_item('old', isRead: true)],
      }, unreadMeta: 4);
      final setup = _setup(get);
      await setup.cubit.load();
      _ingestSelf(setup.cubit, _item('live', isRead: false));
      expect(setup.cubit.state.items.where((e) => !e.isRead), hasLength(1));
      expect(setup.unread.state.count, 4);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('successful markAsRead decrements unread exactly once', () async {
      final mark = _MarkResult();
      final get = _PagingGet({
        1: [_item('n1')],
      }, unreadMeta: 2);
      final setup = _setup(get, mark: mark);
      await setup.cubit.load();
      expect(setup.unread.state.count, 2);
      await setup.cubit.markAsRead('n1');
      expect(setup.unread.state.count, 1);
      await setup.cubit.markAsRead('n1');
      expect(setup.unread.state.count, 1);
      await setup.cubit.close();
      await setup.unread.close();
    });

    test('failed markAsRead does not decrement unread', () async {
      final mark = _MarkResult()..result = const Failure('down', code: 'HTTP_500');
      final get = _PagingGet({
        1: [_item('n1')],
      }, unreadMeta: 2);
      final setup = _setup(get, mark: mark);
      await setup.cubit.load();
      await setup.cubit.markAsRead('n1');
      expect(setup.unread.state.count, 2);
      expect(setup.cubit.state.items.single.isRead, isFalse);
      await setup.cubit.close();
      await setup.unread.close();
    });
  });

  group('socket payload recipientUserId', () {
    test('targeted payload includes server recipientUserId', () {
      final mapped = socketPayloadForNavigation({
        'id': 'n1',
        'entityType': 'work_order',
        'entityId': 'wo1',
        'recipientUserId': 'user-a',
        'data': {'recipientUserId': 'user-b', 'workOrderId': 'wo1'},
      });
      expect(mapped['recipientUserId'], 'user-a');
      expect(mapped['workOrderId'], 'wo1');
    });

    test('nested client recipientUserId cannot hijack ownership', () {
      final mapped = socketPayloadForNavigation({
        'id': 'n1',
        'entityType': 'work_order',
        'entityId': 'wo1',
        'data': {'recipientUserId': 'user-b', 'workOrderId': 'wo1'},
      });
      expect(mapped.containsKey('recipientUserId'), isFalse);
    });

    test('User A payload cannot become User B pending navigation', () async {
      SharedPreferences.setMockInitialValues({});
      final store = PendingNotificationStore(
        PreferencesService(await SharedPreferences.getInstance()),
      );
      final mapped = socketPayloadForNavigation({
        'id': 'n1',
        'entityType': 'work_order',
        'entityId': 'wo-a',
        'workOrderId': 'wo-a',
        'recipientUserId': 'user-a',
      });
      final intent = resolveNotificationNavigation(mapped).copyWith(
        userId: mapped['recipientUserId']?.toString(),
      );
      await store.persist(intent);
      expect(await store.takeForUser('user-b'), isNull);
    });

    test('deep-link route ignores recipientUserId for authorization', () {
      final intent = resolveNotificationNavigation({
        'type': 'work_order',
        'workOrderId': 'wo-secret',
        'recipientUserId': 'user-b',
      });
      expect(intent.route, RoutePaths.workOrderDetail('wo-secret'));
      expect(intent.userId, isNull);
    });
  });

  test('incomplete realtime mapper returns null', () {
    expect(
      appNotificationFromRealtime({'id': 'n1'}, localeCode: 'en'),
      isNull,
    );
    expect(
      appNotificationFromRealtime(
        {'titleEn': 'Hi', 'bodyEn': 'There'},
        localeCode: 'en',
      ),
      isNull,
    );
  });
}
