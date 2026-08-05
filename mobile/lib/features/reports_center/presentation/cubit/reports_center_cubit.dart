import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/domain/usecases/assets_usecases.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/domain/usecases/list_admin_attendance_usecase.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/utils/dashboard_period_range.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/inventory/domain/usecases/spare_part_usecases.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/usecases/list_admin_overtime_usecase.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/domain/usecases/pm_usecases.dart';
import 'package:mobile/features/reports_center/domain/entities/report_list_row.dart';
import 'package:mobile/features/reports_center/domain/entities/reports_center_module.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';
import 'package:mobile/features/service_reports/domain/usecases/service_reports_usecases.dart';
import 'package:mobile/features/users/domain/usecases/users_usecases.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_my_work_orders_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_work_orders_usecase.dart';

enum ReportsCenterStatus { initial, loading, loadingMore, ready, failure }

class ReportsCenterState extends Equatable {
  const ReportsCenterState({
    this.status = ReportsCenterStatus.initial,
    this.module = ReportsCenterModule.serviceReports,
    this.availableModules = const [],
    this.search = '',
    this.statusKey,
    this.rangeFrom,
    this.rangeTo,
    this.employeeId,
    this.employees = const [],
    this.sort = ReportsSort.dateDesc,
    this.rows = const [],
    this.page = 1,
    this.hasMore = false,
    this.message,
    this.isRefreshing = false,
  });

  final ReportsCenterStatus status;
  final ReportsCenterModule module;
  final List<ReportsCenterModule> availableModules;
  final String search;
  final String? statusKey;
  final DateTime? rangeFrom;
  final DateTime? rangeTo;
  final String? employeeId;
  final List<ReportEmployeeOption> employees;
  final ReportsSort sort;
  final List<ReportListRow> rows;
  final int page;
  final bool hasMore;
  final String? message;
  final bool isRefreshing;

  List<ReportListRow> get sortedRows {
    final list = List<ReportListRow>.from(rows);
    int cmp(ReportListRow a, ReportListRow b) {
      switch (sort) {
        case ReportsSort.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case ReportsSort.titleDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        case ReportsSort.dateAsc:
          return (a.date ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.date ?? DateTime.fromMillisecondsSinceEpoch(0));
        case ReportsSort.dateDesc:
          return (b.date ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.date ?? DateTime.fromMillisecondsSinceEpoch(0));
        case ReportsSort.statusAsc:
          return (a.statusLabel ?? '').compareTo(b.statusLabel ?? '');
        case ReportsSort.statusDesc:
          return (b.statusLabel ?? '').compareTo(a.statusLabel ?? '');
      }
    }

    list.sort(cmp);
    return list;
  }

  ReportsCenterState copyWith({
    ReportsCenterStatus? status,
    ReportsCenterModule? module,
    List<ReportsCenterModule>? availableModules,
    String? search,
    String? statusKey,
    bool clearStatusKey = false,
    DateTime? rangeFrom,
    DateTime? rangeTo,
    bool clearRange = false,
    String? employeeId,
    bool clearEmployee = false,
    List<ReportEmployeeOption>? employees,
    ReportsSort? sort,
    List<ReportListRow>? rows,
    int? page,
    bool? hasMore,
    String? message,
    bool clearMessage = false,
    bool? isRefreshing,
  }) {
    return ReportsCenterState(
      status: status ?? this.status,
      module: module ?? this.module,
      availableModules: availableModules ?? this.availableModules,
      search: search ?? this.search,
      statusKey: clearStatusKey ? null : (statusKey ?? this.statusKey),
      rangeFrom: clearRange ? null : (rangeFrom ?? this.rangeFrom),
      rangeTo: clearRange ? null : (rangeTo ?? this.rangeTo),
      employeeId: clearEmployee ? null : (employeeId ?? this.employeeId),
      employees: employees ?? this.employees,
      sort: sort ?? this.sort,
      rows: rows ?? this.rows,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      message: clearMessage ? null : (message ?? this.message),
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        module,
        availableModules,
        search,
        statusKey,
        rangeFrom,
        rangeTo,
        employeeId,
        employees,
        sort,
        rows,
        page,
        hasMore,
        message,
        isRefreshing,
      ];
}

class ReportsCenterCubit extends Cubit<ReportsCenterState> {
  ReportsCenterCubit({
    required PermissionChecker permissions,
    required ListAdminAttendanceUseCase listAttendance,
    required ListAdminOvertimeUseCase listOvertime,
    required ListWorkOrdersUseCase listWorkOrders,
    required ListMyWorkOrdersUseCase listMyWorkOrders,
    required ListAssetsUseCase listAssets,
    required ListSparePartsUseCase listSpareParts,
    required ListPmPlansUseCase listPmPlans,
    required ListServiceReportsUseCase listServiceReports,
    required ListManagedUsersUseCase listUsers,
  })  : _permissions = permissions,
        _listAttendance = listAttendance,
        _listOvertime = listOvertime,
        _listWorkOrders = listWorkOrders,
        _listMyWorkOrders = listMyWorkOrders,
        _listAssets = listAssets,
        _listSpareParts = listSpareParts,
        _listPmPlans = listPmPlans,
        _listServiceReports = listServiceReports,
        _listUsers = listUsers,
        super(const ReportsCenterState());

  static const int _pageSize = 20;

  final PermissionChecker _permissions;
  final ListAdminAttendanceUseCase _listAttendance;
  final ListAdminOvertimeUseCase _listOvertime;
  final ListWorkOrdersUseCase _listWorkOrders;
  final ListMyWorkOrdersUseCase _listMyWorkOrders;
  final ListAssetsUseCase _listAssets;
  final ListSparePartsUseCase _listSpareParts;
  final ListPmPlansUseCase _listPmPlans;
  final ListServiceReportsUseCase _listServiceReports;
  final ListManagedUsersUseCase _listUsers;

  Future<void> bootstrap() async {
    final modules = ReportsCenterModule.values
        .where((m) => m.isAllowed(_permissions))
        .toList(growable: false);
    if (modules.isEmpty) {
      emit(
        state.copyWith(
          status: ReportsCenterStatus.failure,
          availableModules: const [],
          message: 'reportsCenterNoAccess',
        ),
      );
      return;
    }

    final initial = modules.contains(ReportsCenterModule.serviceReports)
        ? ReportsCenterModule.serviceReports
        : modules.first;

    emit(
      state.copyWith(
        availableModules: modules,
        module: initial,
        clearStatusKey: true,
        clearEmployee: true,
        clearRange: true,
      ),
    );

    if (initial.supportsEmployeeFilter && _permissions.canViewUsers()) {
      await _loadEmployees();
    }
    await loadFirstPage();
  }

  Future<void> selectModule(ReportsCenterModule module) async {
    if (!module.isAllowed(_permissions) || module == state.module) return;
    emit(
      state.copyWith(
        module: module,
        clearStatusKey: true,
        clearEmployee: true,
        clearRange: true,
        search: '',
        rows: const [],
        page: 1,
        hasMore: false,
        clearMessage: true,
      ),
    );
    if (module.supportsEmployeeFilter &&
        _permissions.canViewUsers() &&
        state.employees.isEmpty) {
      await _loadEmployees();
    }
    await loadFirstPage();
  }

  void setSearch(String value) {
    emit(state.copyWith(search: value));
  }

  Future<void> applySearch(String value) async {
    emit(state.copyWith(search: value.trim()));
    await loadFirstPage();
  }

  Future<void> setStatusKey(String? key) async {
    emit(
      state.copyWith(
        statusKey: key,
        clearStatusKey: key == null,
      ),
    );
    await loadFirstPage();
  }

  Future<void> setEmployee(String? id) async {
    emit(
      state.copyWith(
        employeeId: id,
        clearEmployee: id == null,
      ),
    );
    await loadFirstPage();
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    if (!state.module.supportsDateRange) return;
    emit(
      state.copyWith(
        rangeFrom: from,
        rangeTo: to,
        clearRange: from == null && to == null,
      ),
    );
    await loadFirstPage();
  }

  Future<void> setPeriod(DashboardPeriod period) async {
    if (!state.module.supportsDateRange) return;
    if (period == DashboardPeriod.custom) return;
    final range = DashboardPeriodRange.resolveLocal(period: period);
    await setDateRange(range.from, range.to);
  }

  void setSort(ReportsSort sort) {
    emit(state.copyWith(sort: sort));
  }

  Future<void> loadFirstPage() async {
    final hasRows = state.rows.isNotEmpty;
    emit(
      state.copyWith(
        status: hasRows
            ? ReportsCenterStatus.ready
            : ReportsCenterStatus.loading,
        isRefreshing: hasRows,
        clearMessage: true,
        page: 1,
      ),
    );

    final result = await _fetchPage(page: 1);
    switch (result) {
      case Success(data: final page):
        emit(
          state.copyWith(
            status: ReportsCenterStatus.ready,
            rows: page.rows,
            page: page.page,
            hasMore: page.hasMore,
            isRefreshing: false,
            clearMessage: true,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: ReportsCenterStatus.failure,
            rows: hasRows ? state.rows : const [],
            isRefreshing: false,
            message: message,
          ),
        );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == ReportsCenterStatus.loadingMore ||
        state.status == ReportsCenterStatus.loading) {
      return;
    }
    emit(state.copyWith(status: ReportsCenterStatus.loadingMore));
    final nextPage = state.page + 1;
    final result = await _fetchPage(page: nextPage);
    switch (result) {
      case Success(data: final page):
        emit(
          state.copyWith(
            status: ReportsCenterStatus.ready,
            rows: [...state.rows, ...page.rows],
            page: page.page,
            hasMore: page.hasMore,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: ReportsCenterStatus.ready,
            message: message,
          ),
        );
    }
  }

  Future<void> _loadEmployees() async {
    final result = await _listUsers(page: 1, limit: 50);
    if (result case Success(data: final page)) {
      emit(
        state.copyWith(
          employees: [
            for (final user in page.items)
              ReportEmployeeOption(id: user.id, label: user.fullName),
          ],
        ),
      );
    }
  }

  Future<Result<_Page>> _fetchPage({required int page}) async {
    final search = state.search.trim().isEmpty ? null : state.search.trim();
    switch (state.module) {
      case ReportsCenterModule.attendance:
        return _fetchAttendance(page: page, search: search);
      case ReportsCenterModule.overtime:
        return _fetchOvertime(page: page, search: search);
      case ReportsCenterModule.workOrders:
        return _fetchWorkOrders(page: page, search: search);
      case ReportsCenterModule.assets:
        return _fetchAssets(page: page, search: search);
      case ReportsCenterModule.inventory:
        return _fetchInventory(page: page, search: search);
      case ReportsCenterModule.pm:
        return _fetchPm(page: page, search: search);
      case ReportsCenterModule.serviceReports:
        return _fetchServiceReports(page: page, search: search);
    }
  }

  Future<Result<_Page>> _fetchAttendance({
    required int page,
    required String? search,
  }) async {
    final status = _attendanceStatus(state.statusKey);
    final result = await _listAttendance(
      page: page,
      limit: _pageSize,
      status: status,
      search: search,
      startDate: state.rangeFrom,
      endDate: state.rangeTo,
      userId: state.employeeId,
    );
    return switch (result) {
      Success(data: final data) => Success(
          _Page(
            rows: [
              for (final item in data.items)
                ReportListRow(
                  id: item.id,
                  module: ReportsCenterModule.attendance,
                  title: item.employee?.displayName ??
                      item.userId ??
                      item.id,
                  subtitle: item.date,
                  statusLabel: item.status.name,
                  date: item.createdAt ??
                      DateTime.tryParse(item.date),
                  meta: '${item.workingMinutes} min',
                  route: RoutePaths.attendanceAdminDetail(item.id),
                ),
            ],
            page: data.page,
            hasMore: data.hasMore,
          ),
        ),
      Failure(message: final message, code: final code) =>
        Failure(message, code: code),
    };
  }

  Future<Result<_Page>> _fetchOvertime({
    required int page,
    required String? search,
  }) async {
    final status = _overtimeStatus(state.statusKey);
    final result = await _listOvertime(
      page: page,
      limit: _pageSize,
      status: status,
      search: search,
    );
    return switch (result) {
      Success(data: final data) => Success(
          _Page(
            rows: [
              for (final item in data.items)
                ReportListRow(
                  id: item.id,
                  module: ReportsCenterModule.overtime,
                  title: item.technician?.displayName ?? item.userId,
                  subtitle: item.type.name,
                  statusLabel: item.status.name,
                  date: item.startAt,
                  route: RoutePaths.overtimeAdminDetail(item.id),
                ),
            ],
            page: data.page,
            hasMore: data.hasMore,
          ),
        ),
      Failure(message: final message, code: final code) =>
        Failure(message, code: code),
    };
  }

  Future<Result<_Page>> _fetchWorkOrders({
    required int page,
    required String? search,
  }) async {
    final status = _workOrderStatus(state.statusKey);
    final useAdmin = _permissions.canViewAllWorkOrders() ||
        _permissions.canViewTeamWorkOrders() ||
        _permissions.canManageWorkOrders();
    final result = useAdmin
        ? await _listWorkOrders(
            page: page,
            limit: _pageSize,
            status: status,
            search: search,
          )
        : await _listMyWorkOrders(
            page: page,
            limit: _pageSize,
            status: status,
            search: search,
          );
    return switch (result) {
      Success(data: final data) => Success(
          _Page(
            rows: [
              for (final item in data.items)
                ReportListRow(
                  id: item.id,
                  module: ReportsCenterModule.workOrders,
                  title: item.jobTitle,
                  subtitle: item.jobNumber,
                  statusLabel: item.status.name,
                  date: item.scheduledAt ?? item.createdAt,
                  meta: item.customerName,
                  route: RoutePaths.workOrderDetail(item.id),
                ),
            ],
            page: data.page,
            hasMore: data.hasMore,
          ),
        ),
      Failure(message: final message, code: final code) =>
        Failure(message, code: code),
    };
  }

  Future<Result<_Page>> _fetchAssets({
    required int page,
    required String? search,
  }) async {
    final status = _assetStatus(state.statusKey);
    final result = await _listAssets(
      page: page,
      limit: _pageSize,
      status: status,
      search: search,
    );
    return switch (result) {
      Success(data: final data) => Success(
          _Page(
            rows: [
              for (final item in data.items)
                ReportListRow(
                  id: item.id,
                  module: ReportsCenterModule.assets,
                  title: item.name,
                  subtitle: item.assetNumber,
                  statusLabel: item.status.name,
                  date: item.updatedAt ?? item.createdAt,
                  meta: item.customer,
                  route: RoutePaths.assetDetail(item.id),
                ),
            ],
            page: data.page,
            hasMore: data.hasMore,
          ),
        ),
      Failure(message: final message, code: final code) =>
        Failure(message, code: code),
    };
  }

  Future<Result<_Page>> _fetchInventory({
    required int page,
    required String? search,
  }) async {
    final status = _stockStatus(state.statusKey);
    final result = await _listSpareParts(
      page: page,
      limit: _pageSize,
      search: search,
      stockStatus: status,
    );
    return switch (result) {
      Success(data: final data) => Success(
          _Page(
            rows: [
              for (final item in data.items)
                ReportListRow(
                  id: item.id,
                  module: ReportsCenterModule.inventory,
                  title: item.name,
                  subtitle: item.partNumber,
                  statusLabel: item.stockStatus.name,
                  date: item.updatedAt ?? item.createdAt,
                  meta: item.category,
                  route: RoutePaths.inventoryPartDetail(item.id),
                ),
            ],
            page: data.page,
            hasMore: data.hasMore,
          ),
        ),
      Failure(message: final message, code: final code) =>
        Failure(message, code: code),
    };
  }

  Future<Result<_Page>> _fetchPm({
    required int page,
    required String? search,
  }) async {
    final status = _pmStatus(state.statusKey);
    final result = await _listPmPlans(
      page: page,
      limit: _pageSize,
      search: search,
      status: status,
    );
    return switch (result) {
      Success(data: final data) => Success(
          _Page(
            rows: [
              for (final item in data.items)
                ReportListRow(
                  id: item.id,
                  module: ReportsCenterModule.pm,
                  title: item.name,
                  subtitle: item.code,
                  statusLabel: item.status.name,
                  date: item.nextDueDate ?? item.updatedAt ?? item.createdAt,
                  meta: item.asset?.name,
                  route: RoutePaths.pmPlanDetail(item.id),
                ),
            ],
            page: data.page,
            hasMore: data.hasMore,
          ),
        ),
      Failure(message: final message, code: final code) =>
        Failure(message, code: code),
    };
  }

  Future<Result<_Page>> _fetchServiceReports({
    required int page,
    required String? search,
  }) async {
    final status = _serviceReportStatus(state.statusKey);
    final result = await _listServiceReports(
      page: page,
      limit: _pageSize,
      search: search,
      status: status,
    );
    return switch (result) {
      Success(data: final data) => Success(
          _Page(
            rows: [
              for (final item in data.items)
                ReportListRow(
                  id: item.id,
                  module: ReportsCenterModule.serviceReports,
                  title: item.reportNumber,
                  subtitle: item.workOrder.jobTitle,
                  statusLabel: item.status.name,
                  date: item.generatedAt ?? item.createdAt,
                  meta: item.workOrder.customerName,
                  route: RoutePaths.reportDetail(item.id),
                ),
            ],
            page: data.page,
            hasMore: data.hasMore,
          ),
        ),
      Failure(message: final message, code: final code) =>
        Failure(message, code: code),
    };
  }

  AttendanceStatus? _attendanceStatus(String? key) {
    if (key == null) return null;
    for (final value in AttendanceStatus.values) {
      if (value.name == key) return value;
    }
    return null;
  }

  OvertimeStatus? _overtimeStatus(String? key) {
    if (key == null) return null;
    for (final value in OvertimeStatus.values) {
      if (value.name == key) return value;
    }
    return null;
  }

  WorkOrderStatus? _workOrderStatus(String? key) {
    if (key == null) return null;
    for (final value in WorkOrderStatus.values) {
      if (value.name == key) return value;
    }
    return null;
  }

  AssetStatus? _assetStatus(String? key) {
    if (key == null) return null;
    for (final value in AssetStatus.values) {
      if (value.name == key) return value;
    }
    return null;
  }

  StockStatus? _stockStatus(String? key) {
    if (key == null) return null;
    for (final value in StockStatus.values) {
      if (value.name == key) return value;
    }
    return null;
  }

  PmPlanStatus? _pmStatus(String? key) {
    if (key == null) return null;
    for (final value in PmPlanStatus.values) {
      if (value.name == key) return value;
    }
    return null;
  }

  ServiceReportStatus? _serviceReportStatus(String? key) {
    if (key == null) return null;
    for (final value in ServiceReportStatus.values) {
      if (value.name == key) return value;
    }
    return null;
  }
}

class _Page {
  const _Page({
    required this.rows,
    required this.page,
    required this.hasMore,
  });

  final List<ReportListRow> rows;
  final int page;
  final bool hasMore;
}
