import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';

ReportPhotoRef _photoFromJson(Map<String, dynamic> json) => ReportPhotoRef(
      url: json['url']?.toString() ?? '',
      publicId: json['publicId']?.toString(),
      fileName: json['fileName']?.toString(),
      mimeType: json['mimeType']?.toString(),
      uploadedAt: DateTime.tryParse(json['uploadedAt']?.toString() ?? ''),
    );

List<ReportPhotoRef> _photosFromJson(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(_photoFromJson)
      .where((p) => p.url.isNotEmpty)
      .toList();
}

class CustomerSignatureModel extends CustomerSignature {
  const CustomerSignatureModel({
    required super.id,
    required super.customerName,
    super.companyId,
    super.workOrderId,
    super.workOrderNumber,
    super.customerPosition,
    super.signatureImage,
    super.signedAt,
    super.notes,
    super.createdBy,
    super.createdAt,
    super.updatedAt,
  });

  factory CustomerSignatureModel.fromJson(Map<String, dynamic> json) {
    final image = json['signatureImage'];
    return CustomerSignatureModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      workOrderId: json['workOrderId']?.toString(),
      workOrderNumber: json['workOrderNumber']?.toString(),
      customerName: json['customerName']?.toString() ?? '',
      customerPosition: json['customerPosition']?.toString(),
      signatureImage: image is Map<String, dynamic>
          ? SignatureImage(
              url: image['url']?.toString() ?? '',
              publicId: image['publicId']?.toString(),
              fileName: image['fileName']?.toString(),
              mimeType: image['mimeType']?.toString(),
              uploadedAt:
                  DateTime.tryParse(image['uploadedAt']?.toString() ?? ''),
            )
          : null,
      signedAt: DateTime.tryParse(json['signedAt']?.toString() ?? ''),
      notes: json['notes']?.toString(),
      createdBy: json['createdBy']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class ServiceReportModel extends ServiceReport {
  const ServiceReportModel({
    required super.id,
    required super.reportNumber,
    required super.status,
    required super.reportQrCode,
    super.companyId,
    super.company,
    super.workOrder,
    super.asset,
    super.technician,
    super.startTime,
    super.endTime,
    super.totalDurationMinutes,
    super.beforePhotos,
    super.progressPhotos,
    super.afterPhotos,
    super.technicianNotes,
    super.customerNotes,
    super.customerSignature,
    super.generatedAt,
    super.generatedBy,
    super.downloadCount,
    super.lastDownloadedAt,
    super.createdAt,
    super.updatedAt,
  });

  factory ServiceReportModel.fromJson(Map<String, dynamic> json) {
    final company = json['company'];
    final workOrder = json['workOrder'];
    final asset = json['asset'];
    final technician = json['technician'];
    final signature = json['customerSignature'];

    return ServiceReportModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      reportNumber: json['reportNumber']?.toString() ?? '',
      status: ServiceReportStatus.fromApi(json['status']?.toString()),
      company: company is Map<String, dynamic>
          ? ReportCompanyInfo(
              companyId: company['companyId']?.toString(),
              name: company['name']?.toString(),
              logoUrl: company['logoUrl']?.toString(),
            )
          : const ReportCompanyInfo(),
      workOrder: workOrder is Map<String, dynamic>
          ? ReportWorkOrderInfo(
              workOrderId: workOrder['workOrderId']?.toString(),
              jobNumber: workOrder['jobNumber']?.toString(),
              jobTitle: workOrder['jobTitle']?.toString(),
              customerName: workOrder['customerName']?.toString(),
              customerAddress: workOrder['customerAddress']?.toString(),
              description: workOrder['description']?.toString(),
              status: workOrder['status']?.toString(),
            )
          : const ReportWorkOrderInfo(),
      asset: asset is Map<String, dynamic>
          ? ReportAssetInfo(
              assetId: asset['assetId']?.toString(),
              assetNumber: asset['assetNumber']?.toString(),
              name: asset['name']?.toString(),
              serialNumber: asset['serialNumber']?.toString(),
              model: asset['model']?.toString(),
              manufacturer: asset['manufacturer']?.toString(),
            )
          : const ReportAssetInfo(),
      technician: technician is Map<String, dynamic>
          ? ReportTechnicianInfo(
              userId: technician['userId']?.toString(),
              name: technician['name']?.toString(),
              employeeId: technician['employeeId']?.toString(),
            )
          : const ReportTechnicianInfo(),
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? ''),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
      totalDurationMinutes: (json['totalDurationMinutes'] as num?)?.toInt(),
      beforePhotos: _photosFromJson(json['beforePhotos']),
      progressPhotos: _photosFromJson(json['progressPhotos']),
      afterPhotos: _photosFromJson(json['afterPhotos']),
      technicianNotes: json['technicianNotes']?.toString(),
      customerNotes: json['customerNotes']?.toString(),
      customerSignature: signature is Map<String, dynamic>
          ? ReportSignatureSnapshot(
              signatureId: signature['signatureId']?.toString(),
              customerName: signature['customerName']?.toString(),
              customerPosition: signature['customerPosition']?.toString(),
              signatureImageUrl: signature['signatureImageUrl']?.toString(),
              signedAt:
                  DateTime.tryParse(signature['signedAt']?.toString() ?? ''),
              notes: signature['notes']?.toString(),
            )
          : const ReportSignatureSnapshot(),
      reportQrCode: json['reportQrCode']?.toString() ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
      generatedBy: json['generatedBy']?.toString(),
      downloadCount: (json['downloadCount'] as num?)?.toInt() ?? 0,
      lastDownloadedAt:
          DateTime.tryParse(json['lastDownloadedAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class ServiceReportsDashboardModel extends ServiceReportsDashboard {
  const ServiceReportsDashboardModel({
    required super.totalReports,
    required super.generated,
    required super.downloaded,
    required super.totalSignatures,
    super.recentReports,
  });

  factory ServiceReportsDashboardModel.fromJson(Map<String, dynamic> json) {
    final recent = json['recentReports'];
    return ServiceReportsDashboardModel(
      totalReports: (json['totalReports'] as num?)?.toInt() ?? 0,
      generated: (json['generated'] as num?)?.toInt() ?? 0,
      downloaded: (json['downloaded'] as num?)?.toInt() ?? 0,
      totalSignatures: (json['totalSignatures'] as num?)?.toInt() ?? 0,
      recentReports: recent is List
          ? recent
              .whereType<Map<String, dynamic>>()
              .map(ServiceReportModel.fromJson)
              .toList()
          : const [],
    );
  }
}

class ServiceReportDownloadModel extends ServiceReportDownload {
  const ServiceReportDownloadModel({
    required super.report,
    required super.fileName,
    required super.mimeType,
    super.downloadedAt,
  });

  factory ServiceReportDownloadModel.fromJson(Map<String, dynamic> json) {
    final reportJson = json['report'] ?? json['content'] ?? json;
    return ServiceReportDownloadModel(
      report: ServiceReportModel.fromJson(
        reportJson is Map<String, dynamic>
            ? reportJson
            : const <String, dynamic>{},
      ),
      fileName: json['fileName']?.toString() ?? 'report.json',
      mimeType: json['mimeType']?.toString() ?? 'application/json',
      downloadedAt: DateTime.tryParse(json['downloadedAt']?.toString() ?? ''),
    );
  }
}

class PendingReportActionModel extends PendingReportAction {
  const PendingReportActionModel({
    required super.id,
    required super.type,
    required super.createdAt,
    super.resourceId,
    super.payload,
    super.retryCount,
    super.lastError,
  });

  factory PendingReportActionModel.fromJson(Map<String, dynamic> json) {
    return PendingReportActionModel(
      id: json['id']?.toString() ?? '',
      type: PendingReportActionType.values.firstWhere(
        (v) => v.name == json['type'],
        orElse: () => PendingReportActionType.generateReport,
      ),
      resourceId: json['resourceId']?.toString(),
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastError: json['lastError']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'resourceId': resourceId,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };
}
