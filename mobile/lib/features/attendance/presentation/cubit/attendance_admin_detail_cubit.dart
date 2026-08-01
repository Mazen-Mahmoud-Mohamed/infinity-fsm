import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_admin_detail.dart';
import 'package:mobile/features/attendance/domain/usecases/get_admin_attendance_detail_usecase.dart';

enum AttendanceAdminDetailStatus { initial, loading, success, failure }

class AttendanceAdminDetailState extends Equatable {
  const AttendanceAdminDetailState({
    this.status = AttendanceAdminDetailStatus.initial,
    this.detail,
    this.message,
    this.isRefreshing = false,
  });

  final AttendanceAdminDetailStatus status;
  final AttendanceAdminDetail? detail;
  final String? message;
  final bool isRefreshing;

  AttendanceAdminDetailState copyWith({
    AttendanceAdminDetailStatus? status,
    AttendanceAdminDetail? detail,
    String? message,
    bool? isRefreshing,
  }) {
    return AttendanceAdminDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, detail, message, isRefreshing];
}

class AttendanceAdminDetailCubit extends Cubit<AttendanceAdminDetailState> {
  AttendanceAdminDetailCubit({
    required GetAdminAttendanceDetailUseCase getDetail,
    required this.attendanceId,
  })  : _getDetail = getDetail,
        super(const AttendanceAdminDetailState());

  final GetAdminAttendanceDetailUseCase _getDetail;
  final String attendanceId;

  Future<void> load({bool silent = false}) async {
    final hasData = state.detail != null;
    if (silent && hasData) {
      emit(state.copyWith(isRefreshing: true, message: null));
    } else {
      emit(
        const AttendanceAdminDetailState(
          status: AttendanceAdminDetailStatus.loading,
        ),
      );
    }

    final result = await _getDetail(attendanceId);
    switch (result) {
      case Success(data: final detail):
        emit(
          AttendanceAdminDetailState(
            status: AttendanceAdminDetailStatus.success,
            detail: detail,
            isRefreshing: false,
          ),
        );
      case Failure(message: final message):
        emit(
          AttendanceAdminDetailState(
            status: hasData
                ? AttendanceAdminDetailStatus.success
                : AttendanceAdminDetailStatus.failure,
            detail: state.detail,
            message: message,
            isRefreshing: false,
          ),
        );
    }
  }
}
