import 'package:equatable/equatable.dart';

enum GlobalSearchModule {
  users,
  workOrders,
  assets,
  inventory,
  overtime,
  pm,
  reports,
}

class GlobalSearchHit extends Equatable {
  const GlobalSearchHit({
    required this.id,
    required this.module,
    required this.title,
    required this.route,
    this.subtitle,
  });

  final String id;
  final GlobalSearchModule module;
  final String title;
  final String? subtitle;
  final String route;

  @override
  List<Object?> get props => [id, module, title, subtitle, route];
}
