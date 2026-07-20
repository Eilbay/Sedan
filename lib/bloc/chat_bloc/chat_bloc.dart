import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/chat/chat_model.dart';
import 'package:optombai/data/repositories/i_chat_repository.dart';
import 'package:optombai/services/chat_auth_guard.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final IChatRepository _repository;
  final SharedPreferences preferences;

  ChatBloc({required IChatRepository repository, required this.preferences})
      : _repository = repository,
        super(const ChatState()) {
    on<FetchChatsEvent>(_onFetchChats);
    on<FetchNextChatsPageEvent>(_onFetchNextPage);
    on<CreatePersonalChatEvent>(_onCreatePersonalChat);
    on<CreateGroupChatEvent>(_onCreateGroupChat);
    on<UpdateChatEvent>(_onUpdateChat);
    on<UpdateUnreadCountEvent>(_onUpdateUnreadCount);
    on<ClearChatsEvent>(_onClearChats);
    on<MuteUserEvent>(_onMuteUser);
    on<UnmuteUserEvent>(_onUnmuteUser);
    on<CheckTranslateStatusEvent>(_onCheckTranslateStatus);
    on<TranslateChatEvent>(_onTranslateChat);
    on<DeleteChatEvent>(_onDeleteChat);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  Future<String> _requireToken() => getIt<ChatAuthGuard>().requireToken();

  _onFetchChats(FetchChatsEvent event, emit) async {
    emit(state.copyWith(isLoading: state.chats.isEmpty));
    try {
      final chatListModel = await _repository.fetchChats(await _requireToken());
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        chats: chatListModel.results,
        chatListModel: chatListModel,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    }
  }

  _onFetchNextPage(FetchNextChatsPageEvent event, emit) async {
    try {
      final model = state.chatListModel;
      if (model?.next != null) {
        emit(state.copyWith(isLoadingPaginate: true));

        final nextModel = await _repository.fetchChats(
          await _requireToken(),
          nextUrl: model!.next,
        );

        emit(state.addNextPage(nextModel.results, nextModel));
      }
    } on AppException catch (e) {
      emit(state.copyWith(
        errors: e.messages,
        isLoadingPaginate: false,
      ));
    }
  }

  _onCreatePersonalChat(CreatePersonalChatEvent event, emit) async {
    // Clear stale errors so callers awaiting `errors.isNotEmpty || hasChat`
    // don't trip on a previous operation's failure and show its snackbar
    // on top of this successful chat creation.
    emit(state.copyWith(isLoading: true, errors: const []));
    try {
      final chat = await _repository.startPersonalChat(
        event.userId,
        await _requireToken(),
        productId: event.productId,
      );
      emit(state.updateChat(chat).copyWith(isLoading: false));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    }
  }

  _onCreateGroupChat(CreateGroupChatEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final chat = await _repository.createGroupChat(
        title: event.title,
        participantIds: event.participantIds,
        token: await _requireToken(),
      );
      emit(state.updateChat(chat).copyWith(isLoading: false));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    }
  }

  _onUpdateChat(UpdateChatEvent event, emit) {
    emit(state.updateChat(event.chat));
  }

  _onUpdateUnreadCount(UpdateUnreadCountEvent event, emit) {
    final index = state.chats.indexWhere((c) => c.id == event.chatId);
    if (index == -1) return;

    final updated = state.chats[index].copyWith(unreadCount: event.unreadCount);
    emit(state.updateChat(updated));
  }

  _onClearChats(ClearChatsEvent event, emit) {
    emit(const ChatState());
  }

  _onMuteUser(MuteUserEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.muteUser(
        chatId: event.chatId,
        userId: event.userId,
        token: await _requireToken(),
        minutes: event.minutes,
        until: event.until,
        reason: event.reason,
      );
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        lastMutedUserName: event.userName,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    }
  }

  _onUnmuteUser(UnmuteUserEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.unmuteUser(
        chatId: event.chatId,
        userId: event.userId,
        token: await _requireToken(),
      );
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    }
  }

  _onCheckTranslateStatus(CheckTranslateStatusEvent event, emit) async {
    try {
      final status = await _repository.getTranslateStatus(
        event.chatId,
        await _requireToken(),
      );

      final int total = status['total'] ?? 0;
      final int done = status['done'] ?? 0;

      if (total > 0 && done < total) {
        emit(state.copyWith(isTranslating: true));

        try {
          await _repository.translateChat(
            chatId: event.chatId,
            isGroup: event.isGroup,
            token: await _requireToken(),
          );

          await Future.delayed(const Duration(seconds: 3));
          emit(state.copyWith(isTranslating: false));
        } catch (translateError) {
          emit(state.copyWith(
            isTranslating: false,
            errors: [translateError.toString()],
          ));
        }
      }
    } on AppException catch (e) {
      // ignore: avoid_print
      print('Translation status check error: ${e.message}');
    }
  }

  _onTranslateChat(TranslateChatEvent event, emit) async {
    try {
      emit(state.copyWith(isTranslating: true));

      await _repository.translateChat(
        chatId: event.chatId,
        isGroup: event.isGroup,
        token: await _requireToken(),
      );

      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(isTranslating: false));
    } on AppException catch (e) {
      emit(state.copyWith(
        isTranslating: false,
        errors: e.messages,
      ));
    }
  }

  _onDeleteChat(DeleteChatEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.deleteChat(event.chatId, await _requireToken());

      final updatedChats =
          state.chats.where((c) => c.id != event.chatId).toList();
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        chats: updatedChats,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: [e.toString()],
      ));
    }
  }
}
