import 'package:mobile/features/assets/domain/entities/asset.dart';

class AssetModel extends Asset {
  const AssetModel({
    required super.id,
    required super.assetNumber,
    required super.name,
    required super.status,
    super.companyId,
    super.category,
    super.serialNumber,
    super.manufacturer,
    super.model,
    super.installationDate,
    super.warrantyExpiry,
    super.location,
    super.gps,
    super.qrCode,
    super.barcode,
    super.customer,
    super.notes,
    super.image,
    super.createdAt,
    super.updatedAt,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'];
    final locationJson = json['location'];
    final gpsJson = json['gps'];
    final imageJson = json['image'];

    return AssetModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      assetNumber: json['assetNumber']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: categoryJson is Map<String, dynamic>
          ? AssetCategoryRef(
              id: categoryJson['id']?.toString() ?? '',
              name: categoryJson['name']?.toString(),
              code: categoryJson['code']?.toString(),
              icon: categoryJson['icon']?.toString(),
            )
          : null,
      serialNumber: json['serialNumber']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      model: json['model']?.toString(),
      installationDate: DateTime.tryParse(json['installationDate']?.toString() ?? ''),
      warrantyExpiry: DateTime.tryParse(json['warrantyExpiry']?.toString() ?? ''),
      status: AssetStatus.fromApi(json['status']?.toString()),
      location: locationJson is Map<String, dynamic>
          ? AssetLocation(
              branchId: locationJson['branchId']?.toString(),
              regionId: locationJson['regionId']?.toString(),
              cityId: locationJson['cityId']?.toString(),
              branchName: locationJson['branchName']?.toString(),
              regionName: locationJson['regionName']?.toString(),
              cityName: locationJson['cityName']?.toString(),
            )
          : const AssetLocation(),
      gps: gpsJson is Map<String, dynamic>
          ? AssetGps(
              latitude: (gpsJson['latitude'] as num?)?.toDouble(),
              longitude: (gpsJson['longitude'] as num?)?.toDouble(),
              accuracy: (gpsJson['accuracy'] as num?)?.toDouble(),
              address: gpsJson['address']?.toString(),
            )
          : const AssetGps(),
      qrCode: json['qrCode']?.toString(),
      barcode: json['barcode']?.toString(),
      customer: json['customer']?.toString(),
      notes: json['notes']?.toString(),
      image: imageJson is Map<String, dynamic>
          ? AssetImage(
              url: imageJson['url']?.toString() ?? '',
              publicId: imageJson['publicId']?.toString(),
              fileName: imageJson['fileName']?.toString(),
              mimeType: imageJson['mimeType']?.toString(),
              uploadedAt:
                  DateTime.tryParse(imageJson['uploadedAt']?.toString() ?? ''),
            )
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}
