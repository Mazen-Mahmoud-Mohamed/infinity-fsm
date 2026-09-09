import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:mobile/features/notifications/presentation/widgets/notifications_skeleton.dart';

class _UnreadRepo extends Fake implements NotificationsRepository {
  @override
  Future<Result<int>> getUnreadCount() async => const Success(12);

  @override
  int unreadCountFromActivity(List<DashboardLiveActivityItem> activity) => 0;
}

class _PagingGet implements GetNotificationsUseCase {
  _PagingGet({required this.hasMoreAfterPage1});

  final bool hasMoreAfterPage1;
  final calls = <int>[];

  @override
  Future<Result<NotificationsPageResult>> call({
    int page = 1,
    int limit = 50,
  }) async {
    calls.add(page);
    return Success(
      (
        items: [
          AppNotification(
            id: 'wo1',
            title: 'Assigned',
            body: 'Body',
            category: NotificationCategory.workOrders,
            module: 'work_orders',
          ),
        ],
        unreadCount: 12,
        page: page,
        hasMore: page == 1 && hasMoreAfterPage1,
      ),
    );
  }
}

class _NoopMark implements MarkNotificationReadUseCase {
  @override
  Future<Result<void>> call(String id) async => const Success(null);
}

class _NoopMarkAll implements MarkAllNotificationsReadUseCase {
  @override
  Future<Result<void>> call(Iterable<String> ids) async => const Success(null);
}

Widget _app({
  required NotificationsCubit cubit,
  required NotificationsUnreadCubit unread,
  required Widget child,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider.value(value: unread),
      ],
      child: Scaffold(body: child),
    ),
  );
}

({NotificationsCubit cubit, NotificationsUnreadCubit unread}) _cubits(
  _PagingGet get,
) {
  final unread = NotificationsUnreadCubit(
    getUnreadCount: GetNotificationsUnreadCountUseCase(_UnreadRepo()),
    repository: _UnreadRepo(),
    refreshDebounce: Duration.zero,
  );
  final cubit = NotificationsCubit(
    getNotifications: get,
    markNotificationRead: _NoopMark(),
    markAllNotificationsRead: _NoopMarkAll(),
    unreadCubit: unread,
  );
  return (cubit: cubit, unread: unread);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('search with no visible matches and hasMore shows load more',
      (tester) async {
    final get = _PagingGet(hasMoreAfterPage1: true);
    final setup = _cubits(get);
    await setup.cubit.load();
    setup.cubit.setSearchQuery('zzzz-no-match');

    await tester.pumpWidget(
      _app(
        cubit: setup.cubit,
        unread: setup.unread,
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state.showSearchLoadMore) {
              return NotificationsSearchLoadMorePanel(
                isLoadingMore: state.isLoadingMore,
                onLoadMore: setup.cubit.loadMore,
              );
            }
            return Text(
              AppLocalizations.of(context).notificationsSearchEmpty,
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(NotificationsSearchLoadMorePanel.loadMoreButtonKey),
      findsOneWidget,
    );
    expect(
      find.text(
        'Search only covers notifications already loaded. More notifications are available.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(NotificationsSearchLoadMorePanel.loadMoreButtonKey),
    );
    await tester.pump();
    expect(get.calls, [1, 2]);

    await setup.cubit.close();
    await setup.unread.close();
  });

  testWidgets('search with no matches and hasMore false shows empty search',
      (tester) async {
    final get = _PagingGet(hasMoreAfterPage1: false);
    final setup = _cubits(get);
    await setup.cubit.load();
    setup.cubit.setSearchQuery('zzzz-no-match');

    await tester.pumpWidget(
      _app(
        cubit: setup.cubit,
        unread: setup.unread,
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state.showSearchLoadMore) {
              return NotificationsSearchLoadMorePanel(
                isLoadingMore: state.isLoadingMore,
                onLoadMore: setup.cubit.loadMore,
              );
            }
            return Text(
              AppLocalizations.of(context).notificationsSearchEmpty,
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(NotificationsSearchLoadMorePanel.loadMoreButtonKey),
      findsNothing,
    );
    expect(find.text('No notifications match your search.'), findsOneWidget);

    await setup.cubit.close();
    await setup.unread.close();
  });

  testWidgets('bell and inbox header use the same unread cubit count',
      (tester) async {
    final unread = NotificationsUnreadCubit(
      getUnreadCount: GetNotificationsUnreadCountUseCase(_UnreadRepo()),
      repository: _UnreadRepo(),
      refreshDebounce: Duration.zero,
    )..applyExactCount(12);

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
          value: unread,
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(
                appBar: AppBar(
                  actions: [
                    BlocBuilder<NotificationsUnreadCubit,
                        NotificationsUnreadState>(
                      builder: (context, state) => Text('bell:${state.count}'),
                    ),
                  ],
                ),
                body: BlocBuilder<NotificationsUnreadCubit,
                    NotificationsUnreadState>(
                  builder: (context, state) {
                    return Text(l10n.notificationsUnreadCount(state.count));
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('bell:12'), findsOneWidget);
    expect(find.text('12 unread notifications'), findsOneWidget);

    await unread.close();
  });
}
