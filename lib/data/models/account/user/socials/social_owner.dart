import 'package:optombai/data/models/account/user/socials/social_type.dart';
import 'package:equatable/equatable.dart';

class SocialOwner extends Equatable {
  final int id;
  final SocialType socialType;
  final String link;
  final String owner;

  const SocialOwner({
    required this.id,
    required this.socialType,
    required this.link,
    required this.owner,
  });

  factory SocialOwner.fromJson(Map<String, dynamic> json) {
    return SocialOwner(
      id: json['id'] ?? 0,
      socialType: SocialType.fromJson(json['social_type'] ?? {}),
      link: json['link'] ?? '',
      owner: json['owner'] ?? '',
    );
  }

  SocialOwner copyWith({
    int? id,
    SocialType? socialType,
    String? link,
    String? owner,
  }) {
    return SocialOwner(
      id: id ?? this.id,
      socialType: socialType ?? this.socialType,
      link: link ?? this.link,
      owner: owner ?? this.owner,
    );
  }

  Map<String, dynamic> toJson() =>
      {"social_type": socialType.id, "link": link, "owner": owner};

  @override
  List<Object?> get props => [id, socialType, link, owner];
}
