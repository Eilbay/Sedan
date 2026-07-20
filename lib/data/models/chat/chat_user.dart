import 'package:equatable/equatable.dart';

class ChatUser extends Equatable {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? image;
  final String phoneNumber;

  const ChatUser({
    required this.id,
    required this.username,
    this.firstName = "",
    this.lastName = "",
    this.image,
    this.phoneNumber = "",
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? "",
      username: json['username'] ?? "",
      firstName: json['first_name'] ?? "",
      lastName: json['last_name'] ?? "",
      image: json['image'],
      phoneNumber: (json['phone_number'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
    'image': image,
    'phone_number': phoneNumber,
  };

  ChatUser copyWith({
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    String? image,
    String? phoneNumber,
  }) {
    return ChatUser(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      image: image ?? this.image,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  String get displayName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return username;
  }

  @override
  List<Object?> get props => [id, username, firstName, lastName, image, phoneNumber];
}
