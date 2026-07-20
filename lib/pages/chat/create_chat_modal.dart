import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';

class CreateChatModal extends StatefulWidget {
  final String currentUserId;

  const CreateChatModal({super.key, required this.currentUserId});

  @override
  State<CreateChatModal> createState() => _CreateChatModalState();
}

class _CreateChatModalState extends State<CreateChatModal> {
  bool _isPersonalChat = true;
  String _selectedUserId = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Создать чат",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPersonalChat ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPersonalChat = true;
                    });
                  },
                  child: const Text("Личный чат"),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 16),
          if (_isPersonalChat)
            _PersonalChatContent(
              selectedUserId: _selectedUserId,
              onUserIdChanged: (value) =>
                  setState(() => _selectedUserId = value),
              onCreateChat: () {
                context.read<ChatBloc>().add(
                      CreatePersonalChatEvent(_selectedUserId),
                    );
                context.router.maybePop();
                // Listen for result and navigate to ChatConversationScreen
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (!context.mounted) return;
                  final state = context.read<ChatBloc>().state;
                  if (state.chats.isNotEmpty) {
                    final chat = state.chats.first;
                    context.router.push(ChatConversationRoute(chat: chat));
                  }
                });
              },
            )
,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Private extracted widgets
// ---------------------------------------------------------------------------

class _PersonalChatContent extends StatelessWidget {
  final String selectedUserId;
  final ValueChanged<String> onUserIdChanged;
  final VoidCallback onCreateChat;

  const _PersonalChatContent({
    required this.selectedUserId,
    required this.onUserIdChanged,
    required this.onCreateChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: "Введите ID пользователя",
            border: OutlineInputBorder(),
          ),
          onChanged: onUserIdChanged,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedUserId.isEmpty ? null : onCreateChat,
            child: const Text("Создать"),
          ),
        ),
      ],
    );
  }
}
