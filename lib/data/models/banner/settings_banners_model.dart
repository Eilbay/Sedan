import 'package:equatable/equatable.dart';

class SettingsModel extends Equatable {
  final int count;
  final String? next;
  final String? previous;
  final List<MainBannerResult> results;

  const SettingsModel(
      {this.count = 0, this.next, this.previous, this.results = const []});

  SettingsModel copyWith(
      {int? count,
      String? next,
      String? preview,
      List<MainBannerResult>? results}) {
    return SettingsModel(
        count: count ?? this.count,
        next: next ?? this.next,
        previous: preview ?? previous,
        results: results ?? this.results);
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      count: json["count"] ?? 0,
      next: json["next"],
      previous: json["preview"],
      results: (json["results"] as List?)
              ?.map((item) => MainBannerResult.fromJson(item))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [count, next, previous, results];
}

class MainBannerResult extends Equatable {
  final int id;
  final String image;
  final String mobile;
  final String user;

  const MainBannerResult({
    this.id = 0,
    this.image = "",
    this.mobile = "",
    this.user = '',
  });

  MainBannerResult copyWith({
    int? id,
    String? image,
    String? mobile,
    String? user,
  }) {
    return MainBannerResult(
      id: id ?? this.id,
      image: image ?? this.image,
      mobile: mobile ?? this.mobile,
      user: user ?? this.user,
    );
  }

  factory MainBannerResult.fromJson(Map<String, dynamic> json) {
    return MainBannerResult(
      id: json["id"] ?? 0,
      image: json["image"] ?? "",
      mobile: json["mobile"] ?? "",
      user: json["user"] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {"id": id, "image": image, 'user': user};

  @override
  List<Object?> get props => [id, image, mobile, user];
}

/// Where a banner tap should lead.
enum BannerLinkType { user, external }

class BannerModel extends Equatable {
  final String id;
  final String? image;
  final String mobile;
  final String? desktop;
  final String user;
  final String? username;
  final String? createdAt;
  final BannerLinkType linkType;
  final String? externalUrl;

  /// Admin-controlled display position; lower comes first.
  final int order;

  const BannerModel({
    required this.id,
    required this.mobile,
    required this.user,
    this.image,
    this.desktop,
    this.username,
    this.createdAt,
    this.linkType = BannerLinkType.user,
    this.externalUrl,
    this.order = 0,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final externalUrl = (json['external_url'] ?? json['external_link']) as String?;
    return BannerModel(
      id: json['id'].toString(),
      image: json['image'] as String?,
      mobile: json['mobile'] ?? "",
      desktop: json['desktop'] as String?,
      user: json['user'] ?? "",
      username: json['username'] as String?,
      createdAt: json['created_at'] as String?,
      linkType: _parseLinkType(json['link_type'], externalUrl),
      externalUrl: externalUrl,
      order: _parseOrder(json),
    );
  }

  /// Backend may not send `link_type` yet (field is being rolled out) —
  /// fall back to inferring it from which link field is populated.
  static BannerLinkType _parseLinkType(dynamic raw, String? externalUrl) {
    if (raw == 'external') return BannerLinkType.external;
    if (raw == 'user') return BannerLinkType.user;
    if (externalUrl != null && externalUrl.isNotEmpty) {
      return BannerLinkType.external;
    }
    return BannerLinkType.user;
  }

  static int _parseOrder(Map<String, dynamic> json) {
    final raw = json['order'] ?? json['position'] ?? json['priority'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  BannerModel copyWith({
    String? id,
    String? image,
    String? mobile,
    String? desktop,
    String? user,
    String? username,
    String? createdAt,
    BannerLinkType? linkType,
    String? externalUrl,
    int? order,
  }) {
    return BannerModel(
      id: id ?? this.id,
      image: image ?? this.image,
      mobile: mobile ?? this.mobile,
      desktop: desktop ?? this.desktop,
      user: user ?? this.user,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      linkType: linkType ?? this.linkType,
      externalUrl: externalUrl ?? this.externalUrl,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [
        id,
        image,
        mobile,
        desktop,
        user,
        username,
        createdAt,
        linkType,
        externalUrl,
        order,
      ];
}
