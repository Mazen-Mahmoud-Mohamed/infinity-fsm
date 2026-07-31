import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';
import 'package:mobile/features/service_reports/domain/usecases/service_reports_usecases.dart';

enum ServiceReportsDashboardStatus { initial, loading, success, failure }

class ServiceReportsDashboardState extends Equatable {
  const ServiceReportsDashboardState({
    this.status = ServiceReportsDashboardStatus.initial,
    this.dashboard,
    this.message,
    this.isRefreshing = false,
  });

  final ServiceReportsDashboardStatus status;
  final ServiceReportsDashboard? dashboard;
  final String? message;
  final bool isRefreshing;

  ServiceReportsDashboardState copyWith({
    ServiceReportsDashboardStatus? status,
    ServiceReportsDashboard? dashboard,
    String? message,
    bool? isRefreshing,
  }) {
    return ServiceReportsDashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, message, isRefreshing];
}

class ServiceReportsDashboardCubit extends Cubit<ServiceReportsDashboardState> {
  ServiceReportsDashboardCubit({
    required GetServiceReportsDashboardUseCase getDashboard,
    required SessionQueryCache queryCache,
  })  : _getDashboard = getDashboard,
        _queryCache = queryCache,
        super(const ServiceReportsDashboardState());

  static const _cacheKey = 'reports:dashboard';

  final GetServiceReportsDashboardUseCase _getDashboard;
  final SessionQueryCache _queryCache;

  Future<void> load() async {
    final cached = _queryCache.get<ServiceReportsDashboard>(_cacheKey);
    if (cached != null) {
      emit(ServiceReportsDashboardState(
        status: ServiceReportsDashboardStatus.success,
        dashboard: cached,
        isRefreshing: true,
      ));
    } else if (state.dashboard != null) {
      emit(state.copyWith(
        status: ServiceReportsDashboardStatus.success,
        isRefreshing: true,
      ));
    } else {
      emit(const ServiceReportsDashboardState(
        status: ServiceReportsDashboardStatus.loading,
      ));
    }

    final result = await _getDashboard();
    switch (result) {
      case Success(data: final data):
        _queryCache.set(_cacheKey, data);
        emit(ServiceReportsDashboardState(
          status: ServiceReportsDashboardStatus.success,
          dashboard: data,
        ));
      case Failure(message: final message):
        if (state.dashboard != null) {
          emit(ServiceReportsDashboardState(
            status: ServiceReportsDashboardStatus.success,
            dashboard: state.dashboard,
            message: message,
          ));
        } else {
          emit(ServiceReportsDashboardState(
            status: ServiceReportsDashboardStatus.failure,
            message: message,
          ));
        }
    }
  }
}

enum ServiceReportsListStatus { initial, loading, loadingMore, success, failure }

class ServiceReportsListState extends Equatable {
  const ServiceReportsListState({
    this.status = ServiceReportsListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.filterStatus,
    this.message,
    this.isRefreshing = false,
  });

  final ServiceReportsListStatus status;
  final List<ServiceReport> items;
  final int page;
  final bool hasMore;
  final String search;
  final ServiceReportStatus? filterStatus;
  final String? message;
  final bool isRefreshing;

  ServiceReportsListState copyWith({
    ServiceReportsListStatus? status,
    List<ServiceReport>? items,
    int? page,
    bool? hasMore,
    String? search,
    ServiceReportStatus? filterStatus,
    bool clearFilterStatus = false,
    String? message,
    bool? isRefreshing,
  }) {
    return ServiceReportsListState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, page, hasMore, search, filterStatus, message, isRefreshing];
}

class ServiceReportsListCubit extends Cubit<ServiceReportsListState> {
  ServiceReportsListCubit({
    required ListServiceReportsUseCase listReports,
    required SessionQueryCache queryCache,
  })  : _listReports = listReports,
        _queryCache = queryCache,
        super(const ServiceReportsListState());

  static const int _pageSize = 20;
  final ListServiceReportsUseCase _listReports;
  final SessionQueryCache _queryCache;

  String _cacheKey({
    required String search,
    ServiceReportStatus? status,
  }) =>
      'reports:list:p1:s=$search:st=${status?.apiValue ?? ''}';

  Future<void> loadFirstPage({
    String? search,
    ServiceReportStatus? status,
    bool clearStatus = false,
  }) async {
    final nextSearch = search ?? state.search;
    final nextStatus = clearStatus ? null : (status ?? state.filterStatus);
    final key = _cacheKey(search: nextSearch, status: nextStatus);
    final cached = _queryCache.get<ServiceReportPage>(key);

    if (cached != null) {
      emit(ServiceReportsListState(
        status: ServiceReportsListStatus.success,
        items: cached.items,
        page: cached.page,
        hasMore: cached.hasMore,
        search: nextSearch,
        filterStatus: nextStatus,
        isRefreshing: true,
      ));
    } else if (state.items.isNotEmpty) {
      emit(state.copyWith(
        status: ServiceReportsListStatus.success,
        search: nextSearch,
        filterStatus: nextStatus,
        clearFilterStatus: nextStatus == null,
        isRefreshing: true,
      ));
    } else {
      emit(ServiceReportsListState(
        status: ServiceReportsListStatus.loading,
        search: nextSearch,
        filterStatus: nextStatus,
      ));
    }

    final result = await _listReports(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
      status: nextStatus,
    );
    switch (result) {
      case Success(data: final page):
        _queryCache.set(key, page);
        emit(ServiceReportsListState(
          status: ServiceReportsListStatus.success,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          search: nextSearch,
          filterStatus: nextStatus,
        ));
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(state.copyWith(
            status: ServiceReportsListStatus.success,
            search: nextSearch,
            filterStatus: nextStatus,
            clearFilterStatus: nextStatus == null,
            message: message,
            isRefreshing: false,
          ));
        } else {
          emit(ServiceReportsListState(
            status: ServiceReportsListStatus.failure,
            search: nextSearch,
            filterStatus: nextStatus,
            message: message,
          ));
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == ServiceReportsListStatus.loading ||
        state.status == ServiceReportsListStatus.loadingMore ||
        state.isRefreshing) {
      return;
    }
    emit(state.copyWith(status: ServiceReportsListStatus.loadingMore));
    final result = await _listReports(
      page: state.page + 1,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
      status: state.filterStatus,
    );
    switch (result) {
      case Success(data: final page):
        emit(state.copyWith(
          status: ServiceReportsListStatus.success,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          status: ServiceReportsListStatus.success,
          message: message,
        ));
    }
  }

  Future<void> setFilter(ServiceReportStatus? status) =>
      loadFirstPage(status: status, clearStatus: status == null);

  Future<void> search(String value) => loadFirstPage(search: value);
}

enum ServiceReportDetailStatus { initial, loading, success, failure }

class ServiceReportDetailState extends Equatable {
  const ServiceReportDetailState({
    this.status = ServiceReportDetailStatus.initial,
    this.report,
    this.message,
    this.downloading = false,
    this.isRefreshing = false,
  });

  final ServiceReportDetailStatus status;
  final ServiceReport? report;
  final String? message;
  final bool downloading;
  final bool isRefreshing;

  @override
  List<Object?> get props =>
      [status, report, message, downloading, isRefreshing];
}

class ServiceReportDetailCubit extends Cubit<ServiceReportDetailState> {
  ServiceReportDetailCubit({
    required String reportId,
    required GetServiceReportByIdUseCase getById,
    required DownloadServiceReportUseCase download,
    required SessionQueryCache queryCache,
  })  : _reportId = reportId,
        _getById = getById,
        _download = download,
        _queryCache = queryCache,
        super(const ServiceReportDetailState());

  final String _reportId;
  final GetServiceReportByIdUseCase _getById;
  final DownloadServiceReportUseCase _download;
  final SessionQueryCache _queryCache;

  String get _cacheKey => 'reports:detail:$_reportId';

  Future<void> load() async {
    final cached = _queryCache.get<ServiceReport>(_cacheKey);
    if (cached != null) {
      emit(ServiceReportDetailState(
        status: ServiceReportDetailStatus.success,
        report: cached,
        isRefreshing: true,
      ));
    } else if (state.report != null) {
      emit(ServiceReportDetailState(
        status: ServiceReportDetailStatus.success,
        report: state.report,
        isRefreshing: true,
      ));
    } else {
      emit(const ServiceReportDetailState(
        status: ServiceReportDetailStatus.loading,
      ));
    }

    final result = await _getById(_reportId);
    switch (result) {
      case Success(data: final report):
        _queryCache.set(_cacheKey, report);
        emit(ServiceReportDetailState(
          status: ServiceReportDetailStatus.success,
          report: report,
        ));
      case Failure(message: final message):
        if (state.report != null) {
          emit(ServiceReportDetailState(
            status: ServiceReportDetailStatus.success,
            report: state.report,
            message: message,
          ));
        } else {
          emit(ServiceReportDetailState(
            status: ServiceReportDetailStatus.failure,
            message: message,
          ));
        }
    }
  }

  Future<Result<ServiceReportDownload>> download() async {
    emit(ServiceReportDetailState(
      status: state.status,
      report: state.report,
      downloading: true,
    ));
    final result = await _download(_reportId);
    switch (result) {
      case Success(data: final data):
        _queryCache.set(_cacheKey, data.report);
        emit(ServiceReportDetailState(
          status: ServiceReportDetailStatus.success,
          report: data.report,
        ));
      case Failure(message: final message):
        emit(ServiceReportDetailState(
          status: ServiceReportDetailStatus.success,
          report: state.report,
          message: message,
        ));
    }
    return result;
  }
}

enum SignatureCaptureStatus { initial, saving, success, failure }

class SignatureCaptureState extends Equatable {
  const SignatureCaptureState({
    this.status = SignatureCaptureStatus.initial,
    this.signature,
    this.message,
  });

  final SignatureCaptureStatus status;
  final CustomerSignature? signature;
  final String? message;

  @override
  List<Object?> get props => [status, signature, message];
}

class SignatureCaptureCubit extends Cubit<SignatureCaptureState> {
  SignatureCaptureCubit({required CreateCustomerSignatureUseCase create})
      : _create = create,
        super(const SignatureCaptureState());

  final CreateCustomerSignatureUseCase _create;

  Future<Result<CustomerSignature>> save(CreateSignatureInput input) async {
    emit(const SignatureCaptureState(status: SignatureCaptureStatus.saving));
    final result = await _create(input);
    switch (result) {
      case Success(data: final signature):
        emit(SignatureCaptureState(
          status: SignatureCaptureStatus.success,
          signature: signature,
        ));
      case Failure(message: final message):
        emit(SignatureCaptureState(
          status: SignatureCaptureStatus.failure,
          message: message,
        ));
    }
    return result;
  }
}

enum GenerateReportStatus { initial, loadingSignatures, generating, success, failure }

class GenerateReportState extends Equatable {
  const GenerateReportState({
    this.status = GenerateReportStatus.initial,
    this.signatures = const [],
    this.report,
    this.message,
  });

  final GenerateReportStatus status;
  final List<CustomerSignature> signatures;
  final ServiceReport? report;
  final String? message;

  @override
  List<Object?> get props => [status, signatures, report, message];
}

class GenerateReportCubit extends Cubit<GenerateReportState> {
  GenerateReportCubit({
    required ListCustomerSignaturesUseCase listSignatures,
    required GenerateServiceReportUseCase generate,
  })  : _listSignatures = listSignatures,
        _generate = generate,
        super(const GenerateReportState());

  final ListCustomerSignaturesUseCase _listSignatures;
  final GenerateServiceReportUseCase _generate;

  Future<void> loadSignatures() async {
    emit(const GenerateReportState(status: GenerateReportStatus.loadingSignatures));
    final result = await _listSignatures(page: 1, limit: 50);
    switch (result) {
      case Success(data: final page):
        emit(GenerateReportState(
          status: GenerateReportStatus.success,
          signatures: page.items,
        ));
      case Failure(message: final message):
        emit(GenerateReportState(
          status: GenerateReportStatus.failure,
          message: message,
        ));
    }
  }

  Future<Result<ServiceReport>> generate(GenerateServiceReportInput input) async {
    emit(GenerateReportState(
      status: GenerateReportStatus.generating,
      signatures: state.signatures,
    ));
    final result = await _generate(input);
    switch (result) {
      case Success(data: final report):
        emit(GenerateReportState(
          status: GenerateReportStatus.success,
          signatures: state.signatures,
          report: report,
        ));
      case Failure(message: final message):
        emit(GenerateReportState(
          status: GenerateReportStatus.failure,
          signatures: state.signatures,
          message: message,
        ));
    }
    return result;
  }
}
