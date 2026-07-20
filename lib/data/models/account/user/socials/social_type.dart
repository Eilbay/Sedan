import 'package:equatable/equatable.dart';

class SocialType extends Equatable {
  final int id;
  final String logo;
  final String domainUrl;
  final String title;

  const SocialType({
    required this.id,
    required this.domainUrl,
    required this.logo,
    required this.title,
  });

  factory SocialType.fromJson(Map<String, dynamic> json) {
    return SocialType(
      id: json['id'] as int,
      domainUrl: json['domain_url'] as String,
      logo: json['logo'] as String,
      title: json['title'] as String,
    );
  }

  SocialType copyWith({
    int? id,
    String? logo,
    String? domainUrl,
    String? title,
  }) {
    return SocialType(
      id: id ?? this.id,
      logo: logo ?? this.logo,
      domainUrl: domainUrl ?? this.domainUrl,
      title: title ?? this.title,
    );
  }

  @override
  List<Object?> get props => [id, logo, domainUrl, title];
}
