import 'package:equatable/equatable.dart';

/// Identifier of the action that produced the notification.
/// Matches the `type` field the backend puts inside push `data`.
enum NotificationType {
  like('like'),
  comment('comment'),
  message('message'),
  unknown('unknown');

  const NotificationType(this.apiValue);

  final String apiValue;

  bool get belongsToNotifications =>
      this == NotificationType.like || this == NotificationType.comment;

  static NotificationType fromApi(String? raw) {
    if (raw == null) return NotificationType.unknown;
    final normalized = raw.trim().toLowerCase().replaceAll('-', '_');
    for (final t in NotificationType.values) {
      if (t.apiValue == normalized) return t;
    }
    if (normalized.contains('message') ||
        normalized.contains('chat') ||
        normalized.contains('сообщ')) {
      return NotificationType.message;
    }
    if (normalized.contains('comment') || normalized.contains('коммент')) {
      return NotificationType.comment;
    }
    if (normalized.contains('like') ||
        normalized.contains('favorite') ||
        normalized.contains('favourite') ||
        normalized.contains('лайк') ||
        normalized.contains('оценил')) {
      return NotificationType.like;
    }
    return NotificationType.unknown;
  }

  static NotificationType infer({
    required Map<String, dynamic> json,
    required Map<String, dynamic> data,
    required String title,
    required String body,
    required String? postId,
    required String? commentId,
    required String? chatId,
  }) {
    final rawType = data['type'] ??
        data['notification_type'] ??
        data['event_type'] ??
        data['event'] ??
        data['action'] ??
        json['type'] ??
        json['notification_type'] ??
        json['event_type'] ??
        json['event'] ??
        json['action'];

    final parsed = NotificationType.fromApi(rawType?.toString());
    if (parsed != NotificationType.unknown) return parsed;

    final text = '$title $body'.toLowerCase();
    final fromText = NotificationType.fromApi(text);
    if (fromText != NotificationType.unknown) return fromText;

    if (commentId != null && commentId.isNotEmpty) {
      return NotificationType.comment;
    }
    if (postId != null && postId.isNotEmpty) {
      return NotificationType.like;
    }
    if (chatId != null && chatId.isNotEmpty) {
      return NotificationType.message;
    }

    return NotificationType.unknown;
  }
}

class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.postId,
    this.commentId,
    this.chatId,
    this.actorId,
    this.actorUsername,
    this.actorImage,
    this.previewUrl,
    this.contentType,
    this.isVideo = false,
    this.raw = const {},
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? postId;
  final String? commentId;
  final String? chatId;

  /// Author of the action (who liked / commented / messaged).
  /// Source: top-level `actor` object in the API payload.
  /// [actorId] drives navigation to the author's profile; null when the
  /// backend omits it, in which case the avatar is not tappable.
  final String? actorId;
  final String? actorUsername;
  final String? actorImage;

  /// Preview of the media the action targets (cover frame / first image).
  /// Source: `data.cover_url`. Null until the backend populates it.
  final String? previewUrl;

  /// `"reel"` | `"product"` — kept for future content-aware navigation.
  /// Source: `data.content_type`. Null until the backend populates it.
  final String? contentType;

  /// Whether the target media is a video (drives the ▶ overlay on the preview).
  final bool isVideo;

  final Map<String, dynamic> raw;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final dataField = json['data'];
    final Map<String, dynamic> data = dataField is Map
        ? Map<String, dynamic>.from(dataField)
        : <String, dynamic>{};

    final actorField = json['actor'];
    final Map<String, dynamic> actor = actorField is Map
        ? Map<String, dynamic>.from(actorField)
        : <String, dynamic>{};

    final title = json['title']?.toString() ?? '';
    final body = (json['body'] ?? json['message'])?.toString() ?? '';
    final postId = (data['post_id'] ?? json['post_id'])?.toString();
    final commentId = (data['comment_id'] ?? json['comment_id'])?.toString();
    final chatId = (data['chat_id'] ?? json['chat_id'])?.toString();

    return NotificationItem(
      id: json['id']?.toString() ?? '',
      type: NotificationType.infer(
        json: json,
        data: data,
        title: title,
        body: body,
        postId: postId,
        commentId: commentId,
        chatId: chatId,
      ),
      title: title,
      body: body,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      postId: postId,
      commentId: commentId,
      chatId: chatId,
      actorId: (actor['id'] ?? data['actor_id'])?.toString(),
      actorUsername: actor['username']?.toString(),
      actorImage: (actor['image'] as String?)?.trim().isEmpty ?? true
          ? null
          : actor['image'] as String,
      previewUrl: (data['cover_url'] as String?)?.trim().isEmpty ?? true
          ? null
          : data['cover_url'] as String,
      contentType: data['content_type']?.toString(),
      isVideo: (data['is_video'] as bool?) ?? false,
      raw: data,
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      postId: postId,
      commentId: commentId,
      chatId: chatId,
      actorId: actorId,
      actorUsername: actorUsername,
      actorImage: actorImage,
      previewUrl: previewUrl,
      contentType: contentType,
      isVideo: isVideo,
      raw: raw,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        body,
        isRead,
        createdAt,
        postId,
        commentId,
        chatId,
        actorId,
        actorUsername,
        actorImage,
        previewUrl,
        contentType,
        isVideo,
      ];
}
