import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/chat/chat_user.dart';
import 'package:optombai/data/models/chat/linked_post.dart';
import 'package:optombai/data/models/chat/message_model.dart';

class Chat extends Equatable {
  final String id;
  final List<ChatUser> participants;
  final ChatUser? owner;
  final bool isGroup;
  final String title;
  final Message? lastMessage;
  final bool isClosed;
  final String updatedAt;
  final int unreadCount;
  final List<ChatUser> admins;
  final List<ChatUser> moderators;
  final LinkedPost? linkedPost;
  final bool wasCreated;

  const Chat({
    required this.id,
    required this.participants,
    this.owner,
    this.isGroup = false,
    this.title = "",
    this.lastMessage,
    this.isClosed = false,
    required this.updatedAt,
    this.unreadCount = 0,
    this.admins = const [],
    this.moderators = const [],
    this.linkedPost,
    this.wasCreated = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? "",
      participants: (json['participants'] as List?)
              ?.map((p) => ChatUser.fromJson(p))
              .toList() ??
          [],
      owner: json['owner'] != null ? ChatUser.fromJson(json['owner']) : null,
      isGroup: json['is_group'] ?? false,
      title: json['title'] ?? "",
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      isClosed: json['is_closed'] ?? false,
      updatedAt: json['updated_at'] ?? "",
      unreadCount: json['unread_count'] ?? 0,
      admins: (json['admins'] as List?)
              ?.map((a) => ChatUser.fromJson(a))
              .toList() ??
          [],
      moderators: (json['moderators'] as List?)
              ?.map((m) => ChatUser.fromJson(m))
              .toList() ??
          [],
      linkedPost: json['linked_post'] != null
          ? LinkedPost.fromJson(json['linked_post'])
          : null,
      wasCreated: json['was_created'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participants': participants.map((p) => p.toJson()).toList(),
        'owner': owner?.toJson(),
        'is_group': isGroup,
        'title': title,
        'last_message': lastMessage?.toJson(),
        'is_closed': isClosed,
        'updated_at': updatedAt,
        'admins': admins.map((a) => a.toJson()).toList(),
        'moderators': moderators.map((m) => m.toJson()).toList(),
        'linked_post': linkedPost?.toJson(),
        'was_created': wasCreated,
      };

  Chat copyWith({
    String? id,
    List<ChatUser>? participants,
    ChatUser? owner,
    bool? isGroup,
    String? title,
    Message? lastMessage,
    bool? isClosed,
    String? updatedAt,
    int? unreadCount,
    List<ChatUser>? admins,
    List<ChatUser>? moderators,
    LinkedPost? linkedPost,
    bool? wasCreated,
  }) {
    return Chat(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      owner: owner ?? this.owner,
      isGroup: isGroup ?? this.isGroup,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      isClosed: isClosed ?? this.isClosed,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      admins: admins ?? this.admins,
      moderators: moderators ?? this.moderators,
      linkedPost: linkedPost ?? this.linkedPost,
      wasCreated: wasCreated ?? this.wasCreated,
    );
  }

  ChatUser? getOtherParticipant(String currentUserId) {
    if (isGroup) return null;
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  String getDisplayTitle(String currentUserId) {
    if (isGroup) {
      return title.isNotEmpty ? title : "Групповой чат";
    }
    final other = getOtherParticipant(currentUserId);
    return other?.displayName ?? "Чат";
  }

  bool canMute(String currentUserId) {
    if (!isGroup) return true;

    return admins.any((a) => a.id == currentUserId) ||
        moderators.any((m) => m.id == currentUserId);
  }

  @override
  List<Object?> get props => [
        id,
        participants,
        owner,
        isGroup,
        title,
        lastMessage,
        isClosed,
        updatedAt,
        unreadCount,
        admins,
        moderators,
        linkedPost,
        wasCreated,
      ];
}

class ChatListModel extends Equatable {
  final int count;
  final String? next;
  final String? previous;
  final List<Chat> results;

  const ChatListModel({
    this.count = 0,
    this.next,
    this.previous,
    this.results = const [],
  });

  factory ChatListModel.fromJson(Map<String, dynamic> json) {
    return ChatListModel(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results:
          (json['results'] as List?)?.map((c) => Chat.fromJson(c)).toList() ??
              [],
    );
  }

  ChatListModel copyWith({
    int? count,
    String? next,
    String? previous,
    List<Chat>? results,
  }) {
    return ChatListModel(
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }

  @override
  List<Object?> get props => [count, next, previous, results];
}

class MessageListModel extends Equatable {
  final int count;
  final String? next;
  final String? previous;
  final List<Message> results;

  const MessageListModel({
    this.count = 0,
    this.next,
    this.previous,
    this.results = const [],
  });

  factory MessageListModel.fromJson(Map<String, dynamic> json) {
    return MessageListModel(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)
              ?.map((m) => Message.fromJson(m))
              .toList() ??
          [],
    );
  }

  MessageListModel copyWith({
    int? count,
    String? next,
    String? previous,
    List<Message>? results,
  }) {
    return MessageListModel(
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }

  @override
  List<Object?> get props => [count, next, previous, results];
}
