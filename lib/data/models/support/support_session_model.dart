import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/chat/chat_model.dart';
import 'package:optombai/data/models/chat/chat_user.dart';
import 'package:optombai/data/models/chat/message_model.dart';

enum SupportSessionStatus {
  waiting,
  active,
  closed;
  static SupportSessionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return SupportSessionStatus.waiting;
      case 'active':
        return SupportSessionStatus.active;
      case 'closed':
        return SupportSessionStatus.closed;
      default:
        return SupportSessionStatus.waiting;
    }
  }

  String toApiString() {
    switch (this) {
      case SupportSessionStatus.waiting:
        return 'waiting';
      case SupportSessionStatus.active:
        return 'active';
      case SupportSessionStatus.closed:
        return 'closed';
    }
  }
}

class SupportSession extends Equatable {
  final String id;
  final SupportSessionStatus status;
  final ChatUser customer;
  final ChatUser? assignedTo;
  final Chat chat;
  final Message firstMessage;
  final String createdAt;
  final String updatedAt;
  final String? closedAt;

  const SupportSession({
    required this.id,
    required this.status,
    required this.customer,
    this.assignedTo,
    required this.chat,
    required this.firstMessage,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });

  factory SupportSession.fromJson(Map<String, dynamic> json) {
    return SupportSession(
      id: json['id'] as String,
      status: SupportSessionStatus.fromString(json['status'] as String),
      customer: ChatUser.fromJson(json['customer'] as Map<String, dynamic>),
      assignedTo: json['assigned_to'] != null
          ? ChatUser.fromJson(json['assigned_to'] as Map<String, dynamic>)
          : null,
      chat: Chat.fromJson(json['chat'] as Map<String, dynamic>),
      firstMessage: Message.fromJson(json['first_message'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      closedAt: json['closed_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.toApiString(),
      'customer': customer.toJson(),
      'assigned_to': assignedTo?.toJson(),
      'chat': chat.toJson(),
      'first_message': firstMessage.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
      'closed_at': closedAt,
    };
  }

  bool get isSupportChat => true;

  bool get canBeClosed => status != SupportSessionStatus.closed;

  bool get isWaiting => status == SupportSessionStatus.waiting;

  bool get isActive => status == SupportSessionStatus.active;

  bool get isClosed => status == SupportSessionStatus.closed;

  SupportSession copyWith({
    String? id,
    SupportSessionStatus? status,
    ChatUser? customer,
    ChatUser? assignedTo,
    Chat? chat,
    Message? firstMessage,
    String? createdAt,
    String? updatedAt,
    String? closedAt,
  }) {
    return SupportSession(
      id: id ?? this.id,
      status: status ?? this.status,
      customer: customer ?? this.customer,
      assignedTo: assignedTo ?? this.assignedTo,
      chat: chat ?? this.chat,
      firstMessage: firstMessage ?? this.firstMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        customer,
        assignedTo,
        chat,
        firstMessage,
        createdAt,
        updatedAt,
        closedAt,
      ];

  @override
  bool get stringify => true;
}
