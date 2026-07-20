import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/data/repositories/i_user_repository.dart';
import 'package:optombai/features/live_stream/presentation/logic/live_chat_cubit.dart';

/// Pure UI widget for live chat. All WebSocket logic lives in [LiveChatCubit].
class LiveChatWidget extends StatefulWidget {
  const LiveChatWidget({
    super.key,
    this.streamOwnerUsername,
    this.streamOwnerAvatarUrl,
    this.currentUsername,
    this.currentUserAvatarUrl,
    this.isStreamOwner = false,
    this.onBanRequest,
  });

  final String? streamOwnerUsername;
  final String? streamOwnerAvatarUrl;
  final String? currentUsername;
  final String? currentUserAvatarUrl;
  /// Whether the current user is the stream owner (enables long-press ban).
  final bool isStreamOwner;
  /// Called when the owner long-presses a message to ban a user.
  final void Function(ChatMessage message)? onBanRequest;

  @override
  State<LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends State<LiveChatWidget> {
  final _controller = TextEditingController();
  final Map<String, String> _participantAvatars = {};
  final Set<String> _avatarLookups = {};

  String _normalizedUsername(String? value) =>
      (value ?? '').trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();

  void _resolveUnknownAvatars(List<ChatMessage> messages) {
    for (final message in messages) {
      if (message.avatarUrl != null) continue;

      final username = _normalizedUsername(message.username);
      if (username.isEmpty ||
          username == _normalizedUsername(widget.currentUsername) ||
          username == _normalizedUsername(widget.streamOwnerUsername) ||
          _participantAvatars.containsKey(username) ||
          !_avatarLookups.add(username)) {
        continue;
      }

      _loadParticipantAvatar(username);
    }
  }

  Future<void> _loadParticipantAvatar(String username) async {
    try {
      final result = await getIt<IUserRepository>().searchUsers(
        search: username,
        limit: 10,
      );
      final users = (result['users'] as List<User>?) ?? const <User>[];

      User? matchedUser;
      for (final user in users) {
        if (_normalizedUsername(user.username) == username) {
          matchedUser = user;
          break;
        }
      }

      final image = matchedUser?.image;
      if (!mounted || image is! String || image.trim().isEmpty) return;

      setState(() {
        _participantAvatars[username] = image.trim();
      });
    } catch (_) {
      // The letter avatar remains visible when the profile cannot be loaded.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (context.read<LiveChatCubit>().state.isBanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вас забанили! Вы не можете писать!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    context.read<LiveChatCubit>().send(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocBuilder<LiveChatCubit, LiveChatState>(
                buildWhen: (prev, curr) => prev.error != curr.error,
                builder: (context, state) {
                  if (state.error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Ошибка: ${state.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                },
              ),
              SizedBox(
                height: 220,
                child: BlocBuilder<LiveChatCubit, LiveChatState>(
                  buildWhen: (prev, curr) => prev.messages != curr.messages,
                  builder: (context, state) {
                    final messages = state.messages;
                    _resolveUnknownAvatars(messages);
                    return ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                        ],
                        stops: [0, 0.22, 1],
                      ).createShader(bounds),
                      child: ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.only(top: 22),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final msg = messages[messages.length - 1 - i];
                          final canBan = widget.isStreamOwner &&
                              msg.username != widget.currentUsername;
                          debugPrint(
                            '[CHAT] msg="${msg.message}" user=${msg.username} '
                            'userId=${msg.userId} isOwner=${widget.isStreamOwner} '
                            'currentUser=${widget.currentUsername} canBan=$canBan',
                          );
                          return _ChatMessageRow(
                            message: msg,
                            streamOwnerUsername: widget.streamOwnerUsername,
                            streamOwnerAvatarUrl: widget.streamOwnerAvatarUrl,
                            currentUsername: widget.currentUsername,
                            currentUserAvatarUrl: widget.currentUserAvatarUrl,
                            participantAvatarUrl: _participantAvatars[
                                _normalizedUsername(msg.username)],
                            onLongPress: canBan
                                ? () {
                                    debugPrint(
                                      '[CHAT] longPress on user=${msg.username} '
                                      'userId=${msg.userId}',
                                    );
                                    widget.onBanRequest?.call(msg);
                                  }
                                : null,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              BlocBuilder<LiveChatCubit, LiveChatState>(
                buildWhen: (prev, curr) => prev.isBanned != curr.isBanned,
                builder: (context, state) {
                  final banned = state.isBanned;
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !banned,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: banned
                                ? 'Вы не можете писать в этом эфире'
                                : 'Сообщение...',
                            hintStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white24,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      IconButton(
                        onPressed: banned ? null : _send,
                        icon: Icon(
                          Icons.send,
                          color: banned ? Colors.white38 : Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessageRow extends StatelessWidget {
  const _ChatMessageRow({
    required this.message,
    this.streamOwnerUsername,
    this.streamOwnerAvatarUrl,
    this.currentUsername,
    this.currentUserAvatarUrl,
    this.participantAvatarUrl,
    this.onLongPress,
  });

  final ChatMessage message;
  final String? streamOwnerUsername;
  final String? streamOwnerAvatarUrl;
  final String? currentUsername;
  final String? currentUserAvatarUrl;
  final String? participantAvatarUrl;
  final VoidCallback? onLongPress;

  String _normalizedUsername(String? value) =>
      (value ?? '').trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();

  @override
  Widget build(BuildContext context) {
    final initial = message.username.trim().isEmpty
        ? '?'
        : message.username.trim().characters.first.toUpperCase();
    final isStreamOwner = _normalizedUsername(message.username) ==
        _normalizedUsername(streamOwnerUsername);
    final isCurrentUser = _normalizedUsername(message.username) ==
        _normalizedUsername(currentUsername);
    final ownerAvatar = streamOwnerAvatarUrl?.trim();
    final currentAvatar = currentUserAvatarUrl?.trim();
    final avatarUrl = message.avatarUrl ??
        participantAvatarUrl ??
        (isCurrentUser && currentAvatar != null && currentAvatar.isNotEmpty
            ? currentAvatar
            : isStreamOwner && ownerAvatar != null && ownerAvatar.isNotEmpty
                ? ownerAvatar
                : null);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF536DB2),
            backgroundImage: avatarUrl == null
                ? null
                : CachedNetworkImageProvider(avatarUrl),
            child: avatarUrl == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '@${message.username}  ',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: message.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.25,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
