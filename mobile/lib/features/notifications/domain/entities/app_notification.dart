import 'package:equatable/equatable.dart';

/// In-app notification derived from existing dashboard activity feed.
/// Read state is stored locally until a dedicated notifications API exists.
enum NotificationCategory {
  all,
  attendance,
  overtime,
  workOrders,
  inventory,
  assets,
  maintenance,
  reports,
  users,
  roles,
  settings,
  general,
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.module,
    this.actorName,
    this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final String module;
  final String? actorName;
  final DateTime? createdAt;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      category: category,
      module: module,
      actorName: actorName,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  static NotificationCategory categoryFromModule(String module) {
    switch (module.trim().toLowerCase()) {
      case 'attendance':
        return NotificationCategory.attendance;
      case 'overtime':
        return NotificationCategory.overtime;
      case 'work_orders':
      case 'work-orders':
      case 'workorders':
        return NotificationCategory.workOrders;
      case 'inventory':
        return NotificationCategory.inventory;
      case 'assets':
        return NotificationCategory.assets;
      case 'pm':
      case 'maintenance':
      case 'preventive_maintenance':
        return NotificationCategory.maintenance;
      case 'reports':
      case 'service_reports':
        return NotificationCategory.reports;
      case 'users':
        return NotificationCategory.users;
      case 'roles':
      case 'rbac':
        return NotificationCategory.roles;
      case 'settings':
        return NotificationCategory.settings;
      default:
        return NotificationCategory.general;
    }
  }

  @override
  List<Object?> get props =>
      [id, title, body, category, module, actorName, createdAt, isRead];
}
