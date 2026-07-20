import 'package:equatable/equatable.dart';

/// Compact user representation returned inside block responses.
class BlockedUser extends Equatable {
  final String id;
  final String username;
  final String? image;

  const BlockedUser({
    required this.id,
    required this.username,
    this.image,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '') as String,
      image: json['image'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, username, image];
}
