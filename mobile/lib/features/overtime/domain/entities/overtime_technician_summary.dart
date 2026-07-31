import 'package:equatable/equatable.dart';

class OvertimeTechnicianSummary extends Equatable {
  const OvertimeTechnicianSummary({
    required this.id,
    this.firstName,
    this.lastName,
    this.fullName,
    this.email,
    this.roles = const [],
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? email;
  final List<String> roles;

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    final combined = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (combined.isNotEmpty) {
      return combined;
    }
    return email ?? id;
  }

  String get primaryRole => roles.isEmpty ? '-' : roles.first;

  @override
  List<Object?> get props => [id, firstName, lastName, fullName, email, roles];
}
