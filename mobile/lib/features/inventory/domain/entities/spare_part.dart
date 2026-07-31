import 'package:equatable/equatable.dart';

enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  String get apiValue {
    switch (this) {
      case StockStatus.inStock:
        return 'IN_STOCK';
      case StockStatus.lowStock:
        return 'LOW_STOCK';
      case StockStatus.outOfStock:
        return 'OUT_OF_STOCK';
    }
  }

  static StockStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'LOW_STOCK':
        return StockStatus.lowStock;
      case 'OUT_OF_STOCK':
        return StockStatus.outOfStock;
      case 'IN_STOCK':
      default:
        return StockStatus.inStock;
    }
  }
}

class SparePartImage extends Equatable {
  const SparePartImage({
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

class SparePart extends Equatable {
  const SparePart({
    required this.id,
    required this.partNumber,
    required this.name,
    required this.unit,
    required this.currentQuantity,
    required this.minimumQuantity,
    required this.stockStatus,
    this.companyId,
    this.category,
    this.description,
    this.image,
    this.barcode,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? companyId;
  final String partNumber;
  final String name;
  final String? category;
  final String? description;
  final String unit;
  final double currentQuantity;
  final double minimumQuantity;
  final StockStatus stockStatus;
  final SparePartImage? image;
  final String? barcode;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isLowStock => stockStatus == StockStatus.lowStock;
  bool get isOutOfStock => stockStatus == StockStatus.outOfStock;

  @override
  List<Object?> get props => [
        id,
        companyId,
        partNumber,
        name,
        category,
        description,
        unit,
        currentQuantity,
        minimumQuantity,
        stockStatus,
        image,
        barcode,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class SparePartPage extends Equatable {
  const SparePartPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<SparePart> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class SparePartImageInput {
  const SparePartImageInput({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final List<int> bytes;
  final String fileName;
  final String mimeType;
}

class SparePartUpsertInput {
  const SparePartUpsertInput({
    required this.partNumber,
    required this.name,
    this.category,
    this.description,
    this.unit = 'pcs',
    this.currentQuantity,
    this.minimumQuantity = 0,
    this.barcode,
    this.isActive = true,
    this.image,
    this.removeImage = false,
  });

  final String partNumber;
  final String name;
  final String? category;
  final String? description;
  final String unit;
  final double? currentQuantity;
  final double minimumQuantity;
  final String? barcode;
  final bool isActive;
  final SparePartImageInput? image;
  final bool removeImage;
}
