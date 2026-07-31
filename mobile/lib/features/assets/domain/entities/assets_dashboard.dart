import 'package:equatable/equatable.dart';

class AssetsDashboard extends Equatable {
  const AssetsDashboard({
    required this.totalAssets,
    required this.active,
    required this.underMaintenance,
    required this.retired,
    required this.warrantyExpiringSoon,
  });

  final int totalAssets;
  final int active;
  final int underMaintenance;
  final int retired;
  final int warrantyExpiringSoon;

  @override
  List<Object?> get props => [
        totalAssets,
        active,
        underMaintenance,
        retired,
        warrantyExpiringSoon,
      ];
}
