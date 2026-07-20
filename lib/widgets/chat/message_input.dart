import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/theme_notifier.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final ValueChanged<String> onQuickReplyTap;
  final String? attachedFileName;
  final String? attachedFilePath;
  final bool hasAttachment;
  final List<String> quickReplies;
  final VoidCallback onRemoveAttachment;

  const MessageInput({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onPickImage,
    required this.onQuickReplyTap,
    this.attachedFileName,
    this.attachedFilePath,
    this.hasAttachment = false,
    this.quickReplies = const [],
    required this.onRemoveAttachment,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool _isImageFile(String fileName) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    final extension = fileName.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension)) {
      return Icons.image;
    } else if (['mp4', 'avi', 'mov', 'mkv', 'flv', 'wmv'].contains(extension)) {
      return Icons.video_library;
    } else if (['pdf'].contains(extension)) {
      return Icons.picture_as_pdf;
    } else if (['doc', 'docx', 'txt'].contains(extension)) {
      return Icons.description;
    } else if (['zip', 'rar', '7z'].contains(extension)) {
      return Icons.folder_zip;
    }

    return Icons.attach_file;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final Color bgColor = isDark ? AppColors.black : AppColors.white;
    final Color inputBgColor =
        isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade200;
    final Color inputTextColor = isDark ? Colors.white : Colors.black87;
    final Color hintColor = isDark ? Colors.white54 : Colors.grey.shade600;

    final Color attachmentBgColor =
        isDark ? const Color(0xFF102A43) : Colors.blue.withValues(alpha: 0.1);
    final Color attachmentBorderColor =
        isDark ? const Color(0xFF197FBD) : Colors.blue;
    final Color attachmentTextColor = isDark ? Colors.white : Colors.black87;
    final Color closeIconColor = isDark ? Colors.white70 : Colors.black87;

    final Color brokenImageBgColor =
        isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300;

    return SafeArea(
      child: Container(
        color: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.quickReplies.isNotEmpty)
              SizedBox(
                height: 44.h,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final reply = widget.quickReplies[index];

                    return ActionChip(
                      label: Text(
                        reply,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: Colors.blue,
                      disabledColor: Colors.blue.withValues(alpha: 0.5),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: widget.isSending
                          ? null
                          : () => widget.onQuickReplyTap(reply),
                    );
                  },
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemCount: widget.quickReplies.length,
                ),
              ),
            if (widget.hasAttachment && widget.attachedFileName != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: attachmentBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: attachmentBorderColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (_isImageFile(widget.attachedFileName ?? '') &&
                        widget.attachedFilePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(widget.attachedFilePath!),
                          width: 40.w,
                          height: 40.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40.w,
                              height: 40.h,
                              decoration: BoxDecoration(
                                color: brokenImageBgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.broken_image,
                                size: 20,
                                color: isDark ? Colors.white54 : Colors.grey,
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Icon(
                        _getFileIcon(widget.attachedFileName ?? ''),
                        color:
                            widget.hasAttachment ? Colors.green : Colors.blue,
                        size: 18.sp,
                      ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        widget.attachedFileName ?? 'Файл',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: attachmentTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: closeIconColor,
                      ),
                      onPressed: widget.onRemoveAttachment,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: widget.hasAttachment ? Colors.green : Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      onPressed: widget.isSending ? null : widget.onPickImage,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 40.w,
                        minHeight: 40.h,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.transparent,
                        ),
                      ),
                      child: TextField(
                        controller: widget.controller,
                        decoration: InputDecoration(
                          hintText: "Введите сообщение...",
                          hintStyle: TextStyle(
                            color: hintColor,
                            fontSize: 14.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        maxLines: null,
                        minLines: 1,
                        enabled: !widget.isSending,
                        cursorColor: Colors.blue,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: inputTextColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: widget.isSending
                          ? SizedBox(
                              width: 20.sp,
                              height: 20.sp,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                      onPressed: widget.isSending ? null : widget.onSend,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 40.w,
                        minHeight: 40.h,
                      ),
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
}
