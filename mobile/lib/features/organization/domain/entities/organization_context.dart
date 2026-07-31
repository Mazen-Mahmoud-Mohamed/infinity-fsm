import 'package:equatable/equatable.dart';
import 'package:mobile/features/organization/domain/entities/branch.dart';
import 'package:mobile/features/organization/domain/entities/company.dart';
import 'package:mobile/features/organization/domain/entities/department.dart';
import 'package:mobile/features/organization/domain/entities/position.dart';
import 'package:mobile/features/organization/domain/entities/team.dart';

class OrganizationContext extends Equatable {
  const OrganizationContext({
    this.company,
    this.branch,
    this.department,
    this.team,
    this.position,
  });

  final Company? company;
  final Branch? branch;
  final Department? department;
  final Team? team;
  final Position? position;

  @override
  List<Object?> get props => [company, branch, department, team, position];
}
