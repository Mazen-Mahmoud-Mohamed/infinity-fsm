import 'package:equatable/equatable.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';

class WorkOrderAttachment extends Equatable {
  const WorkOrderAttachment({
    required this.url,
    this.publicId,
    this.fileName,
    this.mimeType,
    this.uploadedAt,
    this.uploadedBy,
  });

  final String url;
  final String? publicId;
  final String? fileName;
  final String? mimeType;
  final DateTime? uploadedAt;
  final String? uploadedBy;

  bool get isImage {
    final mime = mimeType?.toLowerCase() ?? '';
    if (mime.startsWith('image/')) {
      return true;
    }
    final name = (fileName ?? url).toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp');
  }

  @override
  List<Object?> get props =>
      [url, publicId, fileName, mimeType, uploadedAt, uploadedBy];
}

class WorkOrderAddress extends Equatable {
  const WorkOrderAddress({
    this.street,
    this.city,
    this.governorate,
    this.lat,
    this.lng,
  });

  final String? street;
  final String? city;
  final String? governorate;
  final double? lat;
  final double? lng;

  bool get hasCoordinates => lat != null && lng != null;

  String get displayText {
    final parts = [street, city, governorate]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        if (street != null) 'street': street,
        if (city != null) 'city': city,
        if (governorate != null) 'governorate': governorate,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  @override
  List<Object?> get props => [street, city, governorate, lat, lng];
}

class WorkOrderFieldLocation extends Equatable {
  const WorkOrderFieldLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.address,
    this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? address;
  final DateTime? recordedAt;

  @override
  List<Object?> get props =>
      [latitude, longitude, accuracy, address, recordedAt];
}

class WorkOrderProgressNote extends Equatable {
  const WorkOrderProgressNote({
    required this.id,
    required this.text,
    this.createdAt,
    this.createdBy,
    this.createdByName,
  });

  final String id;
  final String text;
  final DateTime? createdAt;
  final String? createdBy;
  final String? createdByName;

  @override
  List<Object?> get props => [id, text, createdAt, createdBy, createdByName];
}

class WorkOrderVoiceNote extends Equatable {
  const WorkOrderVoiceNote({
    required this.url,
    this.publicId,
    this.duration,
    this.size,
    this.format,
    this.uploadedAt,
  });

  final String url;
  final String? publicId;
  final double? duration;
  final int? size;
  final String? format;
  final DateTime? uploadedAt;

  @override
  List<Object?> get props =>
      [url, publicId, duration, size, format, uploadedAt];
}

enum WorkOrderTimelineType {
  created,
  assigned,
  accepted,
  rejected,
  started,
  completed,
  cancelled;

  static WorkOrderTimelineType fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'ASSIGNED':
        return WorkOrderTimelineType.assigned;
      case 'ACCEPTED':
        return WorkOrderTimelineType.accepted;
      case 'REJECTED':
        return WorkOrderTimelineType.rejected;
      case 'STARTED':
        return WorkOrderTimelineType.started;
      case 'COMPLETED':
        return WorkOrderTimelineType.completed;
      case 'CANCELLED':
        return WorkOrderTimelineType.cancelled;
      default:
        return WorkOrderTimelineType.created;
    }
  }

  String get label {
    switch (this) {
      case WorkOrderTimelineType.created:
        return 'Created';
      case WorkOrderTimelineType.assigned:
        return 'Assigned';
      case WorkOrderTimelineType.accepted:
        return 'Accepted';
      case WorkOrderTimelineType.rejected:
        return 'Rejected';
      case WorkOrderTimelineType.started:
        return 'Started';
      case WorkOrderTimelineType.completed:
        return 'Completed';
      case WorkOrderTimelineType.cancelled:
        return 'Cancelled';
    }
  }
}

class WorkOrderTimelineEvent extends Equatable {
  const WorkOrderTimelineEvent({
    required this.type,
    required this.at,
    this.userId,
    this.userName,
    this.note,
  });

  final WorkOrderTimelineType type;
  final DateTime at;
  final String? userId;
  final String? userName;
  final String? note;

  @override
  List<Object?> get props => [type, at, userId, userName, note];
}

enum WorkOrderPhotoCategory { before, progress, after }

class WorkOrder extends Equatable {
  const WorkOrder({
    required this.id,
    required this.companyId,
    required this.jobNumber,
    required this.jobTitle,
    required this.priority,
    required this.status,
    this.customerName,
    this.customerAddress,
    this.locationLabel,
    this.locationUrl,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.assignedTechnicianIds = const [],
    this.assignedTechnicianNames = const [],
    this.customerPhoneNumbers = const [],
    this.description,
    this.notes,
    this.voiceNote,
    this.scheduledAt,
    this.attachments = const [],
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.progressPhotos = const [],
    this.beforeNotes,
    this.progressNotes = const [],
    this.completionNotes,
    this.startedLocation,
    this.completedLocation,
    this.timeline = const [],
    this.estimatedDurationMinutes,
    this.actualDurationMinutes,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.rejectedAt,
    this.rejectionReason,
    this.acceptedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String jobNumber;
  final String jobTitle;
  final String? customerName;
  final WorkOrderAddress? customerAddress;
  final String? locationLabel;
  final String? locationUrl;
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final List<String> assignedTechnicianIds;
  final List<String> assignedTechnicianNames;
  final List<String> customerPhoneNumbers;
  final WorkOrderPriority priority;
  final WorkOrderStatus status;
  final String? description;
  final String? notes;
  final WorkOrderVoiceNote? voiceNote;
  final DateTime? scheduledAt;
  final List<WorkOrderAttachment> attachments;
  final List<WorkOrderAttachment> beforePhotos;
  final List<WorkOrderAttachment> afterPhotos;
  final List<WorkOrderAttachment> progressPhotos;
  final String? beforeNotes;
  final List<WorkOrderProgressNote> progressNotes;
  final String? completionNotes;
  final WorkOrderFieldLocation? startedLocation;
  final WorkOrderFieldLocation? completedLocation;
  final List<WorkOrderTimelineEvent> timeline;
  final int? estimatedDurationMinutes;
  final int? actualDurationMinutes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? acceptedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Prefer explicit URL; fall back to label when it is already a URL.
  String? get effectiveLocationUrl {
    final url = locationUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return url;
    }
    final label = locationLabel?.trim();
    if (label != null &&
        (label.startsWith('http://') || label.startsWith('https://'))) {
      return label;
    }
    return null;
  }

  bool get hasOpenableLocationUrl {
    final url = effectiveLocationUrl;
    if (url == null) {
      return false;
    }
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String get locationDisplay {
    if (locationLabel != null && locationLabel!.trim().isNotEmpty) {
      return locationLabel!.trim();
    }
    final url = effectiveLocationUrl;
    if (url != null) {
      return url;
    }
    final address = customerAddress?.displayText;
    if (address != null && address.isNotEmpty) {
      return address;
    }
    return '—';
  }

  List<String> get effectiveAssigneeIds {
    if (assignedTechnicianIds.isNotEmpty) {
      return assignedTechnicianIds;
    }
    final single = assignedTechnicianId;
    return single == null || single.isEmpty ? const [] : [single];
  }

  String get assigneesDisplay {
    if (assignedTechnicianNames.isNotEmpty) {
      return assignedTechnicianNames.join(', ');
    }
    return assignedTechnicianName ?? '';
  }

  bool isAssignedTo(String? userId) {
    if (userId == null || userId.isEmpty) {
      return false;
    }
    return effectiveAssigneeIds.contains(userId);
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        jobNumber,
        jobTitle,
        customerName,
        customerAddress,
        locationLabel,
        locationUrl,
        assignedTechnicianId,
        assignedTechnicianName,
        assignedTechnicianIds,
        assignedTechnicianNames,
        customerPhoneNumbers,
        priority,
        status,
        description,
        notes,
        voiceNote,
        scheduledAt,
        attachments,
        beforePhotos,
        afterPhotos,
        progressPhotos,
        beforeNotes,
        progressNotes,
        completionNotes,
        startedLocation,
        completedLocation,
        timeline,
        estimatedDurationMinutes,
        actualDurationMinutes,
        startedAt,
        completedAt,
        cancelledAt,
        cancellationReason,
        rejectedAt,
        rejectionReason,
        acceptedAt,
        createdAt,
        updatedAt,
      ];
}

class WorkOrderPage extends Equatable {
  const WorkOrderPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<WorkOrder> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class WorkOrderAttachmentInput {
  const WorkOrderAttachmentInput({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final List<int> bytes;
  final String fileName;
  final String mimeType;
}

class WorkOrderUpsertInput {
  const WorkOrderUpsertInput({
    required this.jobTitle,
    this.customerName,
    this.customerPhoneNumbers = const [],
    this.locationLabel,
    this.locationUrl,
    this.customerAddress,
    this.description,
    this.notes,
    this.priority = WorkOrderPriority.medium,
    this.scheduledAt,
    this.assignedTechnicianId,
    this.assignedTechnicianIds = const [],
    this.estimatedDurationMinutes,
    this.attachments = const [],
    this.voiceNoteBytes,
    this.voiceNoteFileName,
    this.voiceNoteMimeType,
    this.clearVoiceNote = false,
    this.replaceAttachments = false,
    this.keepAttachmentUrls = const [],
  });

  final String jobTitle;
  final String? customerName;
  final List<String> customerPhoneNumbers;
  final String? locationLabel;
  final String? locationUrl;
  final WorkOrderAddress? customerAddress;
  final String? description;
  final String? notes;
  final WorkOrderPriority priority;
  final DateTime? scheduledAt;
  final String? assignedTechnicianId;
  final List<String> assignedTechnicianIds;
  final int? estimatedDurationMinutes;
  final List<WorkOrderAttachmentInput> attachments;
  final List<int>? voiceNoteBytes;
  final String? voiceNoteFileName;
  final String? voiceNoteMimeType;
  final bool clearVoiceNote;
  final bool replaceAttachments;
  final List<String> keepAttachmentUrls;
}

class WorkOrderLocationInput {
  const WorkOrderLocationInput({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracy,
    this.address,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? address;
  final DateTime recordedAt;
}
