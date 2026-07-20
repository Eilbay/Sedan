part of 'chat_bloc.dart';

class ChatState extends Equatable {
  // ignore: type_annotated_public_api
  final bool isLoading;
  final bool isLoadingPaginate;
  final List<String> errors;
  final bool isSuccess;
  final List<Chat> chats;
  final ChatListModel? chatListModel;
  final String? lastMutedUserName;
  final bool isTranslating;

  const ChatState({
    this.isLoading = false,
    this.isLoadingPaginate = false,
    this.errors = const [],
    this.isSuccess = false,
    this.chats = const [],
    this.chatListModel,
    this.lastMutedUserName,
    this.isTranslating = false,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isLoadingPaginate,
    List<String>? errors,
    bool? isSuccess,
    List<Chat>? chats,
    ChatListModel? chatListModel,
    String? lastMutedUserName,
    bool? isTranslating,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingPaginate: isLoadingPaginate ?? this.isLoadingPaginate,
      errors: errors ?? this.errors,
      isSuccess: isSuccess ?? this.isSuccess,
      chats: chats ?? this.chats,
      chatListModel: chatListModel ?? this.chatListModel,
      lastMutedUserName: lastMutedUserName ?? this.lastMutedUserName,
      isTranslating: isTranslating ?? this.isTranslating,
    );
  }

  ChatState addNextPage(List<Chat> newChats, ChatListModel model) {
    final allChats = List<Chat>.from(chats)..addAll(newChats);
    return copyWith(
      chats: allChats,
      chatListModel: model,
    );
  }

  ChatState updateChat(Chat updatedChat) {
    final updatedList = List<Chat>.from(chats);
    final index = updatedList.indexWhere((c) => c.id == updatedChat.id);

    if (index != -1) {
      updatedList.removeAt(index);
    }

    // Insert at correct position (sorted by updatedAt descending)
    int insertAt = 0;
    for (int i = 0; i < updatedList.length; i++) {
      if (updatedChat.updatedAt.compareTo(updatedList[i].updatedAt) >= 0) {
        insertAt = i;
        break;
      }
      insertAt = i + 1;
    }
    updatedList.insert(insertAt, updatedChat);

    return copyWith(chats: updatedList, isSuccess: true);
  }

  @override
  List<Object?> get props => [isLoading, isLoadingPaginate, errors, isSuccess, chats, chatListModel, lastMutedUserName, isTranslating];
}
