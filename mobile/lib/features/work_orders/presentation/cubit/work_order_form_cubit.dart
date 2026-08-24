import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/organization/domain/entities/user_summary.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_voice_draft.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/usecases/create_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/get_work_order_by_id_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/update_work_order_usecase.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_location_launcher.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_phone_numbers.dart';

enum WorkOrderFormStatus { initial, loading, ready, saving, success, failure }

/// Soft cap aligned with backend multipart maxCount for attachments.
const int kWorkOrderMaxAttachments = 20;

class WorkOrderFormState extends Equatable {
  const WorkOrderFormState({
    this.status = WorkOrderFormStatus.initial,
    this.existing,
    this.technicians = const [],
    this.jobTitle = '',
    this.customerName = '',
    this.customerPhoneNumbers = const [],
    this.locationUrl = '',
    this.legacyLocationLabel = '',
    this.notes = '',
    this.priority = WorkOrderPriority.medium,
    this.scheduledAt,
    this.assignedTechnicianIds = const [],
    this.pendingAttachments = const [],
    this.existingAttachments = const [],
    this.existingVoiceNote,
    this.voiceDraft,
    this.clearVoiceNote = false,
    this.message,
    this.isError = false,
  });

  final WorkOrderFormStatus status;
  final WorkOrder? existing;
  final List<UserSummary> technicians;
  final String jobTitle;
  final String customerName;
  final List<String> customerPhoneNumbers;
  final String locationUrl;
  /// Non-URL legacy location text (shown as helper; not edited in URL field).
  final String legacyLocationLabel;
  final String notes;
  final WorkOrderPriority priority;
  final DateTime? scheduledAt;
  final List<String> assignedTechnicianIds;
  final List<WorkOrderAttachmentInput> pendingAttachments;
  final List<WorkOrderAttachment> existingAttachments;
  final WorkOrderVoiceNote? existingVoiceNote;
  final OvertimeVoiceDraft? voiceDraft;
  final bool clearVoiceNote;
  final String? message;
  final bool isError;

  bool get isEditing => existing != null;

  int get totalAttachmentCount =>
      existingAttachments.length + pendingAttachments.length;

  bool get canAddMoreAttachments =>
      totalAttachmentCount < kWorkOrderMaxAttachments;

  WorkOrderFormState copyWith({
    WorkOrderFormStatus? status,
    WorkOrder? existing,
    List<UserSummary>? technicians,
    String? jobTitle,
    String? customerName,
    List<String>? customerPhoneNumbers,
    String? locationUrl,
    String? legacyLocationLabel,
    String? notes,
    WorkOrderPriority? priority,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    List<String>? assignedTechnicianIds,
    List<WorkOrderAttachmentInput>? pendingAttachments,
    List<WorkOrderAttachment>? existingAttachments,
    WorkOrderVoiceNote? existingVoiceNote,
    bool clearExistingVoiceNote = false,
    OvertimeVoiceDraft? voiceDraft,
    bool clearVoiceDraft = false,
    bool? clearVoiceNote,
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
      customerPhoneNumbers:
          customerPhoneNumbers ?? this.customerPhoneNumbers,
      locationUrl: locationUrl ?? this.locationUrl,
      legacyLocationLabel: legacyLocationLabel ?? this.legacyLocationLabel,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
      assignedTechnicianIds:
          assignedTechnicianIds ?? this.assignedTechnicianIds,
      pendingAttachments: pendingAttachments ?? this.pendingAttachments,
      existingAttachments: existingAttachments ?? this.existingAttachments,
      existingVoiceNote: clearExistingVoiceNote
          ? null
          : (existingVoiceNote ?? this.existingVoiceNote),
      voiceDraft: clearVoiceDraft ? null : (voiceDraft ?? this.voiceDraft),
      clearVoiceNote: clearVoiceNote ?? this.clearVoiceNote,
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
        customerPhoneNumbers,
        locationUrl,
        legacyLocationLabel,
        notes,
        priority,
        scheduledAt,
        assignedTechnicianIds,
        pendingAttachments,
        existingAttachments,
        existingVoiceNote,
        voiceDraft,
        clearVoiceNote,
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
        final url = workOrder.effectiveLocationUrl ?? '';
        final legacyLabel = (workOrder.locationLabel ?? '').trim();
        final showLegacy = legacyLabel.isNotEmpty &&
            !WorkOrderLocationLauncher.isValidHttpUrl(legacyLabel);
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
            customerPhoneNumbers: workOrder.customerPhoneNumbers,
            locationUrl: url,
            legacyLocationLabel: showLegacy ? legacyLabel : '',
            notes: workOrder.notes ?? '',
            priority: workOrder.priority,
            scheduledAt: workOrder.scheduledAt,
            assignedTechnicianIds: workOrder.effectiveAssigneeIds,
            existingAttachments: workOrder.attachments,
            existingVoiceNote: workOrder.voiceNote,
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
    String? locationUrl,
    String? notes,
    WorkOrderPriority? priority,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
  }) {
    emit(
      state.copyWith(
        jobTitle: jobTitle,
        customerName: customerName,
        locationUrl: locationUrl,
        notes: notes,
        priority: priority,
        scheduledAt: scheduledAt,
        clearScheduledAt: clearScheduledAt,
      ),
    );
  }

  void addPhoneNumberRow() {
    if (state.customerPhoneNumbers.length >= WorkOrderPhoneNumbers.maxCount) {
      emit(
        state.copyWith(
          message: 'workOrderMaxCustomerPhonesReached',
          isError: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        customerPhoneNumbers: [...state.customerPhoneNumbers, ''],
        clearMessage: true,
        isError: false,
      ),
    );
  }

  void updatePhoneNumberAt(int index, String value) {
    if (index < 0 || index >= state.customerPhoneNumbers.length) {
      return;
    }
    final next = [...state.customerPhoneNumbers];
    next[index] = value;
    emit(state.copyWith(customerPhoneNumbers: next));
  }

  void removePhoneNumberAt(int index) {
    if (index < 0 || index >= state.customerPhoneNumbers.length) {
      return;
    }
    final next = [...state.customerPhoneNumbers]..removeAt(index);
    emit(state.copyWith(customerPhoneNumbers: next));
  }

  void toggleTechnician(String technicianId) {
    final current = [...state.assignedTechnicianIds];
    if (current.contains(technicianId)) {
      current.remove(technicianId);
    } else {
      current.add(technicianId);
    }
    emit(state.copyWith(assignedTechnicianIds: current));
  }

  void removeTechnician(String technicianId) {
    emit(
      state.copyWith(
        assignedTechnicianIds: state.assignedTechnicianIds
            .where((id) => id != technicianId)
            .toList(),
      ),
    );
  }

  void addAttachment(WorkOrderAttachmentInput input) {
    if (!state.canAddMoreAttachments) {
      emit(
        state.copyWith(
          message: 'workOrderMaxAttachmentsReached',
          isError: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        pendingAttachments: [...state.pendingAttachments, input],
        clearMessage: true,
        isError: false,
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

  void setVoiceDraft(OvertimeVoiceDraft? draft) {
    emit(
      state.copyWith(
        voiceDraft: draft,
        clearVoiceDraft: draft == null,
        clearVoiceNote: draft != null ? false : state.clearVoiceNote,
      ),
    );
  }

  void clearExistingVoiceNote() {
    emit(
      state.copyWith(
        clearExistingVoiceNote: true,
        clearVoiceDraft: true,
        clearVoiceNote: true,
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

    final locationUrl = state.locationUrl.trim();
    if (locationUrl.isNotEmpty &&
        !WorkOrderLocationLauncher.isValidHttpUrl(locationUrl)) {
      emit(
        state.copyWith(
          message: 'workOrderLocationUrlInvalid',
          isError: true,
        ),
      );
      return;
    }

    final invalidPhone =
        WorkOrderPhoneNumbers.firstInvalid(state.customerPhoneNumbers);
    if (invalidPhone != null) {
      emit(
        state.copyWith(
          message: 'workOrderCustomerPhoneInvalid',
          isError: true,
        ),
      );
      return;
    }

    final phones =
        WorkOrderPhoneNumbers.normalize(state.customerPhoneNumbers);

    emit(state.copyWith(status: WorkOrderFormStatus.saving, clearMessage: true));

    final voiceDraft = state.voiceDraft;
    final voiceExt = () {
      final path = voiceDraft?.filePath ?? '';
      final dot = path.lastIndexOf('.');
      if (dot >= 0 && dot < path.length - 1) {
        return path.substring(dot + 1).toLowerCase();
      }
      return 'm4a';
    }();
    final input = WorkOrderUpsertInput(
      jobTitle: title,
      customerName: state.customerName.trim().isEmpty
          ? null
          : state.customerName.trim(),
      customerPhoneNumbers: phones,
      locationUrl: locationUrl.isEmpty ? null : locationUrl,
      locationLabel: locationUrl.isNotEmpty
          ? locationUrl
          : (state.legacyLocationLabel.trim().isEmpty
              ? null
              : state.legacyLocationLabel.trim()),
      notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
      priority: state.priority,
      scheduledAt: state.scheduledAt,
      assignedTechnicianIds: state.assignedTechnicianIds,
      assignedTechnicianId: state.assignedTechnicianIds.isEmpty
          ? null
          : state.assignedTechnicianIds.first,
      attachments: state.pendingAttachments,
      voiceNoteBytes: voiceDraft?.bytes,
      voiceNoteFileName:
          voiceDraft == null ? null : 'voice-note.$voiceExt',
      voiceNoteMimeType: voiceDraft == null
          ? null
          : (voiceExt == 'mp3'
              ? 'audio/mpeg'
              : voiceExt == 'wav'
                  ? 'audio/wav'
                  : 'audio/mp4'),
      clearVoiceNote: state.clearVoiceNote && voiceDraft == null,
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
            message: state.isEditing ? 'workOrderUpdated' : 'workOrderCreated',
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
