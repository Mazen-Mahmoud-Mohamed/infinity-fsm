import 'package:equatable/equatable.dart';

enum ServiceReportStatus {
  draft,
  generated,
  downloaded;

  String get apiValue => switch (this) {
        ServiceReportStatus.draft => 'DRAFT',
        ServiceReportStatus.generated => 'GENERATED',
        ServiceReportStatus.downloaded => 'DOWNLOADED',
      };

  static ServiceReportStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'DRAFT':
        return ServiceReportStatus.draft;
      case 'DOWNLOADED':
        return ServiceReportStatus.downloaded;
      case 'GENERATED':
      default:
        return ServiceReportStatus.generated;
    }
  }
}

class ReportPhotoRef extends Equatable {
  const ReportPhotoRef({
    required this.url,
    this.publicId,
    this.fileName,
    this.mimeType,
    this.uploadedAt,
  });

  final String url;
  final String? publicId;
  final String? fileName;
  final String? mimeType;
  final DateTime? uploadedAt;

  Map<String, dynamic> toJson() => {
        'url': url,
        if (publicId != null) 'publicId': publicId,
        if (fileName != null) 'fileName': fileName,
        if (mimeType != null) 'mimeType': mimeType,
      };

  @override
  List<Object?> get props => [url, publicId, fileName, mimeType, uploadedAt];
}

class SignatureImage extends Equatable {
  const SignatureImage({
    required this.url,
    this.publicId,
    this.fileName,
    this.mimeType,
    this.uploadedAt,
  });

  final String url;
  final String? publicId;
  final String? fileName;
  final String? mimeType;
  final DateTime? uploadedAt;

  @override
  List<Object?> get props => [url, publicId, fileName, mimeType, uploadedAt];
}

class CustomerSignature extends Equatable {
  const CustomerSignature({
    required this.id,
    required this.customerName,
    this.companyId,
    this.workOrderId,
    this.workOrderNumber,
    this.customerPosition,
    this.signatureImage,
    this.signedAt,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? companyId;
  final String? workOrderId;
  final String? workOrderNumber;
  final String customerName;
  final String? customerPosition;
  final SignatureImage? signatureImage;
  final DateTime? signedAt;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        workOrderId,
        workOrderNumber,
        customerName,
        customerPosition,
        signatureImage,
        signedAt,
        notes,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

class CustomerSignaturePage extends Equatable {
  const CustomerSignaturePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<CustomerSignature> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class CreateSignatureInput {
  const CreateSignatureInput({
    required this.customerName,
    required this.signatureBytes,
    this.customerPosition,
    this.workOrderId,
    this.workOrderNumber,
    this.signedAt,
    this.notes,
    this.fileName = 'signature.png',
    this.mimeType = 'image/png',
  });

  final String customerName;
  final String? customerPosition;
  final String? workOrderId;
  final String? workOrderNumber;
  final DateTime? signedAt;
  final String? notes;
  final List<int> signatureBytes;
  final String fileName;
  final String mimeType;
}

class ReportCompanyInfo extends Equatable {
  const ReportCompanyInfo({this.companyId, this.name, this.logoUrl});
  final String? companyId;
  final String? name;
  final String? logoUrl;
  @override
  List<Object?> get props => [companyId, name, logoUrl];
}

class ReportWorkOrderInfo extends Equatable {
  const ReportWorkOrderInfo({
    this.workOrderId,
    this.jobNumber,
    this.jobTitle,
    this.customerName,
    this.customerAddress,
    this.description,
    this.status,
  });

  final String? workOrderId;
  final String? jobNumber;
  final String? jobTitle;
  final String? customerName;
  final String? customerAddress;
  final String? description;
  final String? status;

  Map<String, dynamic> toJson() => {
        if (workOrderId != null) 'workOrderId': workOrderId,
        if (jobNumber != null) 'jobNumber': jobNumber,
        if (jobTitle != null) 'jobTitle': jobTitle,
        if (customerName != null) 'customerName': customerName,
        if (customerAddress != null) 'customerAddress': customerAddress,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
      };

  @override
  List<Object?> get props => [
        workOrderId,
        jobNumber,
        jobTitle,
        customerName,
        customerAddress,
        description,
        status,
      ];
}

class ReportAssetInfo extends Equatable {
  const ReportAssetInfo({
    this.assetId,
    this.assetNumber,
    this.name,
    this.serialNumber,
    this.model,
    this.manufacturer,
  });

  final String? assetId;
  final String? assetNumber;
  final String? name;
  final String? serialNumber;
  final String? model;
  final String? manufacturer;

  Map<String, dynamic> toJson() => {
        if (assetId != null) 'assetId': assetId,
        if (assetNumber != null) 'assetNumber': assetNumber,
        if (name != null) 'name': name,
        if (serialNumber != null) 'serialNumber': serialNumber,
        if (model != null) 'model': model,
        if (manufacturer != null) 'manufacturer': manufacturer,
      };

  @override
  List<Object?> get props =>
      [assetId, assetNumber, name, serialNumber, model, manufacturer];
}

class ReportTechnicianInfo extends Equatable {
  const ReportTechnicianInfo({this.userId, this.name, this.employeeId});
  final String? userId;
  final String? name;
  final String? employeeId;

  Map<String, dynamic> toJson() => {
        if (userId != null) 'userId': userId,
        if (name != null) 'name': name,
        if (employeeId != null) 'employeeId': employeeId,
      };

  @override
  List<Object?> get props => [userId, name, employeeId];
}

class ReportSignatureSnapshot extends Equatable {
  const ReportSignatureSnapshot({
    this.signatureId,
    this.customerName,
    this.customerPosition,
    this.signatureImageUrl,
    this.signedAt,
    this.notes,
  });

  final String? signatureId;
  final String? customerName;
  final String? customerPosition;
  final String? signatureImageUrl;
  final DateTime? signedAt;
  final String? notes;

  @override
  List<Object?> get props => [
        signatureId,
        customerName,
        customerPosition,
        signatureImageUrl,
        signedAt,
        notes,
      ];
}

class ServiceReport extends Equatable {
  const ServiceReport({
    required this.id,
    required this.reportNumber,
    required this.status,
    required this.reportQrCode,
    this.companyId,
    this.company = const ReportCompanyInfo(),
    this.workOrder = const ReportWorkOrderInfo(),
    this.asset = const ReportAssetInfo(),
    this.technician = const ReportTechnicianInfo(),
    this.startTime,
    this.endTime,
    this.totalDurationMinutes,
    this.beforePhotos = const [],
    this.progressPhotos = const [],
    this.afterPhotos = const [],
    this.technicianNotes,
    this.customerNotes,
    this.customerSignature = const ReportSignatureSnapshot(),
    this.generatedAt,
    this.generatedBy,
    this.downloadCount = 0,
    this.lastDownloadedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? companyId;
  final String reportNumber;
  final ServiceReportStatus status;
  final ReportCompanyInfo company;
  final ReportWorkOrderInfo workOrder;
  final ReportAssetInfo asset;
  final ReportTechnicianInfo technician;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? totalDurationMinutes;
  final List<ReportPhotoRef> beforePhotos;
  final List<ReportPhotoRef> progressPhotos;
  final List<ReportPhotoRef> afterPhotos;
  final String? technicianNotes;
  final String? customerNotes;
  final ReportSignatureSnapshot customerSignature;
  final String reportQrCode;
  final DateTime? generatedAt;
  final String? generatedBy;
  final int downloadCount;
  final DateTime? lastDownloadedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        reportNumber,
        status,
        company,
        workOrder,
        asset,
        technician,
        startTime,
        endTime,
        totalDurationMinutes,
        beforePhotos,
        progressPhotos,
        afterPhotos,
        technicianNotes,
        customerNotes,
        customerSignature,
        reportQrCode,
        generatedAt,
        generatedBy,
        downloadCount,
        lastDownloadedAt,
        createdAt,
        updatedAt,
      ];
}

class ServiceReportPage extends Equatable {
  const ServiceReportPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<ServiceReport> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class GenerateServiceReportInput {
  const GenerateServiceReportInput({
    this.companyName,
    this.companyLogoUrl,
    this.workOrderId,
    this.signatureId,
    this.workOrder = const ReportWorkOrderInfo(),
    this.asset = const ReportAssetInfo(),
    this.technician = const ReportTechnicianInfo(),
    this.startTime,
    this.endTime,
    this.totalDurationMinutes,
    this.beforePhotos = const [],
    this.progressPhotos = const [],
    this.afterPhotos = const [],
    this.technicianNotes,
    this.customerNotes,
  });

  final String? companyName;
  final String? companyLogoUrl;
  final String? workOrderId;
  final String? signatureId;
  final ReportWorkOrderInfo workOrder;
  final ReportAssetInfo asset;
  final ReportTechnicianInfo technician;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? totalDurationMinutes;
  final List<ReportPhotoRef> beforePhotos;
  final List<ReportPhotoRef> progressPhotos;
  final List<ReportPhotoRef> afterPhotos;
  final String? technicianNotes;
  final String? customerNotes;
}

class ServiceReportDownload extends Equatable {
  const ServiceReportDownload({
    required this.report,
    required this.fileName,
    required this.mimeType,
    this.downloadedAt,
  });

  final ServiceReport report;
  final String fileName;
  final String mimeType;
  final DateTime? downloadedAt;

  @override
  List<Object?> get props => [report, fileName, mimeType, downloadedAt];
}

class ServiceReportsDashboard extends Equatable {
  const ServiceReportsDashboard({
    required this.totalReports,
    required this.generated,
    required this.downloaded,
    required this.totalSignatures,
    this.recentReports = const [],
  });

  final int totalReports;
  final int generated;
  final int downloaded;
  final int totalSignatures;
  final List<ServiceReport> recentReports;

  @override
  List<Object?> get props =>
      [totalReports, generated, downloaded, totalSignatures, recentReports];
}

enum PendingReportActionType {
  createSignature,
  generateReport,
}

class PendingReportAction extends Equatable {
  const PendingReportAction({
    required this.id,
    required this.type,
    required this.createdAt,
    this.resourceId,
    this.payload = const {},
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final PendingReportActionType type;
  final String? resourceId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  @override
  List<Object?> get props =>
      [id, type, resourceId, payload, createdAt, retryCount, lastError];
}
