import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
import 'package:optombai/bloc/support_bloc/support_bloc.dart';
import 'package:optombai/bloc/support_bloc/support_event.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/widgets/auth/inline_sign_in.dart';
import 'package:optombai/widgets/chat/chat_card.dart';
import 'package:optombai/widgets/shimmer/shimmer_list_tile.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/bottom_nav.dart';

@RoutePage()
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  Object? _lastLifecycleState;
  bool _requestedAuthedLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChats();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final chatBloc = context.read<ChatBloc>();
        if (!chatBloc.state.isLoadingPaginate) {
          chatBloc.add(FetchNextChatsPageEvent());
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(state) {
    if (state.toString().contains('resumed') &&
        (_lastLifecycleState == null ||
            _lastLifecycleState.toString().contains('paused') ||
            _lastLifecycleState.toString().contains('hidden'))) {
      _loadChats();
    }
    _lastLifecycleState = state;
  }

  void _loadChats() {
    if (!mounted) return;
    final hasToken = context.read<ThemeNotifier>().isRegister;
    debugPrint(
        '[CHAT] _loadChats hasToken=$hasToken requested=$_requestedAuthedLoad');
    if (!hasToken) return;
    BlocProvider.of<ChatBloc>(context).add(FetchChatsEvent());
    context.read<SupportBloc>().add(CheckActiveSupportSessionEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSupportButtonPressed() {
    context.read<SupportBloc>().add(CheckActiveSupportSessionEvent());
    final supportBloc = context.read<SupportBloc>();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final activeSession = supportBloc.state.activeSession;
      if (activeSession != null) {
        context.router.push(ChatConversationRoute(chat: activeSession.chat));
      } else {
        context.router.push(const CreateSupportRequestRoute());
      }
    });
  }

  void _showDeleteChatDialog(String chatId, String chatTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить чат?'),
          content: Text('Вы уверены, что хотите удалить чат "$chatTitle"?'),
          actions: [
            TextButton(
              onPressed: () => context.router.maybePop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                context.router.maybePop();
                context.read<ChatBloc>().add(DeleteChatEvent(chatId));
              },
              child: const Text(
                'Удалить',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<UserBloc>().state.user.id;
    final hasToken = context.select((ThemeNotifier n) => n.isRegister);
    debugPrint(
      '[CHAT] build hasToken=$hasToken chatCount=${context.read<ChatBloc>().state.chats.length} '
      'currentUserId=$currentUserId requestedLoad=$_requestedAuthedLoad',
    );

    if (hasToken && !_requestedAuthedLoad) {
      _requestedAuthedLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadChats();
      });
    }

    // Messages tab stays highlighted via currentIndexOverride: -10.
    // When not authenticated, show the sign-in form instead of the chat list.
    if (!hasToken) {
      debugPrint('[CHAT] build -> InlineSignIn');
      _requestedAuthedLoad = false;
      return Scaffold(
        bottomNavigationBar:
            const BottomNav(currentIndexOverride: -10, passive: true),
        appBar: AppBar(title: const Text('Сообщения')),
        body: const InlineSignIn(),
      );
    }

    debugPrint('[CHAT] build -> chat list');
    return Scaffold(
      bottomNavigationBar:
          const BottomNav(currentIndexOverride: -10, passive: true),
      appBar: AppBar(
        title: const Text("Сообщения"),
        actions: [
          GestureDetector(
            onTap: _onSupportButtonPressed,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage('assets/icons/support_agent.jpg'),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<ChatBloc, ChatState>(
        listenWhen: (previous, current) {
          return previous.errors != current.errors && current.errors.isNotEmpty;
        },
        listener: (context, state) {
          if (state.errors.isNotEmpty) {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Ошибка'),
                  content: Text(state.errors.first),
                  actions: [
                    TextButton(
                      onPressed: () => dialogContext.router.maybePop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (previous, current) {
            return previous.chats != current.chats ||
                previous.isLoading != current.isLoading ||
                previous.errors != current.errors ||
                previous.isLoadingPaginate != current.isLoadingPaginate;
          },
          builder: (context, chatState) {
            if (chatState.isLoading) {
              return Column(
                children: List.generate(
                  6,
                  (_) => const ShimmerListTile(),
                ),
              );
            }

            if (chatState.errors.isNotEmpty) {
              return Center(child: Text(chatState.errors.first));
            }

            if (chatState.chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Нет чатов',
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            final supportChatId =
                context.read<SupportBloc>().state.activeSession?.chat.id;

            return RefreshIndicator(
              onRefresh: () async {
                final chatBloc = context.read<ChatBloc>();
                chatBloc.add(FetchChatsEvent());
                await chatBloc.stream.firstWhere((s) => !s.isLoading).timeout(
                    const Duration(seconds: 10),
                    onTimeout: () => chatBloc.state);
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: chatState.chats.length +
                    (chatState.isLoadingPaginate ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chatState.chats.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final chat = chatState.chats[index];
                  final isSupportChat = chat.id == supportChatId;
                  final otherUser = chat.getOtherParticipant(currentUserId);

                  return RepaintBoundary(
                    child: ChatCard(
                      chat: chat,
                      currentUserId: currentUserId,
                      isSupportChat: isSupportChat,
                      onTap: () {
                        context.router.push(ChatConversationRoute(chat: chat));
                      },
                      onAvatarTap: (!isSupportChat && otherUser != null)
                          ? () => context.router.push(
                                OtherUserProfileRoute(
                                  user: otherUser.id,
                                  username: otherUser.username,
                                ),
                              )
                          : null,
                      onLongPress: () {
                        _showDeleteChatDialog(
                            chat.id, chat.getDisplayTitle(currentUserId));
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
