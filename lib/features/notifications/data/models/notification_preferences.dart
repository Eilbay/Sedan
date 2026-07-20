import 'package:equatable/equatable.dart';

class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    required this.messagesEnabled,
    required this.likesEnabled,
    required this.commentsEnabled,
  });

  final bool messagesEnabled;
  final bool likesEnabled;
  final bool commentsEnabled;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      messagesEnabled: (json['messages_enabled'] as bool?) ?? true,
      likesEnabled: (json['likes_enabled'] as bool?) ?? true,
      commentsEnabled: (json['comments_enabled'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'messages_enabled': messagesEnabled,
        'likes_enabled': likesEnabled,
        'comments_enabled': commentsEnabled,
      };

  NotificationPreferences copyWith({
    bool? messagesEnabled,
    bool? likesEnabled,
    bool? commentsEnabled,
  }) {
    return NotificationPreferences(
      messagesEnabled: messagesEnabled ?? this.messagesEnabled,
      likesEnabled: likesEnabled ?? this.likesEnabled,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
    );
  }

  @override
  List<Object?> get props => [messagesEnabled, likesEnabled, commentsEnabled];
}
