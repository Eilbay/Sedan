import 'package:dio/dio.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/features/notifications/data/models/notification_item.dart';
import 'package:optombai/features/notifications/data/models/notification_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.next,
    required this.count,
  });

  final List<NotificationItem> items;
  final String? next;
  final int count;
}

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._dio, this._preferences);

  final Dio _dio;
  final SharedPreferences _preferences;

  String _token() => _preferences.getString(TOKEN_KEY) ?? '';

  Options _auth() => Options(headers: {'Authorization': 'Bearer ${_token()}'});

  Future<NotificationsPage> fetchList({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.notificationsList,
        queryParameters: {
          'limit': limit,
          'offset': (page - 1) * limit,
        },
        options: _auth(),
      );

      final data = response.data;
      final List results = (data is Map ? data['results'] : null) as List? ??
          (data is List ? data : const []);
      final items = results
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .where((item) => item.type.belongsToNotifications)
          .toList();

      return NotificationsPage(
        items: items,
        next: data is Map ? data['next']?.toString() : null,
        count: (data is Map ? (data['count'] as num?) : null)?.toInt() ??
            items.length,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.notificationsUnreadCount,
        options: _auth(),
      );
      final data = response.data;
      if (data is Map) {
        final count = _extractPublicationUnreadCount(
          Map<String, dynamic>.from(data),
        );
        if (count != null) return count;
      }
      return _fetchPublicationUnreadCountFromList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  int? _extractPublicationUnreadCount(Map<String, dynamic> data) {
    final byType = data['by_type'] ?? data['types'] ?? data['counts'];
    if (byType is Map) {
      return _countPublicationTypes(Map<String, dynamic>.from(byType));
    }

    final unreadByType = data['unread_by_type'];
    if (unreadByType is Map) {
      return _countPublicationTypes(Map<String, dynamic>.from(unreadByType));
    }

    final explicitLike = data['unread_likes'] ??
        data['unread_like'] ??
        data['unread_likes_count'] ??
        data['unread_like_count'] ??
        data['likes_count'] ??
        data['like_count'] ??
        data['likes'] ??
        data['like'];
    final explicitComment = data['unread_comments'] ??
        data['unread_comment'] ??
        data['unread_comments_count'] ??
        data['unread_comment_count'] ??
        data['comments_count'] ??
        data['comment_count'] ??
        data['comments'] ??
        data['comment'];

    if (explicitLike != null || explicitComment != null) {
      return _countValue(explicitLike) + _countValue(explicitComment);
    }

    return null;
  }

  int _countValue(Object? value) {
    if (value is num) return value.toInt();
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return ((map['count'] ?? map['unread_count']) as num?)?.toInt() ?? 0;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _countPublicationTypes(Map<String, dynamic> typed) {
    var total = 0;

    for (final entry in typed.entries) {
      final type = NotificationType.fromApi(entry.key);
      if (type.belongsToNotifications) {
        total += _countValue(entry.value);
      }
    }

    return total;
  }

  Future<int> _fetchPublicationUnreadCountFromList() async {
    var page = 1;
    var total = 0;
    String? next;

    do {
      final notificationsPage = await fetchList(page: page, limit: 100);
      total += notificationsPage.items.where((item) => !item.isRead).length;
      next = notificationsPage.next;
      page++;
    } while (next != null && page <= 5);

    return total;
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.post(
        ApiEndpoints.notificationsRead(id),
        options: _auth(),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post(
        ApiEndpoints.notificationsReadAll,
        options: _auth(),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<NotificationPreferences> fetchPreferences() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.notificationsPreferences,
        options: _auth(),
      );
      return NotificationPreferences.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<NotificationPreferences> updatePreferences(
    Map<String, dynamic> patch,
  ) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.notificationsPreferences,
        data: patch,
        options: _auth(),
      );
      return NotificationPreferences.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
