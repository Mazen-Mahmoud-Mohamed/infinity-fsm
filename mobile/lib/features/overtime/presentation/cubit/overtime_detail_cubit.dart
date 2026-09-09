import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/usecases/approve_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_overtime_by_id_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/reject_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_admin_cubit.dart';

enum OvertimeDetailStatus { initial, loading, success, failure }

enum ReviewAction { approve, approvePartial, reject }

class OvertimeDetailState extends Equatable {
  const OvertimeDetailState({
    this.status = OvertimeDetailStatus.initial,
    this.session,
    this.reviewAction,
    this.message,
    this.isError = false,
    this.reviewedSession,
  });

  final OvertimeDetailStatus status;
  final OvertimeSession? session;
  final ReviewAction? reviewAction;
  final String? message;
  final bool isError;

  /// Last successful accept/reject result, used when popping back to the list.
  final OvertimeSession? reviewedSession;

  bool get isBusy => reviewAction != null;
  bool get isApproving => reviewAction == ReviewAction.approve;
  bool get isApprovingPartial => reviewAction == ReviewAction.approvePartial;
  bool get isRejecting => reviewAction == ReviewAction.reject;

  OvertimeDetailState copyWith({
    OvertimeDetailStatus? status,
    OvertimeSession? session,
    ReviewAction? reviewAction,
    bool clearReviewAction = false,
    String? message,
    bool? isError,
    bool clearMessage = false,
    OvertimeSession? reviewedSession,
  }) {
    return OvertimeDetailState(
      status: status ?? this.status,
      session: session ?? this.session,
      reviewAction:
          clearReviewAction ? null : (reviewAction ?? this.reviewAction),
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
      reviewedSession: reviewedSession ?? this.reviewedSession,
    );
  }

  @override
  List<Object?> get props => [
        status,
        session,
        reviewAction,
        message,
        isError,
        reviewedSession,
      ];
}

class OvertimeDetailCubit extends Cubit<OvertimeDetailState> {
  OvertimeDetailCubit({
    required GetOvertimeByIdUseCase getById,
    required ApproveOvertimeUseCase approve,
    required RejectOvertimeUseCase reject,
    required this.sessionId,
    SessionQueryCache? sessionQueryCache,
    OvertimeAdminCubit? adminList,
  })  : _getById = getById,
        _approve = approve,
        _reject = reject,
        _sessionQueryCache = sessionQueryCache,
        _adminList = adminList,
        super(const OvertimeDetailState());

  final GetOvertimeByIdUseCase _getById;
  final ApproveOvertimeUseCase _approve;
  final RejectOvertimeUseCase _reject;
  final SessionQueryCache? _sessionQueryCache;
  final OvertimeAdminCubit? _adminList;
  final String sessionId;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: OvertimeDetailStatus.loading,
        clearReviewAction: true,
        clearMessage: true,
        isError: false,
      ),
    );

    final result = await _getById(sessionId);
    switch (result) {
      case Success(data: final session):
        emit(
          OvertimeDetailState(
            status: OvertimeDetailStatus.success,
            session: session,
          ),
        );
      case Failure(message: final message):
        emit(
          OvertimeDetailState(
            status: OvertimeDetailStatus.failure,
            message: message,
            isError: true,
          ),
        );
    }
  }

  Future<void> approve({String? reviewNotes, double? approvedHours}) async {
    return _submitApprove(
      reviewAction: ReviewAction.approve,
      reviewNotes: reviewNotes,
      approvedHours: approvedHours,
    );
  }

  Future<void> approvePartial({
    String? reviewNotes,
    required double approvedHours,
  }) async {
    return _submitApprove(
      reviewAction: ReviewAction.approvePartial,
      reviewNotes: reviewNotes,
      approvedHours: approvedHours,
    );
  }

  Future<void> _submitApprove({
    required ReviewAction reviewAction,
    String? reviewNotes,
    double? approvedHours,
  }) async {
    if (state.isBusy || state.session == null) {
      return;
    }

    emit(
      state.copyWith(
        reviewAction: reviewAction,
        clearMessage: true,
        isError: false,
      ),
    );

    final result = await _approve(
      sessionId,
      reviewNotes: reviewNotes,
      approvedHours: approvedHours,
    );
    switch (result) {
      case Success(data: final session):
        _syncList(session);
        emit(
          OvertimeDetailState(
            status: OvertimeDetailStatus.success,
            session: session,
            message: 'overtimeApprovedMessage',
            reviewedSession: session,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: OvertimeDetailStatus.success,
            clearReviewAction: true,
            message: message,
            isError: true,
          ),
        );
    }
  }

  Future<void> reject({String? rejectionReason, String? reviewNotes}) async {
    if (state.isBusy || state.session == null) {
      return;
    }

    emit(
      state.copyWith(
        reviewAction: ReviewAction.reject,
        clearMessage: true,
        isError: false,
      ),
    );

    final result = await _reject(
      sessionId,
      rejectionReason: rejectionReason,
      reviewNotes: reviewNotes,
    );
    switch (result) {
      case Success(data: final session):
        _syncList(session);
        emit(
          OvertimeDetailState(
            status: OvertimeDetailStatus.success,
            session: session,
            message: 'overtimeRejectedMessage',
            reviewedSession: session,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: OvertimeDetailStatus.success,
            clearReviewAction: true,
            message: message,
            isError: true,
          ),
        );
    }
  }

  void clearFeedback() {
    if (state.message != null) {
      emit(state.copyWith(clearMessage: true, isError: false));
    }
  }

  void _syncList(OvertimeSession session) {
    final list = _adminList;
    if (list != null && !list.isClosed) {
      list.applyUpdated(session);
      return;
    }
    final cache = _sessionQueryCache;
    if (cache != null) {
      OvertimeAdminCubit.syncReviewedSession(cache, session);
    }
  }
}
