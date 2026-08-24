import 'package:mobile/features/overtime/data/mappers/overtime_json_helpers.dart';
import 'package:mobile/features/work_orders/domain/entities/pending_work_order_action.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';

class WorkOrderModel extends WorkOrder {
  const WorkOrderModel({
    required super.id,
    required super.companyId,
    required super.jobNumber,
    required super.jobTitle,
    required super.priority,
    required super.status,
    super.customerName,
    super.customerAddress,
    super.locationLabel,
    super.locationUrl,
    super.assignedTechnicianId,
    super.assignedTechnicianName,
    super.assignedTechnicianIds = const [],
    super.assignedTechnicianNames = const [],
    super.customerPhoneNumbers = const [],
    super.description,
    super.notes,
    super.voiceNote,
    super.scheduledAt,
    super.attachments = const [],
    super.beforePhotos = const [],
    super.afterPhotos = const [],
    super.progressPhotos = const [],
    super.beforeNotes,
    super.progressNotes = const [],
    super.completionNotes,
    super.startedLocation,
    super.completedLocation,
    super.timeline = const [],
    super.estimatedDurationMinutes,
    super.actualDurationMinutes,
    super.startedAt,
    super.completedAt,
    super.cancelledAt,
    super.cancellationReason,
    super.rejectedAt,
    super.rejectionReason,
    super.acceptedAt,
    super.createdAt,
    super.updatedAt,
  });

  factory WorkOrderModel.fromJson(Map<String, dynamic> json) {
    final addressJson = json['customerAddress'];
    final attachmentsJson = json['attachments'];
    final beforePhotosJson = json['beforePhotos'];
    final afterPhotosJson = json['afterPhotos'];
    final progressPhotosJson = json['progressPhotos'];
    final progressNotesJson = json['progressNotes'];
    final timelineJson = json['timeline'];
    final startedLocJson = json['startedLocation'];
    final completedLocJson = json['completedLocation'];
    final voiceNoteJson = json['voiceNote'];
    final assigneeIdsRaw = json['assignedTechnicianIds'];
    final assigneeNamesRaw = json['assignedTechnicianNames'];
    final phonesRaw = json['customerPhoneNumbers'];

    final assigneeIds = assigneeIdsRaw is List
        ? assigneeIdsRaw
            .map((e) => e?.toString())
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
    final assigneeNames = assigneeNamesRaw is List
        ? assigneeNamesRaw
            .map((e) => e?.toString())
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
    final customerPhoneNumbers = phonesRaw is List
        ? phonesRaw
            .map((e) => e?.toString())
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    return WorkOrderModel(
      id: requireString(json, 'id'),
      companyId: requireString(json, 'companyId'),
      jobNumber: requireString(json, 'jobNumber'),
      jobTitle: requireString(json, 'jobTitle'),
      customerName: optionalString(json, 'customerName'),
      customerPhoneNumbers: customerPhoneNumbers,
      customerAddress: addressJson is Map<String, dynamic>
          ? WorkOrderAddress(
              street: optionalString(addressJson, 'street'),
              city: optionalString(addressJson, 'city'),
              governorate: optionalString(addressJson, 'governorate'),
              lat: _readNullableDouble(addressJson, 'lat'),
              lng: _readNullableDouble(addressJson, 'lng'),
            )
          : null,
      locationLabel: optionalString(json, 'locationLabel'),
      locationUrl: optionalString(json, 'locationUrl'),
      assignedTechnicianId: optionalString(json, 'assignedTechnicianId'),
      assignedTechnicianName: optionalString(json, 'assignedTechnicianName'),
      assignedTechnicianIds: assigneeIds,
      assignedTechnicianNames: assigneeNames,
      priority: WorkOrderPriority.fromApi(
        optionalString(json, 'priority') ?? 'MEDIUM',
      ),
      status: WorkOrderStatus.fromApi(optionalString(json, 'status') ?? 'PENDING'),
      description: optionalString(json, 'description'),
      notes: optionalString(json, 'notes'),
      voiceNote: voiceNoteJson is Map<String, dynamic>
          ? WorkOrderVoiceNote(
              url: requireString(voiceNoteJson, 'url'),
              publicId: optionalString(voiceNoteJson, 'publicId'),
              duration: _readNullableDouble(voiceNoteJson, 'duration'),
              size: _readNullableInt(voiceNoteJson, 'size'),
              format: optionalString(voiceNoteJson, 'format'),
              uploadedAt: parseDateTime(voiceNoteJson['uploadedAt']),
            )
          : null,
      scheduledAt: parseDateTime(json['scheduledAt']),
      attachments: _mapPhotoList(attachmentsJson),
      beforePhotos: _mapPhotoList(beforePhotosJson),
      afterPhotos: _mapPhotoList(afterPhotosJson),
      progressPhotos: _mapPhotoList(progressPhotosJson),
      beforeNotes: optionalString(json, 'beforeNotes'),
      progressNotes: progressNotesJson is List
          ? progressNotesJson
              .whereType<Map<String, dynamic>>()
              .map(_mapProgressNote)
              .toList()
          : const [],
      completionNotes: optionalString(json, 'completionNotes'),
      startedLocation: startedLocJson is Map<String, dynamic>
          ? _mapLocation(startedLocJson)
          : null,
      completedLocation: completedLocJson is Map<String, dynamic>
          ? _mapLocation(completedLocJson)
          : null,
      timeline: timelineJson is List
          ? timelineJson
              .whereType<Map<String, dynamic>>()
              .map(_mapTimeline)
              .toList()
          : const [],
      estimatedDurationMinutes: _readNullableInt(json, 'estimatedDurationMinutes'),
      actualDurationMinutes: _readNullableInt(json, 'actualDurationMinutes'),
      startedAt: parseDateTime(json['startedAt']),
      completedAt: parseDateTime(json['completedAt']),
      cancelledAt: parseDateTime(json['cancelledAt']),
      cancellationReason: optionalString(json, 'cancellationReason'),
      rejectedAt: parseDateTime(json['rejectedAt']),
      rejectionReason: optionalString(json, 'rejectionReason'),
      acceptedAt: parseDateTime(json['acceptedAt']),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  static List<WorkOrderAttachment> _mapPhotoList(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<Map<String, dynamic>>().map(_mapAttachment).toList();
  }

  static WorkOrderAttachment _mapAttachment(Map<String, dynamic> json) {
    return WorkOrderAttachment(
      url: requireString(json, 'url'),
      publicId: optionalString(json, 'publicId'),
      fileName: optionalString(json, 'fileName'),
      mimeType: optionalString(json, 'mimeType'),
      uploadedAt: parseDateTime(json['uploadedAt']),
      uploadedBy: optionalString(json, 'uploadedBy'),
    );
  }

  static WorkOrderProgressNote _mapProgressNote(Map<String, dynamic> json) {
    return WorkOrderProgressNote(
      id: optionalString(json, 'id') ?? '',
      text: optionalString(json, 'text') ?? '',
      createdAt: parseDateTime(json['createdAt']),
      createdBy: optionalString(json, 'createdBy'),
      createdByName: optionalString(json, 'createdByName'),
    );
  }

  static WorkOrderFieldLocation _mapLocation(Map<String, dynamic> json) {
    return WorkOrderFieldLocation(
      latitude: _readNullableDouble(json, 'latitude') ?? 0,
      longitude: _readNullableDouble(json, 'longitude') ?? 0,
      accuracy: _readNullableDouble(json, 'accuracy'),
      address: optionalString(json, 'address'),
      recordedAt: parseDateTime(json['recordedAt']),
    );
  }

  static WorkOrderTimelineEvent _mapTimeline(Map<String, dynamic> json) {
    return WorkOrderTimelineEvent(
      type: WorkOrderTimelineType.fromApi(optionalString(json, 'type') ?? 'CREATED'),
      at: parseDateTime(json['at']) ?? DateTime.now(),
      userId: optionalString(json, 'userId'),
      userName: optionalString(json, 'userName'),
      note: optionalString(json, 'note'),
    );
  }

  static int? _readNullableInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  static double? _readNullableDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}

class PendingWorkOrderActionModel extends PendingWorkOrderAction {
  const PendingWorkOrderActionModel({
    required super.id,
    required super.type,
    required super.createdAt,
    super.workOrderId,
    super.payload = const {},
    super.retryCount = 0,
    super.lastError,
  });

  factory PendingWorkOrderActionModel.fromJson(Map<String, dynamic> json) {
    return PendingWorkOrderActionModel(
      id: requireString(json, 'id'),
      type: PendingWorkOrderActionType.values.firstWhere(
        (item) => item.name == json['type'],
        orElse: () => PendingWorkOrderActionType.update,
      ),
      workOrderId: optionalString(json, 'workOrderId'),
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastError: optionalString(json, 'lastError'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'workOrderId': workOrderId,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };
}
