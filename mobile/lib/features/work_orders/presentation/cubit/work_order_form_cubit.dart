import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/organization/domain/entities/user_summary.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/usecases/create_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/get_work_order_by_id_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/update_work_order_usecase.dart';

enum WorkOrderFormStatus { initial, loading, ready, saving, success, failure }

class WorkOrderFormState extends Equatable {
  const WorkOrderFormState({
    this.status = WorkOrderFormStatus.initial,
    this.existing,
    this.technicians = const [],
    this.jobTitle = '',
    this.customerName = '',
    this.locationLabel = '',
    this.description = '',
    this.notes = '',
    this.priority = WorkOrderPriority.medium,
    this.scheduledAt,
    this.assignedTechnicianId,
    this.pendingAttachments = const [],
    this.existingAttachments = const [],
    this.message,
    this.isError = false,
  });

  final WorkOrderFormStatus status;
  final WorkOrder? existing;
  final List<UserSummary> technicians;
  final String jobTitle;
  final String customerName;
  final String locationLabel;
  final String description;
  final String notes;
  final WorkOrderPriority priority;
  final DateTime? scheduledAt;
  final String? assignedTechnicianId;
  final List<WorkOrderAttachmentInput> pendingAttachments;
  final List<WorkOrderAttachment> existingAttachments;
  final String? message;
  final bool isError;

  bool get isEditing => existing != null;

  WorkOrderFormState copyWith({
    WorkOrderFormStatus? status,
    WorkOrder? existing,
    List<UserSummary>? technicians,
    String? jobTitle,
    String? customerName,
    String? locationLabel,
    String? description,
    String? notes,
    WorkOrderPriority? priority,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    String? assignedTechnicianId,
    bool clearAssignedTechnicianId = false,
    List<WorkOrderAttachmentInput>? pendingAttachments,
    List<WorkOrderAttachment>? existingAttachments,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return WorkOrderFormState(
      status: status ?? this.status,
      existing: existing ?? this.existing,
      technicians: technicians ?? this.technicians,
      jobTitle: jobTitle ?? this.jobTitle,
      customerName: customerName ?? this.customerName,
      locationLabel: locationLabel ?? this.locationLabel,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
      assignedTechnicianId: clearAssignedTechnicianId
          ? null
          : (assignedTechnicianId ?? this.assignedTechnicianId),
      pendingAttachments: pendingAttachments ?? this.pendingAttachments,
      existingAttachments: existingAttachments ?? this.existingAttachments,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        existing,
        technicians,
        jobTitle,
        customerName,
        locationLabel,
        description,
        notes,
        priority,
        scheduledAt,
        assignedTechnicianId,
        pendingAttachments,
        existingAttachments,
        message,
        isError,
      ];
}

class WorkOrderFormCubit extends Cubit<WorkOrderFormState> {
  WorkOrderFormCubit({
    required CreateWorkOrderUseCase create,
    required UpdateWorkOrderUseCase update,
    required GetWorkOrderByIdUseCase getById,
    required OrganizationRepository organizationRepository,
    this.workOrderId,
  })  : _create = create,
        _update = update,
        _getById = getById,
        _organizationRepository = organizationRepository,
        super(const WorkOrderFormState());

  final CreateWorkOrderUseCase _create;
  final UpdateWorkOrderUseCase _update;
  final GetWorkOrderByIdUseCase _getById;
  final OrganizationRepository _organizationRepository;
  final String? workOrderId;

  Future<void> load() async {
    emit(state.copyWith(status: WorkOrderFormStatus.loading, clearMessage: true));

    final usersResult = await _organizationRepository.getUsers();
    final technicians = switch (usersResult) {
      Success(data: final users) => users
          .where(
            (user) => user.roles.any(
              (role) => role.toUpperCase().contains('TECHNICIAN'),
            ),
          )
          .toList(),
      Failure() => <UserSummary>[],
    };

    if (workOrderId == null) {
      emit(
        state.copyWith(
          status: WorkOrderFormStatus.ready,
          technicians: technicians.isEmpty
              ? (switch (usersResult) {
                  Success(data: final users) => users,
                  Failure() => const <UserSummary>[],
                })
              : technicians,
        ),
      );
      return;
    }

    final result = await _getById(workOrderId!);
    switch (result) {
      case Success(data: final workOrder):
        emit(
          state.copyWith(
            status: WorkOrderFormStatus.ready,
            existing: workOrder,
            technicians: technicians.isEmpty
                ? (switch (usersResult) {
                    Success(data: final users) => users,
                    Failure() => const <UserSummary>[],
                  })
                : technicians,
            jobTitle: workOrder.jobTitle,
            customerName: workOrder.customerName ?? '',
            locationLabel: workOrder.locationLabel ?? '',
            description: workOrder.description ?? '',
            notes: workOrder.notes ?? '',
            priority: workOrder.priority,
            scheduledAt: workOrder.scheduledAt,
            assignedTechnicianId: workOrder.assignedTechnicianId,
            existingAttachments: workOrder.attachments,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: WorkOrderFormStatus.failure,
            message: message,
            isError: true,
          ),
        );
    }
  }

  void updateField({
    String? jobTitle,
    String? customerName,
    String? locationLabel,
    String? description,
    String? notes,
    WorkOrderPriority? priority,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    String? assignedTechnicianId,
    bool clearAssignedTechnicianId = false,
  }) {
    emit(
      state.copyWith(
        jobTitle: jobTitle,
        customerName: customerName,
        locationLabel: locationLabel,
        description: description,
        notes: notes,
        priority: priority,
        scheduledAt: scheduledAt,
        clearScheduledAt: clearScheduledAt,
        assignedTechnicianId: assignedTechnicianId,
        clearAssignedTechnicianId: clearAssignedTechnicianId,
      ),
    );
  }

  void addAttachment(WorkOrderAttachmentInput input) {
    emit(
      state.copyWith(
        pendingAttachments: [...state.pendingAttachments, input],
      ),
    );
  }

  void removePendingAttachment(int index) {
    final next = [...state.pendingAttachments]..removeAt(index);
    emit(state.copyWith(pendingAttachments: next));
  }

  void removeExistingAttachment(String url) {
    emit(
      state.copyWith(
        existingAttachments:
            state.existingAttachments.where((item) => item.url != url).toList(),
      ),
    );
  }

  Future<void> submit() async {
    final title = state.jobTitle.trim();
    if (title.isEmpty) {
      emit(
        state.copyWith(
          message: 'workOrderJobTitleRequired',
          isError: true,
        ),
      );
      return;
    }

    if (title.length > 200) {
      emit(
        state.copyWith(
          message: 'workOrderJobTitleMaxLength',
          isError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(status: WorkOrderFormStatus.saving, clearMessage: true));

    final input = WorkOrderUpsertInput(
      jobTitle: title,
      customerName: state.customerName.trim().isEmpty
          ? null
          : state.customerName.trim(),
      locationLabel: state.locationLabel.trim().isEmpty
          ? null
          : state.locationLabel.trim(),
      description:
          state.description.trim().isEmpty ? null : state.description.trim(),
      notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
      priority: state.priority,
      scheduledAt: state.scheduledAt,
      assignedTechnicianId: state.assignedTechnicianId,
      attachments: state.pendingAttachments,
      replaceAttachments: state.isEditing,
      keepAttachmentUrls:
          state.existingAttachments.map((item) => item.url).toList(),
    );

    final result = state.isEditing
        ? await _update(state.existing!.id, input)
        : await _create(input);

    switch (result) {
      case Success(data: final workOrder):
        emit(
          state.copyWith(
            status: WorkOrderFormStatus.success,
            existing: workOrder,
            message: state.isEditing
                ? 'workOrderUpdated'
                : 'workOrderCreated',
            isError: false,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: WorkOrderFormStatus.ready,
            message: message,
            isError: true,
          ),
        );
    }
  }
}
