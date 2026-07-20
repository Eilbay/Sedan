import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/chat/chat_model.dart';
import 'package:optombai/widgets/utils/gradient_avatar.dart';
import 'package:optombai/widgets/utils/live_ring_avatar.dart';

class ChatCard extends StatelessWidget {
  final Chat chat;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Opens the other participant's profile. Null for support chats.
  final VoidCallback? onAvatarTap;
  final bool isSupportChat;

  const ChatCard({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
    this.onAvatarTap,
    this.isSupportChat = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final title =
        isSupportChat ? "Поддержка " : chat.getDisplayTitle(currentUserId);

    final otherUser = chat.getOtherParticipant(currentUserId);
    final lastMessageText = chat.lastMessage?.text ?? "Нет сообщений";
    final hasUnread = chat.unreadCount > 0;

    final Color titleColor = hasUnread
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.white70 : Colors.black87);

    final Color subtitleColor = hasUnread
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.white60 : Colors.grey);

    final Color timeColor = isDark ? Colors.white54 : Colors.grey;

    final Color avatarBgColor = isSupportChat
        ? Colors.blue
        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xffF0F0F0));

    final Color avatarTextColor = isDark ? Colors.white : Colors.black87;

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: isSupportChat
          ? GradientAvatar(
              radius: 26,
              backgroundColor: avatarBgColor,
              child: const Icon(Icons.support_agent, color: Colors.white),
            )
          : LiveRingAvatar(
              radius: 26,
              ownerId: otherUser?.id ?? '',
              imageUrl: otherUser?.image,
              backgroundColor: avatarBgColor,
              onTap: onAvatarTap,
              notLiveRingBuilder: (avatar) => Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: avatar,
              ),
              child: Text(
                title.isNotEmpty ? title[0].toUpperCase() : '?',
                style: TextStyle(
                  color: avatarTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          lastMessageText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: subtitleColor,
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
      trailing: Text(
        _formatTime(chat.updatedAt),
        style: TextStyle(
          fontSize: 12,
          color: timeColor,
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final parts = timestamp.split(' ');
      if (parts.length == 2) {
        final timeParts = parts[1].split(':');
        return '${timeParts[0]}:${timeParts[1]}';
      }
    } catch (e) {
      //
    }
    return '';
  }
}
