import 'package:optombai/features/notifications/data/models/notification_item.dart';

/// Parsed push-notification `data` payload. Built from
/// `RemoteMessage.data` (firebase_messaging) for both foreground and tap
/// scenarios.
class PushPayload {
  const PushPayload({
    required this.type,
    this.title,
    this.body,
    this.postId,
    this.commentId,
    this.chatId,
  });

  final NotificationType type;
  final String? title;
  final String? body;
  final String? postId;
  final String? commentId;
  final String? chatId;

  factory PushPayload.fromMessage({
    Map<String, dynamic> data = const {},
    String? title,
    String? body,
  }) {
    return PushPayload(
      type: NotificationType.fromApi(data['type']?.toString()),
      title: title,
      body: body,
      postId: data['post_id']?.toString(),
      commentId: data['comment_id']?.toString(),
      chatId: data['chat_id']?.toString(),
    );
  }
}
