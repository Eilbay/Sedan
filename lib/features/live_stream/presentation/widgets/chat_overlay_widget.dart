import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ChatOverlayWidget extends StatefulWidget {
  final List<String> messages;

  const ChatOverlayWidget({super.key, required this.messages});

  @override
  State<ChatOverlayWidget> createState() => _ChatOverlayWidgetState();
}

class _ChatOverlayWidgetState extends State<ChatOverlayWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant ChatOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double chatHeight = MediaQuery.sizeOf(context).height * 0.35;

    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.75,
      height: chatHeight,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.messages.length,
        padding: const EdgeInsets.only(bottom: 10, left: 10, top: 10),
        itemBuilder: (context, index) {
          final message = widget.messages[index];
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}
