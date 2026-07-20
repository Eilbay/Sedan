part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {}

class FetchChatsEvent extends ChatEvent {
  @override
  List<Object?> get props => [];
}

class FetchNextChatsPageEvent extends ChatEvent {
  @override
  List<Object?> get props => [];
}

class CreatePersonalChatEvent extends ChatEvent {
  final String userId;
  final String? productId;

  CreatePersonalChatEvent(this.userId, {this.productId});

  @override
  List<Object?> get props => [userId, productId];
}

class CreateGroupChatEvent extends ChatEvent {
  final String title;
  final List<String> participantIds;

  CreateGroupChatEvent({
    required this.title,
    required this.participantIds,
  });

  @override
  List<Object?> get props => [title, participantIds];
}

class UpdateChatEvent extends ChatEvent {
  final Chat chat;

  UpdateChatEvent(this.chat);

  @override
  List<Object?> get props => [chat];
}

class UpdateUnreadCountEvent extends ChatEvent {
  final String chatId;
  final int unreadCount;

  UpdateUnreadCountEvent({
    required this.chatId,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [chatId, unreadCount];
}

class ClearChatsEvent extends ChatEvent {
  @override
  List<Object?> get props => [];
}

class MuteUserEvent extends ChatEvent {
  final String chatId;
  final String userId;
  final String? userName;
  final int? minutes;
  final String? until;
  final String? reason;

  MuteUserEvent({
    required this.chatId,
    required this.userId,
    this.userName,
    this.minutes,
    this.until,
    this.reason,
  });

  @override
  List<Object?> get props => [chatId, userId, userName, minutes, until, reason];
}

class UnmuteUserEvent extends ChatEvent {
  final String chatId;
  final String userId;

  UnmuteUserEvent({
    required this.chatId,
    required this.userId,
  });

  @override
  List<Object?> get props => [chatId, userId];
}

class CheckTranslateStatusEvent extends ChatEvent {
  final String chatId;
  final bool isGroup;

  CheckTranslateStatusEvent({
    required this.chatId,
    required this.isGroup,
  });

  @override
  List<Object?> get props => [chatId, isGroup];
}

class TranslateChatEvent extends ChatEvent {
  final String chatId;
  final bool isGroup;

  TranslateChatEvent({
    required this.chatId,
    required this.isGroup,
  });

  @override
  List<Object?> get props => [chatId, isGroup];
}

class DeleteChatEvent extends ChatEvent {
  final String chatId;

  DeleteChatEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}
