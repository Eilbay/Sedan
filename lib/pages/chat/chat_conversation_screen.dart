import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/bloc/block_bloc/block_bloc.dart';
import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
import 'package:optombai/bloc/message_bloc/message_bloc.dart';
import 'package:optombai/bloc/support_bloc/support_bloc.dart';
import 'package:optombai/services/push/current_chat_tracker.dart';
import 'package:optombai/bloc/support_bloc/support_event.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/data/models/chat/chat_model.dart';
import 'package:optombai/data/models/chat/chat_user.dart';
import 'package:optombai/data/models/chat/linked_post.dart';
import 'package:optombai/data/models/chat/message_model.dart';
import 'package:optombai/data/models/support/support_session_model.dart';
import 'package:optombai/widgets/chat/message_bubble.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:optombai/data/repositories/i_user_repository.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/widgets/chat/message_input.dart';
import 'package:optombai/widgets/moderation/user_actions_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class ChatConversationScreen extends StatefulWidget {
  final Chat chat;
  final SupportSession? supportSession;
  final LinkedPost? linkedPost;

  const ChatConversationScreen({
    super.key,
    required this.chat,
    this.supportSession,
    this.linkedPost,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  static const List<String> _availabilityQuickReplies = [
    'Здравствуйте',
    'Да, еще актуально',
    'Позвоните мне',
  ];

  File? _attachedFile;
  String? _attachedFileName;
  MessageType? _attachedMessageType;

  // Captured once in initState. dispose() must NOT call context.read: during
  // teardown the Provider element above is already gone, so the lookup throws
  // "Null check operator used on a null value". Hold the reference instead.
  late final MessageBloc _messageBloc;

  bool _paginationArmed = true;

  @override
  void initState() {
    super.initState();
    _messageBloc = context.read<MessageBloc>();
    _scrollController.addListener(_onScroll);

    CurrentChatTracker.instance.setOpen(widget.chat.id);
    _initializeChat();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final pixels = _scrollController.position.pixels;
    final state = _messageBloc.state;

    if (pixels > 250) {
      _paginationArmed = true;
      return;
    }

    if (pixels > 100) return;
    if (!_paginationArmed) return;
    if (state.isLoading || state.isLoadingPaginate) return;
    if (state.messageListModel?.next == null) return;

    _paginationArmed = false;
    _messageBloc.add(FetchNextMessagesPageEvent());
  }

  void _initializeChat() {
    final messageBloc = context.read<MessageBloc>();
    final chatBloc = context.read<ChatBloc>();

    messageBloc.add(FetchMessagesEvent(widget.chat.id));

    messageBloc.add(ConnectWebSocketEvent(widget.chat.id));

    messageBloc.add(MarkMessagesAsReadEvent(widget.chat.id));
    chatBloc.add(UpdateUnreadCountEvent(
      chatId: widget.chat.id,
      unreadCount: 0,
    ));
  }

  @override
  void dispose() {
    CurrentChatTracker.instance.setOpen(null);
    _messageBloc.add(DisconnectWebSocketEvent());
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage({File? attachment, MessageType type = MessageType.text}) {
    final text = _textController.text.trim();
    if (text.isEmpty && attachment == null) return;

    final messageType =
        attachment != null ? (_attachedMessageType ?? MessageType.file) : type;
    final currentUser = context.read<UserBloc>().state.user;

    context.read<MessageBloc>().add(SendMessageEvent(
          chatId: widget.chat.id,
          text: text,
          type: messageType,
          attachment: attachment,
          sender: ChatUser(
            id: currentUser.id,
            username: currentUser.username,
            image: currentUser.image?.toString(),
            phoneNumber: currentUser.phone_number,
          ),
        ));

    _textController.clear();

    setState(() {
      _attachedFile = null;
      _attachedFileName = null;
      _attachedMessageType = null;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendQuickReply(String text) {
    if (text.trim().isEmpty) return;

    _textController
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    _sendMessage();
  }

  List<String> _getQuickReplies(List<Message> messages, String currentUserId) {
    if (messages.isEmpty) return const [];

    for (final message in messages.reversed) {
      if (message.sender?.id == currentUserId) {
        continue;
      }

      final normalizedText = message.text
          .toLowerCase()
          .replaceAll('ё', 'е')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (normalizedText.isEmpty) {
        continue;
      }

      if (normalizedText == 'здравствуйте! еще актуально?' ||
          normalizedText == 'здравствуйте! ещё актуально?' ||
          normalizedText == 'здравствуйте еще актуально?' ||
          normalizedText == 'здравствуйте ещё актуально?' ||
          normalizedText == 'здравствуйте' ||
          normalizedText == 'здравствуйте!' ||
          normalizedText == 'здравствуйте.') {
        return _availabilityQuickReplies;
      }

      final asksAvailability = normalizedText.contains('актуал');
      final hasGreeting = normalizedText.contains('здравств') ||
          normalizedText.contains('добрый') ||
          normalizedText.contains('доброе') ||
          normalizedText.contains('привет') ||
          normalizedText.contains('салам');
      final hasQuestion = normalizedText.contains('?') ||
          normalizedText.contains('еще') ||
          normalizedText.contains('ещё');

      if (asksAvailability && (hasGreeting || hasQuestion)) {
        return _availabilityQuickReplies;
      }

      break;
    }

    return const [];
  }

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 30 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextTranslated(
                'Выбрать файл',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const TextTranslated('Фото'),
                onTap: () {
                  context.router.maybePop();
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const TextTranslated('Видео'),
                onTap: () {
                  context.router.maybePop();
                  _pickVideoFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Файл'),
                onTap: () {
                  context.router.maybePop();
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _compressAndAttachImage(image);
    }
  }

  Future<void> _compressAndAttachImage(XFile image) async {
    try {
      final file = File(image.path);

      setState(() {
        _attachedFile = file;
        _attachedFileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
        _attachedMessageType = MessageType.image;
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _attachVideoFile(video);
    }
  }

  Future<void> _attachVideoFile(XFile video) async {
    try {
      final file = File(video.path);

      setState(() {
        _attachedFile = file;
        _attachedFileName = 'VID_${DateTime.now().millisecondsSinceEpoch}.mp4';
        _attachedMessageType = MessageType.video;
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке видео: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);

        setState(() {
          _attachedFile = file;
          _attachedFileName = result.files.single.name;
          _attachedMessageType = MessageType.file;
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выборе файла: $e')),
      );
    }
  }

  Future<void> _launchPhoneNumber(String phoneNumber) async {
    final normalizedPhone = phoneNumber.trim();
    if (normalizedPhone.isEmpty) return;

    final phoneUri = Uri(scheme: 'tel', path: normalizedPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось открыть набор номера')),
    );
  }

  Future<void> _launchUserPhone(ChatUser user) async {
    var phoneNumber = user.phoneNumber.trim();

    if (phoneNumber.isEmpty) {
      try {
        final token = context.read<UserBloc>().getToken();
        final profile = await getIt<IUserRepository>().getUser(token, user.id);
        phoneNumber = profile.phone_number.trim();
      } catch (_) {
        phoneNumber = '';
      }
    }

    if (!mounted) return;

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Номер телефона не указан')),
      );
      return;
    }

    await _launchPhoneNumber(phoneNumber);
  }

  void _removeAttachment() {
    setState(() {
      _attachedFile = null;
      _attachedFileName = null;
      _attachedMessageType = null;
    });
  }

  void _closeSupport() async {
    if (widget.supportSession == null || !widget.supportSession!.canBeClosed) {
      return;
    }

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Закрыть обращение?"),
        content: const Text(
          "Вы уверены, что хотите закрыть обращение в поддержку?",
        ),
        actions: [
          TextButton(
            child: const Text("Отмена"),
            onPressed: () => context.router.maybePop(false),
          ),
          TextButton(
            child: const Text("Закрыть"),
            onPressed: () => context.router.maybePop(true),
          ),
        ],
      ),
    );

    if (shouldClose == true && mounted) {
      context.read<SupportBloc>().add(
            CloseSupportSessionEvent(
              sessionId: widget.supportSession!.id,
              comment: "Закрыто пользователем",
            ),
          );

      context.router.maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<UserBloc>().state.user.id;
    final isSupportChat = widget.supportSession != null;
    final chatTitle = isSupportChat
        ? "Поддержка "
        : widget.chat.getDisplayTitle(currentUserId);
    final isGroupChat = widget.chat.participants.length > 2;

    final otherUser = !isGroupChat && !isSupportChat
        ? widget.chat.participants.firstWhere(
            (p) => p.id != currentUserId,
            orElse: () => widget.chat.participants.first,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: !isGroupChat && otherUser != null && !isSupportChat
              ? () {
                  context.router.push(OtherUserProfileRoute(
                    user: otherUser.id,
                    username: otherUser.username,
                  ));
                }
              : null,
          child: Row(
            children: [
              Expanded(
                child: Text(chatTitle),
              ),
            ],
          ),
        ),
        actions: [
          if (isSupportChat && widget.supportSession!.canBeClosed)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: "Закрыть обращение",
              onPressed: _closeSupport,
            ),
          if (!isGroupChat && !isSupportChat && otherUser != null)
            IconButton(
              icon: const Icon(Icons.phone),
              tooltip: 'Позвонить',
              onPressed: () => _launchUserPhone(otherUser),
            ),
          if (!isGroupChat && !isSupportChat && otherUser != null)
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Действия',
              onPressed: () => UserActionsSheet.show(
                context,
                userId: otherUser.id,
                username: otherUser.username,
                reportTargetType: ReportTargetType.user,
                reportTargetId: otherUser.id,
              ),
            ),
          if (!isGroupChat && otherUser != null && otherUser.image != null)
            GestureDetector(
              onTap: () {
                context.router.push(OtherUserProfileRoute(
                  user: otherUser.id,
                  username: otherUser.username,
                ));
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: otherUser.image!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Text(
                            otherUser.displayName.isNotEmpty
                                ? otherUser.displayName[0].toUpperCase()
                                : 'U',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          BlocBuilder<MessageBloc, MessageState>(
            buildWhen: (previous, current) =>
                previous.isWebSocketConnected != current.isWebSocketConnected,
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Icon(
                    state.isWebSocketConnected
                        ? Icons.circle
                        : Icons.circle_outlined,
                    color:
                        state.isWebSocketConnected ? Colors.green : Colors.grey,
                    size: 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MessageBloc, MessageState>(
            listenWhen: (previous, current) =>
                previous.transientErrorTick != current.transientErrorTick &&
                current.transientError.isNotEmpty,
            listener: (context, state) {
              // transientError is only set on a BLOCKED reject. Show the exact
              // direction: a one-to-one chat knows the other user, so the local
              // blocked list tells "you blocked them" from "they blocked you".
              // Fall back to the server text for group/support chats.
              final blockedByMe = otherUser != null &&
                  context.read<BlockBloc>().isUserBlocked(otherUser.id);
              final message = otherUser == null
                  ? state.transientError
                  : (blockedByMe
                      ? 'Вы заблокировали этого пользователя'
                      : 'Этот пользователь вас заблокировал');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(milliseconds: 500),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
          BlocListener<ChatBloc, ChatState>(
            listenWhen: (previous, current) =>
                previous.lastMutedUserName != current.lastMutedUserName ||
                previous.errors != current.errors,
            listener: (context, state) {
              if (state.isSuccess && state.lastMutedUserName != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${state.lastMutedUserName} замучен'),
                    duration: const Duration(milliseconds: 500),
                    backgroundColor: Colors.orange[700],
                  ),
                );
              }
              if (state.errors.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: ${state.errors.first}'),
                    duration: const Duration(milliseconds: 500),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
        child: Column(
          children: [
            if (widget.chat.linkedPost != null || widget.linkedPost != null)
              _LinkedPostCard(
                linkedPost: widget.chat.linkedPost ?? widget.linkedPost!,
              ),
            BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (previous, current) =>
                  previous.isTranslating != current.isTranslating,
              builder: (context, state) {
                if (!state.isTranslating) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.blue[700],
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Чат переводится...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<MessageBloc, MessageState>(
                buildWhen: (previous, current) =>
                    previous.messages != current.messages ||
                    previous.isLoading != current.isLoading ||
                    previous.isLoadingPaginate != current.isLoadingPaginate ||
                    previous.errors != current.errors,
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.errors.isNotEmpty) {
                    return Center(child: Text(state.errors.first));
                  }

                  if (state.messages.isEmpty) {
                    return const Center(child: Text("Нет сообщений"));
                  }

                  final sortedMessages = List<Message>.from(state.messages)
                    ..sort((a, b) {
                      final aDate = _parseMessageDate(a.createdAt);
                      final bDate = _parseMessageDate(b.createdAt);

                      if (aDate == null && bDate == null) return 0;
                      if (aDate == null) return -1;
                      if (bDate == null) return 1;

                      final dateCompare = aDate.compareTo(bDate);
                      if (dateCompare != 0) return dateCompare;

                      return a.id.compareTo(b.id);
                    });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: false,
                    itemCount: sortedMessages.length +
                        (state.isLoadingPaginate ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.isLoadingPaginate && index == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final msgIndex =
                          state.isLoadingPaginate ? index - 1 : index;
                      final message = sortedMessages[msgIndex];
                      final isMe = message.sender?.id == currentUserId;
                      final isGroupChat = widget.chat.participants.length > 2;

                      final previousMessage =
                          msgIndex > 0 ? sortedMessages[msgIndex - 1] : null;
                      final showDateDivider =
                          _shouldShowDateDivider(message, previousMessage);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showDateDivider)
                            _MessageDateDivider(
                              label: _formatMessageDateLabel(message.createdAt),
                            ),
                          MessageBubble(
                            message: message,
                            isMe: isMe,
                            chatId: widget.chat.id,
                            isGroupChat: isGroupChat,
                            currentUserId: currentUserId,
                            canMute: widget.chat.canMute(currentUserId),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            BlocBuilder<MessageBloc, MessageState>(
              buildWhen: (previous, current) =>
                  previous.isSending != current.isSending ||
                  previous.messages != current.messages,
              builder: (context, state) {
                final quickReplies =
                    _getQuickReplies(state.messages, currentUserId);
                return MessageInput(
                  controller: _textController,
                  isSending:
                      state.isSending && !state.hasPendingAttachmentMessage,
                  onSend: _attachedFile != null
                      ? () => _sendMessage(attachment: _attachedFile)
                      : () => _sendMessage(),
                  onPickImage: _showAttachmentOptions,
                  onQuickReplyTap: _sendQuickReply,
                  attachedFileName: _attachedFileName,
                  attachedFilePath: _attachedFile?.path,
                  hasAttachment: _attachedFile != null,
                  quickReplies: quickReplies,
                  onRemoveAttachment: _removeAttachment,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowDateDivider(Message message, Message? previousMessage) {
    final messageDate = _parseMessageDate(message.createdAt);
    if (messageDate == null) return false;
    if (previousMessage == null) return true;

    final previousDate = _parseMessageDate(previousMessage.createdAt);
    if (previousDate == null) return true;

    return !_isSameDate(messageDate, previousDate);
  }

  DateTime? _parseMessageDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final normalized =
        trimmed.contains('T') ? trimmed : trimmed.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) return parsed.toLocal();

    final dateTimeParts = trimmed.split(' ');
    final dateParts = dateTimeParts.first.split(RegExp(r'[-.]'));
    if (dateParts.length != 3) return null;

    final first = int.tryParse(dateParts[0]);
    final second = int.tryParse(dateParts[1]);
    var third = int.tryParse(dateParts[2]);
    if (first == null || second == null || third == null) return null;

    if (third < 100) third += 2000;

    if (dateParts[0].length == 4) {
      return DateTime(first, second, third);
    }

    return DateTime(third, second, first);
  }

  String _formatMessageDateLabel(String value) {
    final date = _parseMessageDate(value);
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(messageDay).inDays;

    if (difference == 0) return 'Сегодня';
    if (difference == 1) return 'Вчера';

    String two(int number) => number.toString().padLeft(2, '0');
    final year = two(date.year % 100);
    return '${two(date.day)}.${two(date.month)}.$year';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MessageDateDivider extends StatelessWidget {
  const _MessageDateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkedPostCard extends StatefulWidget {
  const _LinkedPostCard({required this.linkedPost});

  final LinkedPost linkedPost;

  @override
  State<_LinkedPostCard> createState() => _LinkedPostCardState();
}

class _LinkedPostCardState extends State<_LinkedPostCard> {
  Future<LinkedPost?>? _detailsFuture;

  bool get _needsDetails =>
      widget.linkedPost.id.isNotEmpty &&
      widget.linkedPost.title == 'Товар' &&
      widget.linkedPost.imageUrl == null;

  @override
  void initState() {
    super.initState();
    _refreshDetailsFuture();
  }

  @override
  void didUpdateWidget(covariant _LinkedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.linkedPost.id != widget.linkedPost.id) {
      _refreshDetailsFuture();
    }
  }

  void _refreshDetailsFuture() {
    _detailsFuture = _needsDetails ? _loadLinkedPostDetails() : null;
  }

  Future<LinkedPost?> _loadLinkedPostDetails() async {
    try {
      final product = await getIt<IProductRepository>()
          .getProductInfo(widget.linkedPost.id);
      return LinkedPost(
        id: product.id,
        title: product.name.isNotEmpty ? product.name : widget.linkedPost.title,
        imageUrl: product.previewUrl,
        price: product.price,
        currency: product.currency,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsFuture = _detailsFuture;
    if (detailsFuture == null) {
      return _LinkedPostCardContent(linkedPost: widget.linkedPost);
    }

    return FutureBuilder<LinkedPost?>(
      future: detailsFuture,
      builder: (context, snapshot) {
        return _LinkedPostCardContent(
          linkedPost: snapshot.data ?? widget.linkedPost,
        );
      },
    );
  }
}

class _LinkedPostCardContent extends StatelessWidget {
  const _LinkedPostCardContent({required this.linkedPost});

  final LinkedPost linkedPost;

  @override
  Widget build(BuildContext context) {
    final priceText = linkedPost.price != null && linkedPost.price != 0
        ? '${linkedPost.price!.toStringAsFixed(2)} ${linkedPost.currency}'
        : 'Договорная';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: InkWell(
        onTap: () => context.router.push(
          ProductDetailsRoute(
            results: Product(id: linkedPost.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: linkedPost.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: linkedPost.imageUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      linkedPost.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }
}
