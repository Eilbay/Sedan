import 'package:equatable/equatable.dart';

class UserBanner extends Equatable {
  final int id;
  final String banner;

  const UserBanner({
    required this.id,
    required this.banner,
  });

  factory UserBanner.fromJson(Map<String, dynamic> json) {
    return UserBanner(
      id: json['id'] ?? 0,
      banner: json['banner'] ?? "",
    );
  }

  UserBanner copyWith({
    int? id,
    String? banner,
  }) {
    return UserBanner(
      id: id ?? this.id,
      banner: banner ?? this.banner,
    );
  }

  @override
  List<Object?> get props => [id, banner];
}
