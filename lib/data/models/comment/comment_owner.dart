import 'package:equatable/equatable.dart';

class CommentOwner extends Equatable {
  final String id;
  final String username;
  final String? image;
  final bool isPremium;
  final bool isVerified;
  final String? squareFlag;

  const CommentOwner({
    required this.id,
    required this.username,
    this.image,
    this.isPremium = false,
    this.isVerified = false,
    this.squareFlag,
  });

  factory CommentOwner.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v.toLowerCase() == 'true' || v == '1';
      return false;
    }

    final userStatus = json['user_status'] as Map<String, dynamic>?;
    final country = json['country'] as Map<String, dynamic>?;

    return CommentOwner(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      image: json['image']?.toString(),
      isPremium: userStatus != null ? parseBool(userStatus['is_premium']) : false,
      isVerified: parseBool(json['is_verified']),
      squareFlag: country?['square_flag']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'image': image,
        'user_status': {'is_premium': isPremium},
        'is_verified': isVerified,
        'country': {'square_flag': squareFlag},
      };

  String get firstLetter => username.isNotEmpty ? username[0].toUpperCase() : '?';

  bool get hasFlag => squareFlag != null && squareFlag!.isNotEmpty;

  @override
  List<Object?> get props => [id, username, image, isPremium, isVerified, squareFlag];
}
