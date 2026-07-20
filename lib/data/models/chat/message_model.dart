import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/chat/chat_user.dart';

enum MessageType {
  text,
  image,
  video,
  file;

  static MessageType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  String toServerString() {
    return toString().split('.').last;
  }
}

class Message extends Equatable {
  final String id;
  final String chatId;
  final ChatUser? sender;
  final MessageType type;
  final String text;
  final String? attachment;
  final String createdAt;
  final bool isRead;
  final String? translatedText;
  final String? translationStatus;
  final String? targetLang;
  final bool isPending;
  final int? uploadProgress;

  const Message({
    required this.id,
    required this.chatId,
    this.sender,
    required this.type,
    required this.text,
    this.attachment,
    required this.createdAt,
    required this.isRead,
    this.translatedText,
    this.translationStatus,
    this.targetLang,
    this.isPending = false,
    this.uploadProgress,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? "",
      chatId: json['chat'] ?? "",
      sender: json['sender'] != null ? ChatUser.fromJson(json['sender']) : null,
      type: MessageType.fromString(json['type'] ?? 'text'),
      text: json['text'] ?? "",
      attachment: json['attachment'],
      createdAt: json['created_at'] ?? "",
      isRead: json['is_read'] ?? false,
      translatedText: json['translated_text'],
      translationStatus: json['translation_status'],
      targetLang: json['target_lang'],
      isPending: false,
      uploadProgress: null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chat': chatId,
        'sender': sender?.toJson(),
        'type': type.toServerString(),
        'text': text,
        'attachment': attachment,
        'created_at': createdAt,
        'is_read': isRead,
        'translated_text': translatedText,
        'translation_status': translationStatus,
        'target_lang': targetLang,
      };

  Message copyWith({
    String? id,
    String? chatId,
    ChatUser? sender,
    MessageType? type,
    String? text,
    String? attachment,
    String? createdAt,
    bool? isRead,
    String? translatedText,
    String? translationStatus,
    String? targetLang,
    bool? isPending,
    int? uploadProgress,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      text: text ?? this.text,
      attachment: attachment ?? this.attachment,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      translatedText: translatedText ?? this.translatedText,
      translationStatus: translationStatus ?? this.translationStatus,
      targetLang: targetLang ?? this.targetLang,
      isPending: isPending ?? this.isPending,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  String getSenderName() {
    if (sender == null) return "Система";
    return sender!.displayName;
  }

  bool get hasAttachment => attachment != null && attachment!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        chatId,
        sender,
        type,
        text,
        attachment,
        createdAt,
        isRead,
        translatedText,
        translationStatus,
        targetLang,
        isPending,
        uploadProgress,
      ];
}
