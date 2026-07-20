import 'dart:io';
import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/chat/chat_model.dart';
import 'package:optombai/data/models/chat/message_model.dart';
import 'package:optombai/data/repositories/i_chat_repository.dart';

class ChatRepository implements IChatRepository {
  final Dio _dio = ApiClient.I.dio;
  static const int _maxAttachmentFileNameLength = 100;

  /// POST /chat/start/
  @override
  Future<Chat> startPersonalChat(
    String userId,
    String token, {
    String? productId,
  }) async {
    try {
      final response = await _dio.post(
        "${ApiEndpoints.chatApi}/start/",
        data: {
          'user_id': userId,
          if (productId != null && productId.isNotEmpty)
            'product_id': productId,
        },
        options: options(token),
      );

      return Chat.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// POST /chat/group/
  @override
  Future<Chat> createGroupChat({
    required String title,
    required List<String> participantIds,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        "${ApiEndpoints.chatApi}/group/",
        data: {
          'title': title,
          'participant_ids': participantIds,
        },
        options: options(token),
      );

      return Chat.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// GET /chats/
  @override
  Future<ChatListModel> fetchChats(String token, {String? nextUrl}) async {
    try {
      final response = await _dio.get(
        nextUrl ?? ApiEndpoints.chatsListApi,
        options: options(token),
      );

      return ChatListModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// GET /chat/{chat_id}/messages/
  @override
  Future<MessageListModel> fetchMessages(
    String chatId,
    String token, {
    String? nextUrl,
  }) async {
    try {
      final response = await _dio.get(
        nextUrl ?? "${ApiEndpoints.chatApi}/$chatId/messages/",
        options: options(token),
      );

      return MessageListModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// POST /chat/{chat_id}/messages/
  @override
  Future<Message> sendMessage({
    required String chatId,
    required String text,
    required MessageType type,
    File? attachment,
    required String token,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'text': text,
        'type': type.toServerString(),
        if (attachment != null)
          'attachment': await MultipartFile.fromFile(
            attachment.path,
            filename: _buildUploadFileName(attachment),
          ),
      });

      final response = await _dio.post(
        "${ApiEndpoints.chatApi}/$chatId/messages/",
        data: formData,
        options: optionsFormData(token),
        onSendProgress: onSendProgress,
      );

      return Message.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  String _buildUploadFileName(File attachment) {
    final original = attachment.path.split('/').last;
    if (original.length <= _maxAttachmentFileNameLength) {
      return original;
    }

    final dotIndex = original.lastIndexOf('.');
    final hasExtension = dotIndex > 0 && dotIndex < original.length - 1;
    final extension = hasExtension ? original.substring(dotIndex) : '';
    final baseName = hasExtension ? original.substring(0, dotIndex) : original;
    final maxBaseLength = _maxAttachmentFileNameLength - extension.length;

    if (maxBaseLength <= 0) {
      return original.substring(0, _maxAttachmentFileNameLength);
    }

    return '${baseName.substring(0, maxBaseLength)}$extension';
  }

  /// POST /chat/{chat_id}/messages/read/
  @override
  Future<int> markMessagesAsRead(String chatId, String token) async {
    try {
      final response = await _dio.post(
        "${ApiEndpoints.chatApi}/$chatId/messages/read/",
        options: options(token),
      );

      return response.data['updated'] ?? 0;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// POST /chat/{chat_id}/mute/
  @override
  Future<void> muteUser({
    required String chatId,
    required String userId,
    required String token,
    int? minutes,
    String? until,
    String? reason,
  }) async {
    try {
      final data = {
        'user_id': userId,
        if (minutes != null) 'minutes': minutes,
        if (until != null) 'until': until,
        if (reason != null) 'reason': reason,
      };

      await _dio.post(
        "${ApiEndpoints.chatApi}/$chatId/mute/",
        data: data,
        options: options(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// POST /chat/{chat_id}/unmute/
  @override
  Future<void> unmuteUser({
    required String chatId,
    required String userId,
    required String token,
  }) async {
    try {
      await _dio.post(
        "${ApiEndpoints.chatApi}/$chatId/unmute/",
        data: {'user_id': userId},
        options: options(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// GET /chats/{chat_id}/translate-status/
  @override
  Future<Map<String, dynamic>> getTranslateStatus(
    String chatId,
    String token,
  ) async {
    try {
      final response = await _dio.get(
        "${ApiEndpoints.chatsListApi}$chatId/translate-status/",
        options: options(token),
      );

      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// POST /chats/{chat_id}/translate/
  @override
  Future<void> translateChat({
    required String chatId,
    required bool isGroup,
    required String token,
  }) async {
    try {
      await _dio.post(
        "${ApiEndpoints.chatsListApi}$chatId/translate/",
        options: options(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// POST /chats/{chat_id}/delete/
  @override
  Future<void> deleteChat(String chatId, String token) async {
    try {
      final response = await _dio.post(
        "${ApiEndpoints.chatsListApi}$chatId/delete/",
        options: options(token),
      );

      final deleted = response.data['deleted'] ?? false;
      if (!deleted) {
        throw const ServerException(message: 'Chat was not deleted');
      }
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
