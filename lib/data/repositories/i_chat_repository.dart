import 'dart:io';

import 'package:optombai/data/models/chat/chat_model.dart';
import 'package:optombai/data/models/chat/message_model.dart';

abstract interface class IChatRepository {
  Future<Chat> startPersonalChat(
    String userId,
    String token, {
    String? productId,
  });

  Future<Chat> createGroupChat({
    required String title,
    required List<String> participantIds,
    required String token,
  });

  Future<ChatListModel> fetchChats(String token, {String? nextUrl});

  Future<MessageListModel> fetchMessages(
    String chatId,
    String token, {
    String? nextUrl,
  });

  Future<Message> sendMessage({
    required String chatId,
    required String text,
    required MessageType type,
    File? attachment,
    required String token,
    void Function(int sent, int total)? onSendProgress,
  });

  Future<int> markMessagesAsRead(String chatId, String token);

  Future<void> muteUser({
    required String chatId,
    required String userId,
    required String token,
    int? minutes,
    String? until,
    String? reason,
  });

  Future<void> unmuteUser({
    required String chatId,
    required String userId,
    required String token,
  });

  Future<Map<String, dynamic>> getTranslateStatus(
    String chatId,
    String token,
  );

  Future<void> translateChat({
    required String chatId,
    required bool isGroup,
    required String token,
  });

  Future<void> deleteChat(String chatId, String token);
}
