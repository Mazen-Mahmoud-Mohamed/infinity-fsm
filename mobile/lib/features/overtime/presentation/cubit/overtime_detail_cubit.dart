import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/usecases/approve_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_overtime_by_id_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/reject_overtime_usecase.dart';

enum OvertimeDetailStatus { initial, loading, success, failure }

enum ReviewAction { approve, reject }

class OvertimeDetailState extends Equatable {
  const OvertimeDetailState({
    this.status = OvertimeDetailStatus.initial,
    this.session,
    this.reviewAction,
    this.message,
    this.isError = false,
  });

  final OvertimeDetailStatus status;
  final OvertimeSession? session;
  final ReviewAction? reviewAction;
  final String? message;
  final bool isError;

  bool get isBusy => reviewAction != null;
  bool get isApproving => reviewAction == ReviewAction.approve;
  bool get isRejecting => reviewAction == ReviewAction.reject;

  OvertimeDetailState copyWith({
    OvertimeDetailStatus? status,
    OvertimeSession? session,
    ReviewAction? reviewAction,
    bool clearReviewAction = false,
    String? message,
    bool? isError,
    bool clearMessage = false,
  }) {
    return OvertimeDetailState(
      status: status ?? this.status,
      session: session ?? this.session,
      reviewAction:
          clearReviewAction ? null : (reviewAction ?? this.reviewAction),
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        session,
        reviewAction,
        message,
        isError,
      ];
}

class OvertimeDetailCubit extends Cubit<OvertimeDetailState> {
  OvertimeDetailCubit({
    required GetOvertimeByIdUseCase getById,
    required ApproveOvertimeUseCase approve,
    required RejectOvertimeUseCase reject,
    required this.sessionId,
  })  : _getById = getById,
        _approve = approve,
        _reject = reject,
        super(const OvertimeDetailState());

  final GetOvertimeByIdUseCase _getById;
  final ApproveOvertimeUseCase _approve;
  final RejectOvertimeUseCase _reject;
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
    if (state.isBusy || state.session == null) {
      return;
    }

    emit(
      state.copyWith(
        reviewAction: ReviewAction.approve,
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
        emit(
          OvertimeDetailState(
            status: OvertimeDetailStatus.success,
            session: session,
            message: 'overtimeApprovedMessage',
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
        emit(
          OvertimeDetailState(
            status: OvertimeDetailStatus.success,
            session: session,
            message: 'overtimeRejectedMessage',
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
}
