import 'package:flutter/foundation.dart';

/// Holds the id of the chat conversation that is currently open in the
/// foreground. Used by [PushNotificationService] to suppress local
/// notifications for messages that arrive in the chat the user is
/// already looking at.
class CurrentChatTracker {
  CurrentChatTracker._();

  static final CurrentChatTracker instance = CurrentChatTracker._();

  final ValueNotifier<String?> openChatId = ValueNotifier<String?>(null);

  void setOpen(String? chatId) {
    openChatId.value = chatId;
  }

  bool isOpen(String? chatId) {
    if (chatId == null || chatId.isEmpty) return false;
    return openChatId.value == chatId;
  }
}
