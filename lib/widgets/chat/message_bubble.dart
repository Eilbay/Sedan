import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
import 'package:optombai/data/models/chat/message_model.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool isGroupChat;
  final String? currentUserId;
  final bool canMute;
  final String chatId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.chatId,
    this.isGroupChat = false,
    this.currentUserId,
    this.canMute = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _showMuteDialog(BuildContext context, String chatId) {
    int selectedMinutes = 10;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Мутить пользователя'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Длительность мута:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MuteDurationButton(
                      label: '10 минут',
                      minutes: 10,
                      isSelected: selectedMinutes == 10,
                      onSelect: (value) =>
                          setState(() => selectedMinutes = value),
                    ),
                    _MuteDurationButton(
                      label: '1 час',
                      minutes: 60,
                      isSelected: selectedMinutes == 60,
                      onSelect: (value) =>
                          setState(() => selectedMinutes = value),
                    ),
                    _MuteDurationButton(
                      label: '5 часов',
                      minutes: 300,
                      isSelected: selectedMinutes == 300,
                      onSelect: (value) =>
                          setState(() => selectedMinutes = value),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Причина (опционально):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    hintText: 'Например: Спам, Оскорбления',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  maxLines: 2,
                  maxLength: 100,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<ChatBloc>().add(
                      MuteUserEvent(
                        chatId: chatId,
                        userId: widget.message.sender!.id,
                        userName: widget.message.sender!.displayName,
                        minutes: selectedMinutes,
                        reason: _reasonController.text.isNotEmpty
                            ? _reasonController.text
                            : null,
                      ),
                    );
                _reasonController.clear();
                Navigator.pop(context);
              },
              child: const Text('Мутить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress:
          !widget.isMe && widget.canMute && widget.message.sender != null
              ? () => _showMuteDialog(context, widget.chatId)
              : null,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
        child: Row(
          mainAxisAlignment:
              widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isMe && widget.isGroupChat)
              Container(
                margin: EdgeInsets.only(right: 8.w, bottom: 4.h),
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: widget.message.sender != null &&
                        widget.message.sender!.image != null &&
                        widget.message.sender!.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16.w),
                        child: CachedNetworkImage(
                          imageUrl: widget.message.sender!.image!,
                          // Decode at display size, not source resolution.
                          memCacheWidth: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          (widget.message.sender != null &&
                                      widget.message.sender!.displayName
                                          .isNotEmpty
                                  ? widget.message.sender!.displayName[0]
                                  : 'C')
                              .toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment: widget.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!widget.isMe && widget.isGroupChat)
                    Padding(
                      padding: EdgeInsets.only(left: 12.w, bottom: 2.h),
                      child: Text(
                        widget.message.getSenderName(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  Container(
                    margin: EdgeInsets.only(
                      bottom: 2.h,
                    ),
                    padding: EdgeInsets.all(10.w),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.65,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isMe ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.message.hasAttachment
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.message.text.isNotEmpty) ...[
                                Text(
                                  widget.message.text,
                                  style: TextStyle(
                                    color: widget.isMe
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                              ],
                              _MessageAttachment(
                                message: widget.message,
                                isMe: widget.isMe,
                              ),
                              SizedBox(height: 4.h),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _MessageMeta(
                                  time: _formatTime(widget.message.createdAt),
                                  isMe: widget.isMe,
                                  isRead: widget.message.isRead,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.message.text,
                                  style: TextStyle(
                                    color: widget.isMe
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              _MessageMeta(
                                time: _formatTime(widget.message.createdAt),
                                isMe: widget.isMe,
                                isRead: widget.message.isRead,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    final trimmed = timestamp.trim();
    if (trimmed.isEmpty) return '';

    final normalized =
        trimmed.contains('T') ? trimmed : trimmed.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      final local = parsed.toLocal();
      return '${_two(local.hour)}:${_two(local.minute)}';
    }

    final parts = trimmed.split(' ');
    if (parts.length == 2) {
      final timeParts = parts[1].split(':');
      if (timeParts.length >= 2) {
        return '${timeParts[0]}:${timeParts[1]}';
      }
    }

    return '';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _MuteDurationButton extends StatelessWidget {
  final String label;
  final int minutes;
  final bool isSelected;
  final ValueChanged<int> onSelect;

  const _MuteDurationButton({
    required this.label,
    required this.minutes,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onSelect(minutes),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }
}

class _MessageMeta extends StatelessWidget {
  const _MessageMeta({
    required this.time,
    required this.isMe,
    required this.isRead,
  });

  final String time;
  final bool isMe;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final color = isMe ? Colors.white70 : Colors.grey[600];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 10.sp,
            color: color,
          ),
        ),
        if (isMe) ...[
          SizedBox(width: 4.w),
          Icon(
            isRead ? Icons.done_all : Icons.done,
            size: 12.sp,
            color: Colors.white70,
          ),
        ],
      ],
    );
  }
}

class _MessageAttachment extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageAttachment({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final pendingIndicator = message.isPending
        ? Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: _UploadProgressBadge(
              progress: message.uploadProgress,
              isMe: isMe,
            ),
          )
        : const SizedBox.shrink();

    switch (message.type) {
      case MessageType.image:
        if (message.isPending) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(message.attachment!),
                  width: 200.w,
                  height: 200.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => SizedBox(
                    width: 200.w,
                    height: 200.h,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ],
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: message.attachment!,
            memCacheWidth: 600,
            fit: BoxFit.cover,
            width: 200.w,
            height: 200.h,
            placeholder: (context, url) => SizedBox(
              width: 200.w,
              height: 200.h,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        );

      case MessageType.video:
        return GestureDetector(
          onTap: () async {
            if (!message.isPending && message.attachment != null) {
              final uri = Uri.parse(message.attachment!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam,
                color: isMe ? Colors.white : Colors.blue,
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  message.attachment?.split('/').last ?? 'Видео',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.blue,
                    fontSize: 12.sp,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              pendingIndicator,
            ],
          ),
        );

      case MessageType.file:
        return GestureDetector(
          onTap: () async {
            if (!message.isPending && message.attachment != null) {
              final uri = Uri.parse(message.attachment!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attach_file,
                color: isMe ? Colors.white : Colors.blue,
                size: 16.sp,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  message.attachment?.split('/').last ?? 'Файл',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.blue,
                    fontSize: 12.sp,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              pendingIndicator,
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _UploadProgressBadge extends StatelessWidget {
  const _UploadProgressBadge({
    required this.progress,
    required this.isMe,
  });

  final int? progress;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final value = (progress ?? 0).clamp(0, 100);

    return Container(
      constraints: BoxConstraints(minWidth: 34.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '$value%',
        maxLines: 1,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.blue.shade700,
          fontSize: 11.sp,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
