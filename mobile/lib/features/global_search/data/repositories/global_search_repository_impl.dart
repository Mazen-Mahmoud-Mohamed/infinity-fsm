import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/assets/domain/usecases/assets_usecases.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';
import 'package:mobile/features/global_search/domain/entities/global_search_hit.dart';
import 'package:mobile/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:mobile/features/inventory/domain/usecases/spare_part_usecases.dart';
import 'package:mobile/features/overtime/domain/usecases/list_admin_overtime_usecase.dart';
import 'package:mobile/features/pm/domain/usecases/pm_usecases.dart';
import 'package:mobile/features/service_reports/domain/usecases/service_reports_usecases.dart';
import 'package:mobile/features/users/domain/usecases/users_usecases.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_my_work_orders_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_work_orders_usecase.dart';

class GlobalSearchRepositoryImpl implements GlobalSearchRepository {
  GlobalSearchRepositoryImpl({
    required ListManagedUsersUseCase listUsers,
    required ListAssetsUseCase listAssets,
    required ListSparePartsUseCase listSpareParts,
    required ListWorkOrdersUseCase listWorkOrders,
    required ListMyWorkOrdersUseCase listMyWorkOrders,
    required ListAdminOvertimeUseCase listAdminOvertime,
    required ListPmPlansUseCase listPmPlans,
    required ListServiceReportsUseCase listServiceReports,
  })  : _listUsers = listUsers,
        _listAssets = listAssets,
        _listSpareParts = listSpareParts,
        _listWorkOrders = listWorkOrders,
        _listMyWorkOrders = listMyWorkOrders,
        _listAdminOvertime = listAdminOvertime,
        _listPmPlans = listPmPlans,
        _listServiceReports = listServiceReports;

  static const int _limitPerModule = 5;

  final ListManagedUsersUseCase _listUsers;
  final ListAssetsUseCase _listAssets;
  final ListSparePartsUseCase _listSpareParts;
  final ListWorkOrdersUseCase _listWorkOrders;
  final ListMyWorkOrdersUseCase _listMyWorkOrders;
  final ListAdminOvertimeUseCase _listAdminOvertime;
  final ListPmPlansUseCase _listPmPlans;
  final ListServiceReportsUseCase _listServiceReports;

  @override
  Future<Result<List<GlobalSearchHit>>> search({
    required String query,
    required PermissionChecker permissions,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return const Success(<GlobalSearchHit>[]);
    }

    final futures = <Future<List<GlobalSearchHit>>>[];

    if (permissions.canViewUsers()) {
      futures.add(_searchUsers(trimmed));
    }
    if (permissions.canViewWorkOrders()) {
      futures.add(_searchWorkOrders(trimmed, permissions));
    }
    if (permissions.canViewAssets()) {
      futures.add(_searchAssets(trimmed));
    }
    if (permissions.canViewInventory()) {
      futures.add(_searchInventory(trimmed));
    }
    if (permissions.canViewAllOvertime() || permissions.canApproveOvertime()) {
      futures.add(_searchOvertime(trimmed));
    }
    if (permissions.canViewPm()) {
      futures.add(_searchPm(trimmed));
    }
    if (permissions.canViewReports()) {
      futures.add(_searchReports(trimmed));
    }

    if (futures.isEmpty) {
      return const Success(<GlobalSearchHit>[]);
    }

    final chunks = await Future.wait(futures);
    final hits = <GlobalSearchHit>[
      for (final chunk in chunks) ...chunk,
    ];
    return Success(hits);
  }

  Future<List<GlobalSearchHit>> _searchUsers(String query) async {
    final result = await _listUsers(
      page: 1,
      limit: _limitPerModule,
      search: query,
    );
    return switch (result) {
      Success(data: final page) => [
          for (final user in page.items)
            GlobalSearchHit(
              id: user.id,
              module: GlobalSearchModule.users,
              title: user.fullName,
              subtitle: user.email,
              route: RoutePaths.userDetail(user.id),
            ),
        ],
      Failure() => const [],
    };
  }

  Future<List<GlobalSearchHit>> _searchWorkOrders(
    String query,
    PermissionChecker permissions,
  ) async {
    final useAdminList = permissions.canViewAllWorkOrders() ||
        permissions.canViewTeamWorkOrders() ||
        permissions.canManageWorkOrders();
    final result = useAdminList
        ? await _listWorkOrders(
            page: 1,
            limit: _limitPerModule,
            search: query,
          )
        : await _listMyWorkOrders(
            page: 1,
            limit: _limitPerModule,
            search: query,
          );
    return switch (result) {
      Success(data: final page) => [
          for (final order in page.items)
            GlobalSearchHit(
              id: order.id,
              module: GlobalSearchModule.workOrders,
              title: order.jobTitle,
              subtitle: [
                order.jobNumber,
                if (order.customerName != null &&
                    order.customerName!.trim().isNotEmpty)
                  order.customerName!.trim(),
              ].join(' · '),
              route: RoutePaths.workOrderDetail(order.id),
            ),
        ],
      Failure() => const [],
    };
  }

  Future<List<GlobalSearchHit>> _searchAssets(String query) async {
    final result = await _listAssets(
      page: 1,
      limit: _limitPerModule,
      search: query,
    );
    return switch (result) {
      Success(data: final page) => [
          for (final asset in page.items)
            GlobalSearchHit(
              id: asset.id,
              module: GlobalSearchModule.assets,
              title: asset.name,
              subtitle: asset.assetNumber,
              route: RoutePaths.assetDetail(asset.id),
            ),
        ],
      Failure() => const [],
    };
  }

  Future<List<GlobalSearchHit>> _searchInventory(String query) async {
    final result = await _listSpareParts(
      page: 1,
      limit: _limitPerModule,
      search: query,
    );
    return switch (result) {
      Success(data: final page) => [
          for (final part in page.items)
            GlobalSearchHit(
              id: part.id,
              module: GlobalSearchModule.inventory,
              title: part.name,
              subtitle: part.partNumber,
              route: RoutePaths.inventoryPartDetail(part.id),
            ),
        ],
      Failure() => const [],
    };
  }

  Future<List<GlobalSearchHit>> _searchOvertime(String query) async {
    final result = await _listAdminOvertime(
      page: 1,
      limit: _limitPerModule,
      search: query,
    );
    return switch (result) {
      Success(data: final page) => [
          for (final session in page.items)
            GlobalSearchHit(
              id: session.id,
              module: GlobalSearchModule.overtime,
              title: session.technician?.displayName ?? session.userId,
              subtitle: '${session.type.name} · ${session.status.name}',
              route: RoutePaths.overtimeAdminDetail(session.id),
            ),
        ],
      Failure() => const [],
    };
  }

  Future<List<GlobalSearchHit>> _searchPm(String query) async {
    final result = await _listPmPlans(
      page: 1,
      limit: _limitPerModule,
      search: query,
    );
    return switch (result) {
      Success(data: final page) => [
          for (final plan in page.items)
            GlobalSearchHit(
              id: plan.id,
              module: GlobalSearchModule.pm,
              title: plan.name,
              subtitle: plan.code,
              route: RoutePaths.pmPlanDetail(plan.id),
            ),
        ],
      Failure() => const [],
    };
  }

  Future<List<GlobalSearchHit>> _searchReports(String query) async {
    final result = await _listServiceReports(
      page: 1,
      limit: _limitPerModule,
      search: query,
    );
    return switch (result) {
      Success(data: final page) => [
          for (final report in page.items)
            GlobalSearchHit(
              id: report.id,
              module: GlobalSearchModule.reports,
              title: report.reportNumber,
              subtitle: [
                if (report.workOrder.jobTitle != null &&
                    report.workOrder.jobTitle!.trim().isNotEmpty)
                  report.workOrder.jobTitle!.trim(),
                if (report.workOrder.customerName != null &&
                    report.workOrder.customerName!.trim().isNotEmpty)
                  report.workOrder.customerName!.trim(),
              ].join(' · '),
              route: RoutePaths.reportDetail(report.id),
            ),
        ],
      Failure() => const [],
    };
  }
}
