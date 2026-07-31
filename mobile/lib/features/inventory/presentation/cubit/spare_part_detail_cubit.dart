import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/inventory/domain/entities/stock_movement.dart';
import 'package:mobile/features/inventory/domain/entities/warehouse.dart';
import 'package:mobile/features/inventory/domain/usecases/list_warehouses_usecase.dart';
import 'package:mobile/features/inventory/domain/usecases/spare_part_usecases.dart';
import 'package:mobile/features/inventory/domain/usecases/stock_movement_usecases.dart';

enum SparePartDetailStatus { initial, loading, success, failure, mutating }

class SparePartDetailState extends Equatable {
  const SparePartDetailState({
    this.status = SparePartDetailStatus.initial,
    this.part,
    this.warehouses = const [],
    this.message,
  });

  final SparePartDetailStatus status;
  final SparePart? part;
  final List<Warehouse> warehouses;
  final String? message;

  SparePartDetailState copyWith({
    SparePartDetailStatus? status,
    SparePart? part,
    List<Warehouse>? warehouses,
    String? message,
  }) {
    return SparePartDetailState(
      status: status ?? this.status,
      part: part ?? this.part,
      warehouses: warehouses ?? this.warehouses,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, part, warehouses, message];
}

class SparePartDetailCubit extends Cubit<SparePartDetailState> {
  SparePartDetailCubit({
    required String partId,
    required GetSparePartByIdUseCase getById,
    required DeleteSparePartUseCase deletePart,
    required ListWarehousesUseCase listWarehouses,
    required StockInUseCase stockIn,
    required StockOutUseCase stockOut,
    required TransferStockUseCase transfer,
    required AdjustmentStockUseCase adjustment,
  })  : _partId = partId,
        _getById = getById,
        _deletePart = deletePart,
        _listWarehouses = listWarehouses,
        _stockIn = stockIn,
        _stockOut = stockOut,
        _transfer = transfer,
        _adjustment = adjustment,
        super(const SparePartDetailState());

  final String _partId;
  final GetSparePartByIdUseCase _getById;
  final DeleteSparePartUseCase _deletePart;
  final ListWarehousesUseCase _listWarehouses;
  final StockInUseCase _stockIn;
  final StockOutUseCase _stockOut;
  final TransferStockUseCase _transfer;
  final AdjustmentStockUseCase _adjustment;

  Future<void> load() async {
    emit(state.copyWith(status: SparePartDetailStatus.loading));
    final results = await Future.wait([
      _getById(_partId),
      _listWarehouses(page: 1, limit: 100, isActive: true),
    ]);

    final partResult = results[0] as Result<SparePart>;
    final warehousesResult = results[1] as Result<WarehousePage>;

    switch (partResult) {
      case Success(data: final part):
        final warehouses = switch (warehousesResult) {
          Success(data: final page) => page.items,
          Failure() => const <Warehouse>[],
        };
        emit(
          SparePartDetailState(
            status: SparePartDetailStatus.success,
            part: part,
            warehouses: warehouses,
          ),
        );
      case Failure(message: final message):
        emit(
          SparePartDetailState(
            status: SparePartDetailStatus.failure,
            message: message,
          ),
        );
    }
  }

  Future<Result<SparePart>> delete() {
    return _deletePart(_partId);
  }

  Future<Result<StockMovementResult>> stockIn(StockInInput input) async {
    emit(state.copyWith(status: SparePartDetailStatus.mutating));
    final result = await _stockIn(input);
    if (result is Success<StockMovementResult>) {
      emit(
        state.copyWith(
          status: SparePartDetailStatus.success,
          part: result.data.sparePart,
        ),
      );
    } else if (result is Failure<StockMovementResult>) {
      emit(
        state.copyWith(
          status: SparePartDetailStatus.success,
          message: result.message,
        ),
      );
    }
    return result;
  }

  Future<Result<StockMovementResult>> stockOut(StockOutInput input) async {
    emit(state.copyWith(status: SparePartDetailStatus.mutating));
    final result = await _stockOut(input);
    if (result is Success<StockMovementResult>) {
      emit(
        state.copyWith(
          status: SparePartDetailStatus.success,
          part: result.data.sparePart,
        ),
      );
    } else if (result is Failure<StockMovementResult>) {
      emit(
        state.copyWith(
          status: SparePartDetailStatus.success,
          message: result.message,
        ),
      );
    }
    return result;
  }

  Future<Result<StockMovementResult>> transfer(TransferStockInput input) async {
    emit(state.copyWith(status: SparePartDetailStatus.mutating));
    final result = await _transfer(input);
    if (result is Success<StockMovementResult>) {
      emit(
        state.copyWith(
          status: SparePartDetailStatus.success,
          part: result.data.sparePart,
        ),
      );
    } else if (result is Failure<StockMovementResult>) {
      emit(
        state.copyWith(
          status: SparePartDetailStatus.success,
          message: result.message,
        ),
      );
    }
    return result;
  }

  Future<Result<StockMovementResult>> adjustment(AdjustmentInput input) async {
    emit(state.copyWith(status: SparePartDetailStatus.mutating));
    final result = await _adjustment(input);
    if (result is Success<StockMovementResult>) {
      emit(
        state.copyWith(
          status: SparePartDetailStatus.success,
          part: result.data.sparePart,
        ),
      );
    } else if (result is Failure<StockMovementResult>) {
      emit(
        state.copyWith(
          status: SparePartDetailStatus.success,
          message: result.message,
        ),
      );
    }
    return result;
  }
}
