import 'package:equatable/equatable.dart';
import 'package:mobile/features/assets/domain/entities/asset_category.dart';

enum AssetStatus {
  active,
  maintenance,
  offline,
  retired;

  String get apiValue {
    switch (this) {
      case AssetStatus.active:
        return 'ACTIVE';
      case AssetStatus.maintenance:
        return 'MAINTENANCE';
      case AssetStatus.offline:
        return 'OFFLINE';
      case AssetStatus.retired:
        return 'RETIRED';
    }
  }

  static AssetStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'MAINTENANCE':
        return AssetStatus.maintenance;
      case 'OFFLINE':
        return AssetStatus.offline;
      case 'RETIRED':
        return AssetStatus.retired;
      case 'ACTIVE':
      default:
        return AssetStatus.active;
    }
  }
}

class AssetImage extends Equatable {
  const AssetImage({
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

class AssetLocation extends Equatable {
  const AssetLocation({
    this.branchId,
    this.regionId,
    this.cityId,
    this.branchName,
    this.regionName,
    this.cityName,
  });

  final String? branchId;
  final String? regionId;
  final String? cityId;
  final String? branchName;
  final String? regionName;
  final String? cityName;

  @override
  List<Object?> get props => [
        branchId,
        regionId,
        cityId,
        branchName,
        regionName,
        cityName,
      ];
}

class AssetGps extends Equatable {
  const AssetGps({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.address,
  });

  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? address;

  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  List<Object?> get props => [latitude, longitude, accuracy, address];
}

class AssetCategoryRef extends Equatable {
  const AssetCategoryRef({
    required this.id,
    this.name,
    this.code,
    this.icon,
  });

  final String id;
  final String? name;
  final String? code;
  final String? icon;

  @override
  List<Object?> get props => [id, name, code, icon];
}

class Asset extends Equatable {
  const Asset({
    required this.id,
    required this.assetNumber,
    required this.name,
    required this.status,
    this.companyId,
    this.category,
    this.serialNumber,
    this.manufacturer,
    this.model,
    this.installationDate,
    this.warrantyExpiry,
    this.location = const AssetLocation(),
    this.gps = const AssetGps(),
    this.qrCode,
    this.barcode,
    this.customer,
    this.notes,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? companyId;
  final String assetNumber;
  final String name;
  final AssetCategoryRef? category;
  final String? serialNumber;
  final String? manufacturer;
  final String? model;
  final DateTime? installationDate;
  final DateTime? warrantyExpiry;
  final AssetStatus status;
  final AssetLocation location;
  final AssetGps gps;
  final String? qrCode;
  final String? barcode;
  final String? customer;
  final String? notes;
  final AssetImage? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        assetNumber,
        name,
        category,
        serialNumber,
        manufacturer,
        model,
        installationDate,
        warrantyExpiry,
        status,
        location,
        gps,
        qrCode,
        barcode,
        customer,
        notes,
        image,
        createdAt,
        updatedAt,
      ];
}

class AssetPage extends Equatable {
  const AssetPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<Asset> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class AssetImageInput {
  const AssetImageInput({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final List<int> bytes;
  final String fileName;
  final String mimeType;
}

class AssetUpsertInput {
  const AssetUpsertInput({
    required this.assetNumber,
    required this.name,
    this.categoryId,
    this.serialNumber,
    this.manufacturer,
    this.model,
    this.installationDate,
    this.warrantyExpiry,
    this.status = AssetStatus.active,
    this.branchId,
    this.regionName,
    this.cityName,
    this.gps,
    this.qrCode,
    this.barcode,
    this.customer,
    this.notes,
    this.image,
    this.removeImage = false,
  });

  final String assetNumber;
  final String name;
  final String? categoryId;
  final String? serialNumber;
  final String? manufacturer;
  final String? model;
  final DateTime? installationDate;
  final DateTime? warrantyExpiry;
  final AssetStatus status;
  final String? branchId;
  final String? regionName;
  final String? cityName;
  final AssetGps? gps;
  final String? qrCode;
  final String? barcode;
  final String? customer;
  final String? notes;
  final AssetImageInput? image;
  final bool removeImage;
}

// Re-export category type used by forms.
typedef AssetCategoryEntity = AssetCategory;
