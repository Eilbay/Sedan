part of 'message_bloc.dart';

class MessageState extends Equatable {
  final bool isLoading;
  final bool isLoadingPaginate;
  final bool isSending;
  final List<String> errors;

  /// One-shot transient error (e.g. WS BLOCKED reject) — separate from
  /// [errors] so the fetch-error UI is not replaced. Paired with
  /// [transientErrorTick] which increments on every new event so the
  /// listener fires even when the message text repeats.
  final String transientError;
  final int transientErrorTick;
  final bool isSuccess;
  final List<Message> messages;
  final MessageListModel? messageListModel;
  final String? currentChatId;
  final bool isWebSocketConnected;

  const MessageState({
    this.isLoading = false,
    this.isLoadingPaginate = false,
    this.isSending = false,
    this.errors = const [],
    this.transientError = '',
    this.transientErrorTick = 0,
    this.isSuccess = false,
    this.messages = const [],
    this.messageListModel,
    this.currentChatId,
    this.isWebSocketConnected = false,
  });

  MessageState copyWith({
    bool? isLoading,
    bool? isLoadingPaginate,
    bool? isSending,
    List<String>? errors,
    String? transientError,
    int? transientErrorTick,
    bool? isSuccess,
    List<Message>? messages,
    MessageListModel? messageListModel,
    String? currentChatId,
    bool? isWebSocketConnected,
  }) {
    return MessageState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingPaginate: isLoadingPaginate ?? this.isLoadingPaginate,
      isSending: isSending ?? this.isSending,
      errors: errors ?? this.errors,
      transientError: transientError ?? this.transientError,
      transientErrorTick: transientErrorTick ?? this.transientErrorTick,
      isSuccess: isSuccess ?? this.isSuccess,
      messages: messages ?? this.messages,
      messageListModel: messageListModel ?? this.messageListModel,
      currentChatId: currentChatId ?? this.currentChatId,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
    );
  }

  MessageState addNextPage(List<Message> oldMessages, MessageListModel model) {
    final allMessages = List<Message>.from(messages)..addAll(oldMessages);
    return copyWith(
      messages: allMessages,
      messageListModel: model,
    );
  }

  MessageState addNewMessage(Message message) {
    final exists = messages.any((m) => m.id == message.id);
    if (exists) {
      return this;
    }

    final updatedMessages = List<Message>.from(messages)..add(message);
    return copyWith(messages: updatedMessages, isSuccess: true);
  }

  MessageState replaceMessage(String oldId, Message message) {
    final idx = messages.indexWhere((m) => m.id == oldId);
    if (idx == -1) {
      return addNewMessage(message);
    }

    final exists = messages.any((m) => m.id == message.id);
    if (exists) {
      final withoutOld = messages.where((m) => m.id != oldId).toList();
      return copyWith(messages: withoutOld, isSuccess: true);
    }

    final updatedMessages = List<Message>.from(messages);
    updatedMessages[idx] = message;
    return copyWith(messages: updatedMessages, isSuccess: true);
  }

  MessageState removeMessage(String id) {
    final updatedMessages = messages.where((m) => m.id != id).toList();
    if (updatedMessages.length == messages.length) return this;
    return copyWith(messages: updatedMessages);
  }

  MessageState updateUploadProgress(String id, int progress) {
    final idx = messages.indexWhere((m) => m.id == id);
    if (idx == -1) return this;

    final updatedMessages = List<Message>.from(messages);
    updatedMessages[idx] = updatedMessages[idx].copyWith(
      uploadProgress: progress.clamp(0, 100),
    );
    return copyWith(messages: updatedMessages);
  }

  bool get hasPendingAttachmentMessage =>
      messages.any((m) => m.isPending && m.hasAttachment);

  /// Insert a new message, or replace an existing one with the same id. Used
  /// for WebSocket frames: a re-broadcast of an existing message (e.g. with
  /// `is_read` flipped to true after the recipient read it) must update the
  /// bubble in place so its checkmark refreshes — the old add-only logic
  /// ignored same-id frames and the double-check never appeared live.
  MessageState upsertMessage(Message message) {
    final idx = messages.indexWhere((m) => m.id == message.id);
    if (idx == -1) {
      final updatedMessages = List<Message>.from(messages)..add(message);
      return copyWith(messages: updatedMessages, isSuccess: true);
    }
    final updatedMessages = List<Message>.from(messages);
    updatedMessages[idx] = message;
    return copyWith(messages: updatedMessages);
  }

  MessageState markAsRead() {
    final updatedMessages =
        messages.map((m) => m.copyWith(isRead: true)).toList();
    return copyWith(messages: updatedMessages);
  }

  /// Flip the given message ids to read. Empty [ids] flips every message
  /// (chat-level "all read" receipt). Incoming messages carry no checkmark,
  /// so marking them read is harmless.
  MessageState markRead(List<String> ids) {
    if (ids.isEmpty) return markAsRead();
    final idSet = ids.toSet();
    final updatedMessages = messages
        .map((m) => idSet.contains(m.id) ? m.copyWith(isRead: true) : m)
        .toList();
    return copyWith(messages: updatedMessages);
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoadingPaginate,
        isSending,
        errors,
        transientError,
        transientErrorTick,
        isSuccess,
        messages,
        messageListModel,
        currentChatId,
        isWebSocketConnected,
      ];
}
