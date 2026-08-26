import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';

/// REST API for recipient notifications + device push tokens.
class NotificationsApiDataSource {
  NotificationsApiDataSource(this._dioClient);

  final DioClient _dioClient;

  Future<Result<({List<AppNotification> items, int unreadCount})>>
      listNotifications({int page = 1, int limit = 50}) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data?['data'];
      final meta = response.data?['meta'] as Map<String, dynamic>? ?? {};
      final list = data is List ? data : const <dynamic>[];
      final items = list
          .whereType<Map<dynamic, dynamic>>()
          .map((raw) => _mapItem(Map<String, dynamic>.from(raw)))
          .toList(growable: false);
      final unread = (meta['unreadCount'] as num?)?.toInt() ??
          items.where((n) => !n.isRead).length;
      return Success((items: items, unreadCount: unread));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  Future<Result<int>> unreadCount() async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return Success((data['count'] as num?)?.toInt() ?? 0);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  Future<Result<void>> markAsRead(String id) async {
    try {
      await _dioClient.put<Map<String, dynamic>>('/notifications/$id/read');
      return const Success(null);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  Future<Result<void>> markAllAsRead() async {
    try {
      await _dioClient.put<Map<String, dynamic>>('/notifications/read-all');
      return const Success(null);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  Future<Result<void>> registerDeviceToken({
    required String token,
    required String platform,
    required String locale,
    String? deviceId,
  }) async {
    try {
      await _dioClient.post<Map<String, dynamic>>(
        '/notifications/device-tokens',
        data: {
          'token': token,
          'platform': platform,
          'locale': locale,
          if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        },
      );
      return const Success(null);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  Future<Result<void>> deactivateDeviceToken(String token) async {
    try {
      await _dioClient.delete<Map<String, dynamic>>(
        '/notifications/device-tokens',
        data: {'token': token},
      );
      return const Success(null);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  AppNotification _mapItem(Map<String, dynamic> json) {
    final module = (json['module'] as String?) ?? 'general';
    final entityType = json['entityType'] as String?;
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      category: AppNotification.categoryFromModule(module),
      module: module,
      actorName: json['actorName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      isRead: json['isRead'] == true,
      entityType: entityType ?? data['type']?.toString(),
      entityId: json['entityId']?.toString() ??
          data['entityId']?.toString() ??
          data['workOrderId']?.toString() ??
          data['overtimeId']?.toString(),
      data: data,
    );
  }
}
