import 'package:equatable/equatable.dart';

abstract class OrgEntity extends Equatable {
  const OrgEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}
