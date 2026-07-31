import 'package:mobile/features/inventory/domain/entities/spare_part.dart';

class SparePartModel extends SparePart {
  const SparePartModel({
    required super.id,
    required super.partNumber,
    required super.name,
    required super.unit,
    required super.currentQuantity,
    required super.minimumQuantity,
    required super.stockStatus,
    super.companyId,
    super.category,
    super.description,
    super.image,
    super.barcode,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  factory SparePartModel.fromJson(Map<String, dynamic> json) {
    final imageJson = json['image'];
    return SparePartModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      partNumber: json['partNumber']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      unit: json['unit']?.toString() ?? 'pcs',
      currentQuantity: (json['currentQuantity'] as num?)?.toDouble() ?? 0,
      minimumQuantity: (json['minimumQuantity'] as num?)?.toDouble() ?? 0,
      stockStatus: StockStatus.fromApi(json['stockStatus']?.toString()),
      image: imageJson is Map<String, dynamic>
          ? SparePartImage(
              url: imageJson['url']?.toString() ?? '',
              publicId: imageJson['publicId']?.toString(),
              fileName: imageJson['fileName']?.toString(),
              mimeType: imageJson['mimeType']?.toString(),
              uploadedAt: _parseDate(imageJson['uploadedAt']),
            )
          : null,
      barcode: json['barcode']?.toString(),
      isActive: json['isActive'] != false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
