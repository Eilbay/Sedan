part of 'message_bloc.dart';

abstract class MessageEvent extends Equatable {}

class FetchMessagesEvent extends MessageEvent {
  final String chatId;

  FetchMessagesEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class FetchNextMessagesPageEvent extends MessageEvent {
  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends MessageEvent {
  final String chatId;
  final String text;
  final MessageType type;
  final File? attachment;
  final ChatUser? sender;

  SendMessageEvent({
    required this.chatId,
    required this.text,
    this.type = MessageType.text,
    this.attachment,
    this.sender,
  });

  @override
  List<Object?> get props => [chatId, text, type, attachment, sender];
}

class ConnectWebSocketEvent extends MessageEvent {
  final String chatId;

  ConnectWebSocketEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class MessageUploadProgressChangedEvent extends MessageEvent {
  final String messageId;
  final int progress;

  MessageUploadProgressChangedEvent({
    required this.messageId,
    required this.progress,
  });

  @override
  List<Object?> get props => [messageId, progress];
}

class DisconnectWebSocketEvent extends MessageEvent {
  @override
  List<Object?> get props => [];
}

class NewMessageFromWebSocketEvent extends MessageEvent {
  final Message message;

  NewMessageFromWebSocketEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatWsErrorEvent extends MessageEvent {
  final ChatWsError error;

  ChatWsErrorEvent(this.error);

  @override
  List<Object?> get props => [error.code, error.detail];
}

/// The other participant read messages — delivered over the chat WebSocket.
/// [messageIds] empty means "all messages in this chat were read" (flip every
/// outgoing message to double-check); a non-empty list flips only those ids.
class MessagesReadFromWebSocketEvent extends MessageEvent {
  final List<String> messageIds;

  MessagesReadFromWebSocketEvent(this.messageIds);

  @override
  List<Object?> get props => [messageIds];
}

class MarkMessagesAsReadEvent extends MessageEvent {
  final String chatId;

  MarkMessagesAsReadEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class ClearMessagesEvent extends MessageEvent {
  @override
  List<Object?> get props => [];
}
