import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/inventory/domain/usecases/spare_part_usecases.dart';

enum SparePartFormStatus { initial, loading, saving, success, failure }

class SparePartFormState extends Equatable {
  const SparePartFormState({
    this.status = SparePartFormStatus.initial,
    this.part,
    this.message,
  });

  final SparePartFormStatus status;
  final SparePart? part;
  final String? message;

  bool get isEditing => part != null;

  SparePartFormState copyWith({
    SparePartFormStatus? status,
    SparePart? part,
    String? message,
  }) {
    return SparePartFormState(
      status: status ?? this.status,
      part: part ?? this.part,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, part, message];
}

class SparePartFormCubit extends Cubit<SparePartFormState> {
  SparePartFormCubit({
    required CreateSparePartUseCase create,
    required UpdateSparePartUseCase update,
    required GetSparePartByIdUseCase getById,
    String? partId,
  })  : _create = create,
        _update = update,
        _getById = getById,
        _partId = partId,
        super(const SparePartFormState());

  final CreateSparePartUseCase _create;
  final UpdateSparePartUseCase _update;
  final GetSparePartByIdUseCase _getById;
  final String? _partId;

  Future<void> load() async {
    final partId = _partId;
    if (partId == null || partId.isEmpty) {
      emit(const SparePartFormState(status: SparePartFormStatus.success));
      return;
    }

    emit(state.copyWith(status: SparePartFormStatus.loading));
    final result = await _getById(partId);
    switch (result) {
      case Success(data: final part):
        emit(
          SparePartFormState(
            status: SparePartFormStatus.success,
            part: part,
          ),
        );
      case Failure(message: final message):
        emit(
          SparePartFormState(
            status: SparePartFormStatus.failure,
            message: message,
          ),
        );
    }
  }

  Future<Result<SparePart>> save(SparePartUpsertInput input) async {
    emit(state.copyWith(status: SparePartFormStatus.saving));
    final partId = _partId;
    final result = (partId == null || partId.isEmpty)
        ? await _create(input)
        : await _update(partId, input);

    switch (result) {
      case Success(data: final part):
        emit(
          SparePartFormState(
            status: SparePartFormStatus.success,
            part: part,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: SparePartFormStatus.success,
            message: message,
          ),
        );
    }
    return result;
  }
}
