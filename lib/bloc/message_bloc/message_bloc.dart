import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/chat/chat_model.dart';
import 'package:optombai/data/models/chat/chat_user.dart';
import 'package:optombai/data/models/chat/message_model.dart';
import 'package:optombai/data/repositories/i_chat_repository.dart';
import 'package:optombai/data/services/websocket_service.dart';
import 'package:optombai/services/chat_auth_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final IChatRepository _repository;
  final SharedPreferences preferences;
  final WebSocketService _webSocketService = WebSocketService();

  StreamSubscription<Message>? _wsSubscription;
  StreamSubscription<ChatWsError>? _wsErrorSubscription;
  StreamSubscription<ChatReadReceipt>? _wsReadSubscription;

  MessageBloc({
    required IChatRepository repository,
    required this.preferences,
  })  : _repository = repository,
        super(const MessageState()) {
    on<FetchMessagesEvent>(_onFetchMessages);
    on<FetchNextMessagesPageEvent>(_onFetchNextPage);
    on<SendMessageEvent>(_onSendMessage);
    on<ConnectWebSocketEvent>(_onConnectWebSocket);
    on<MessageUploadProgressChangedEvent>(_onUploadProgressChanged);
    on<DisconnectWebSocketEvent>(_onDisconnectWebSocket);
    on<NewMessageFromWebSocketEvent>(_onNewMessageFromWebSocket);
    on<MessagesReadFromWebSocketEvent>(_onMessagesRead);
    on<ChatWsErrorEvent>(_onChatWsError);
    on<MarkMessagesAsReadEvent>(_onMarkAsRead);
    on<ClearMessagesEvent>(_onClearMessages);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? '';

  Future<String> _requireToken() {
    return getIt<ChatAuthGuard>().requireToken();
  }

  Future<void> _onFetchMessages(
    FetchMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        isLoadingPaginate: false,
        currentChatId: event.chatId,
      ),
    );

    try {
      final messageListModel = await _repository.fetchMessages(
        event.chatId,
        await _requireToken(),
      );

      emit(
        state.copyWith(
          isLoading: false,
          isLoadingPaginate: false,
          isSuccess: true,
          messages: messageListModel.results.reversed.toList(),
          messageListModel: messageListModel,
        ),
      );
    } on AppException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isLoadingPaginate: false,
          errors: e.messages,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Fetch messages error: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(
        state.copyWith(
          isLoading: false,
          isLoadingPaginate: false,
          errors: const ['Не удалось загрузить сообщения'],
        ),
      );
    }
  }

  Future<void> _onFetchNextPage(
    FetchNextMessagesPageEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state.isLoading || state.isLoadingPaginate) return;

    final model = state.messageListModel;
    final nextUrl = model?.next;
    final chatId = state.currentChatId;

    if (nextUrl == null || nextUrl.isEmpty) return;
    if (chatId == null || chatId.isEmpty) return;

    emit(state.copyWith(isLoadingPaginate: true));

    try {
      final nextModel = await _repository.fetchMessages(
        chatId,
        await _requireToken(),
        nextUrl: nextUrl,
      );

      final nextState = state.addNextPage(
        nextModel.results.reversed.toList(),
        nextModel,
      );

      emit(
        nextState.copyWith(
          isLoadingPaginate: false,
        ),
      );
    } on AppException catch (e) {
      emit(
        state.copyWith(
          errors: e.messages,
          isLoadingPaginate: false,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Fetch next messages page error: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(
        state.copyWith(
          isLoadingPaginate: false,
          errors: const ['Не удалось загрузить предыдущие сообщения'],
        ),
      );
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    final pendingId = event.attachment == null
        ? null
        : 'pending-${DateTime.now().microsecondsSinceEpoch}';

    final pendingMessage = pendingId == null
        ? null
        : Message(
            id: pendingId,
            chatId: event.chatId,
            sender: event.sender,
            type: event.type,
            text: event.text,
            attachment: event.attachment!.path,
            createdAt: _formatLocalCreatedAt(DateTime.now()),
            isRead: false,
            isPending: true,
            uploadProgress: 0,
          );

    emit(
      (pendingMessage == null ? state : state.addNewMessage(pendingMessage))
          .copyWith(
        isSending: true,
        transientError: '',
      ),
    );

    try {
      final message = await _repository.sendMessage(
        chatId: event.chatId,
        text: event.text,
        type: event.type,
        attachment: event.attachment,
        token: await _requireToken(),
        onSendProgress: pendingId == null
            ? null
            : (sent, total) {
                if (total <= 0) return;

                final progress = ((sent / total) * 100).round().clamp(0, 100);

                add(
                  MessageUploadProgressChangedEvent(
                    messageId: pendingId,
                    progress: progress,
                  ),
                );
              },
      );

      final nextState = pendingId == null
          ? state.addNewMessage(message)
          : state.replaceMessage(pendingId, message);

      emit(nextState.copyWith(isSending: false));
    } on BlockedException catch (_) {
      // Don't replace the chat history with the error — show as snackbar.
      // Fixed copy regardless of the server's detail text, per product
      // requirement: the reason is always "recipient restricted chat access".
      final nextState =
          pendingId == null ? state : state.removeMessage(pendingId);
      emit(nextState.copyWith(
        isSending: false,
        transientError:
            'Вы не можете отправить сообщение — пользователь ограничил вам доступ к чату',
        transientErrorTick: state.transientErrorTick + 1,
      ));
    } on AppException catch (e) {
      final nextState =
          pendingId == null ? state : state.removeMessage(pendingId);

      emit(
        nextState.copyWith(
          errors: e.messages,
          isSending: false,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Send message error: $e');
      debugPrintStack(stackTrace: stackTrace);

      final nextState =
          pendingId == null ? state : state.removeMessage(pendingId);

      emit(
        nextState.copyWith(
          errors: const ['Не удалось отправить сообщение'],
          isSending: false,
        ),
      );
    }
  }

  String _formatLocalCreatedAt(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}:${two(dateTime.second)}';
  }

  void _onUploadProgressChanged(
    MessageUploadProgressChangedEvent event,
    Emitter<MessageState> emit,
  ) {
    emit(state.updateUploadProgress(event.messageId, event.progress));
  }

  Future<void> _onConnectWebSocket(
    ConnectWebSocketEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      final token = await _requireToken();

      _webSocketService.connect(event.chatId, token);

      await _wsSubscription?.cancel();
      _wsSubscription = _webSocketService.messageStream.listen((message) {
        add(NewMessageFromWebSocketEvent(message));
      });

      await _wsErrorSubscription?.cancel();
      _wsErrorSubscription = _webSocketService.errorStream.listen((error) {
        add(ChatWsErrorEvent(error));
      });

      await _wsReadSubscription?.cancel();
      _wsReadSubscription = _webSocketService.readStream.listen((receipt) {
        add(MessagesReadFromWebSocketEvent(receipt.messageIds));
      });

      emit(state.copyWith(isWebSocketConnected: true));
    } catch (e, stackTrace) {
      debugPrint('WebSocket connection failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(
        state.copyWith(
          errors: ['WebSocket connection failed: $e'],
          isWebSocketConnected: false,
        ),
      );
    }
  }

  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocketEvent event,
    Emitter<MessageState> emit,
  ) async {
    await _wsSubscription?.cancel();
    await _wsErrorSubscription?.cancel();
    await _wsReadSubscription?.cancel();

    _wsSubscription = null;
    _wsErrorSubscription = null;
    _wsReadSubscription = null;

    _webSocketService.disconnect();

    emit(state.copyWith(isWebSocketConnected: false));
  }

  void _onNewMessageFromWebSocket(
    NewMessageFromWebSocketEvent event,
    Emitter<MessageState> emit,
  ) {
    emit(state.upsertMessage(event.message));
  }

  void _onMessagesRead(
    MessagesReadFromWebSocketEvent event,
    Emitter<MessageState> emit,
  ) {
    emit(state.markRead(event.messageIds));
  }

  void _onChatWsError(
    ChatWsErrorEvent event,
    Emitter<MessageState> emit,
  ) {
    final detail = event.error.detail.isNotEmpty
        ? event.error.detail
        : event.error.code == 'BLOCKED'
            ? 'Вы не можете писать этому пользователю'
            : 'Ошибка чата';

    emit(
      state.copyWith(
        transientError: detail,
        transientErrorTick: state.transientErrorTick + 1,
      ),
    );
  }

  Future<void> _onMarkAsRead(
    MarkMessagesAsReadEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      final token = await _requireToken();

      await _repository.markMessagesAsRead(event.chatId, token);

      final messageListModel = await _repository.fetchMessages(
        event.chatId,
        token,
      );

      emit(
        state.copyWith(
          messages: messageListModel.results.reversed.toList(),
          messageListModel: messageListModel,
        ),
      );
    } on AppException catch (e) {
      debugPrint('Failed to mark as read: ${e.messages}');
    } catch (e, stackTrace) {
      debugPrint('Failed to mark as read: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _onClearMessages(
    ClearMessagesEvent event,
    Emitter<MessageState> emit,
  ) {
    emit(const MessageState());
  }

  @override
  Future<void> close() async {
    await _wsSubscription?.cancel();
    await _wsErrorSubscription?.cancel();
    await _wsReadSubscription?.cancel();

    _webSocketService.dispose();

    return super.close();
  }
}
