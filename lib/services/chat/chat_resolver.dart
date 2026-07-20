import 'package:optombai/data/models/chat/chat_model.dart';
import 'package:optombai/data/repositories/i_chat_repository.dart';

/// Resolves a [Chat] by its id for deep navigation (push-notification taps and
/// notification-list taps).
///
/// [IChatRepository] exposes only a paginated [IChatRepository.fetchChats] —
/// there is no fetch-by-id endpoint — so on a cache miss this pages through the
/// chat list until the id is found or the pages run out. Mirrors the reel
/// deep-link resolver in `app.dart`.
class ChatResolver {
  ChatResolver(this._repository);

  final IChatRepository _repository;

  Future<Chat?> resolveById({
    required String chatId,
    required String token,
    List<Chat> cached = const [],
  }) async {
    final cachedMatch = _findById(cached, chatId);
    if (cachedMatch != null) return cachedMatch;

    var page = await _repository.fetchChats(token);
    var match = _findById(page.results, chatId);
    while (match == null && page.next != null) {
      page = await _repository.fetchChats(token, nextUrl: page.next);
      match = _findById(page.results, chatId);
    }
    return match;
  }

  Chat? _findById(List<Chat> chats, String chatId) {
    for (final chat in chats) {
      if (chat.id == chatId) return chat;
    }
    return null;
  }
}
