import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

final List<DateFormat> _dateFormats = [
  DateFormat('dd-MM-yyyy HH:mm:ss'),
  DateFormat('yyyy-MM-dd HH:mm:ss'),
  DateFormat('yyyy-MM-ddTHH:mm:ss'),
  DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'"),
  DateFormat('yyyy-MM-dd'),
];

DateTime _parseDateFlexible(dynamic v) {
  if (v is String && v.isNotEmpty) {
    for (final fmt in _dateFormats) {
      try {
        return fmt.parse(v, true).toLocal();
      } catch (_) {}
    }
  }
  return DateTime.now();
}

class ReelListModel extends Equatable {
  final String? next;
  final String? previous;

  /// Offset for the next page (mirrors the offset embedded in [next]). The
  /// reels-feed is cyclic, so [next] is effectively always present.
  final int? nextOffset;

  /// Total reels available for this feed/filter (informational).
  final int? count;
  final List<ReelModel> results;

  const ReelListModel({
    this.next,
    this.previous,
    this.nextOffset,
    this.count,
    this.results = const [],
  });

  factory ReelListModel.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final list = (rawResults is List)
        ? rawResults
            .whereType<Map<String, dynamic>>()
            .map(ReelModel.fromJson)
            .toList()
        : const <ReelModel>[];

    return ReelListModel(
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      nextOffset: (json['next_offset'] as num?)?.toInt(),
      count: (json['count'] as num?)?.toInt(),
      results: list,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'next': next,
      'previous': previous,
      'next_offset': nextOffset,
      'count': count,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [next, previous, nextOffset, count, results];
}

class ReelModel extends Equatable {
  final String id;
  final String slug;
  final DateTime createdAt;
  final String description;
  final int views;
  final String videoUrl;
  final ReelOwner owner;
  final int likes;
  final bool isLiked;
  final String? coverUrl;
  final String? videoPreviewUrl;
  final String? coverMediumUrl;
  final int? videoDuration;
  final bool isProcessed;
  final bool isPromoted;
  final DateTime? promoEndAt;
  final String? promoCampaignId;
  final String? hlsMasterUrl;
  final bool hlsReady;
  final List<HlsRendition> hlsRenditions;

  /// `"organic"` (normal reel) or `"promo"` (paid ad slot). From reels-feed.
  final String cardType;

  /// Server-assigned slot index in the feed (ads land on fixed positions).
  final int? position;

  /// True for the first reels of a fresh feed — backend serves a light 360p
  /// HLS variant so the feed starts instantly. Player logic is unchanged
  /// (the light manifest is already pointed to by [hlsMasterUrl]).
  final bool lowQuality;

  /// Highest rendition height available for this reel (informational).
  final int? maxQualityHeight;

  const ReelModel({
    required this.id,
    required this.slug,
    required this.createdAt,
    required this.description,
    required this.views,
    required this.videoUrl,
    required this.owner,
    required this.likes,
    required this.isLiked,
    this.coverUrl,
    this.videoPreviewUrl,
    this.coverMediumUrl,
    this.videoDuration,
    this.isProcessed = true,
    this.isPromoted = false,
    this.promoEndAt,
    this.promoCampaignId,
    this.hlsMasterUrl,
    this.hlsReady = false,
    this.hlsRenditions = const [],
    this.cardType = 'organic',
    this.position,
    this.lowQuality = false,
    this.maxQualityHeight,
  });

  /// True when the reel has a usable HLS manifest. Use [playbackUrl] to get
  /// the actual URL to feed into the player (with MP4 fallback).
  bool get hasHls => hlsReady && (hlsMasterUrl?.isNotEmpty ?? false);

  /// Resolved video URL for playback: HLS manifest when ready, MP4 otherwise.
  String get playbackUrl => hasHls ? hlsMasterUrl!.trim() : videoUrl.trim();

  /// True when this slot is a paid promotion: either the feed marked it as a
  /// `promo` card, or it carries an active legacy promotion flag. Drives the
  /// "Реклама" overlay and impression tracking.
  bool get isPromoCard =>
      cardType == 'promo' ||
      (isPromoted && (promoEndAt?.isAfter(DateTime.now()) ?? false));

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    final renditionsRaw = json['hls_renditions'];
    final renditions = (renditionsRaw is List)
        ? renditionsRaw
            .whereType<Map<String, dynamic>>()
            .map(HlsRendition.fromJson)
            .toList()
        : const <HlsRendition>[];

    return ReelModel(
      id: (json['id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      createdAt: _parseDateFlexible(json['created_at']),
      description: (json['description'] ?? '').toString(),
      views: _asInt(json['views']),
      videoUrl: (json['video_url'] ?? '').toString(),
      owner: ReelOwner.fromJson(json['owner'] ?? {}),
      likes: _asInt(json['likes']),
      isLiked: json['is_liked'] == true,
      coverUrl: json['cover_url'] as String?,
      videoPreviewUrl: json['video_preview'] as String?,
      coverMediumUrl: json['cover_medium'] as String?,
      videoDuration: (json['duration'] as num?)?.round(),
      isProcessed: json['is_processed'] ?? true,
      isPromoted: json['is_promoted'] ?? false,
      promoEndAt: json['promo_end_at'] != null
          ? _parseDateFlexible(json['promo_end_at'])
          : null,
      // Backend sends promo_campaign_id as an int (e.g. 2); `as String?` threw
      // a TypeError that aborted reel parsing → endless loading spinner.
      promoCampaignId: json['promo_campaign_id']?.toString(),
      hlsMasterUrl: json['hls_master_url'] as String?,
      hlsReady: json['hls_ready'] == true,
      hlsRenditions: renditions,
      cardType: (json['card_type'] ?? 'organic').toString(),
      position: (json['position'] as num?)?.toInt(),
      lowQuality: json['low_quality'] == true,
      maxQualityHeight: (json['max_quality_height'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'created_at': DateFormat('dd-MM-yyyy HH:mm:ss').format(createdAt),
      'description': description,
      'views': views,
      'video_url': videoUrl,
      'owner': owner.toJson(),
      'likes': likes,
      'is_liked': isLiked,
      'cover_url': coverUrl,
      'video_preview': videoPreviewUrl,
      'cover_medium': coverMediumUrl,
      'duration': videoDuration,
      'is_processed': isProcessed,
      'is_promoted': isPromoted,
      'promo_end_at': promoEndAt != null
          ? DateFormat('dd-MM-yyyy HH:mm:ss').format(promoEndAt!)
          : null,
      'promo_campaign_id': promoCampaignId,
      'hls_master_url': hlsMasterUrl,
      'hls_ready': hlsReady,
      'hls_renditions': hlsRenditions.map((r) => r.toJson()).toList(),
      'card_type': cardType,
      'position': position,
      'low_quality': lowQuality,
      'max_quality_height': maxQualityHeight,
    };
  }

  ReelModel copyWith({
    String? id,
    String? slug,
    DateTime? createdAt,
    String? description,
    int? views,
    String? videoUrl,
    ReelOwner? owner,
    int? likes,
    bool? isLiked,
    String? coverUrl,
    String? videoPreviewUrl,
    String? coverMediumUrl,
    int? videoDuration,
    bool? isProcessed,
    bool? isPromoted,
    DateTime? promoEndAt,
    String? promoCampaignId,
    String? hlsMasterUrl,
    bool? hlsReady,
    List<HlsRendition>? hlsRenditions,
    String? cardType,
    int? position,
    bool? lowQuality,
    int? maxQualityHeight,
  }) {
    return ReelModel(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      views: views ?? this.views,
      videoUrl: videoUrl ?? this.videoUrl,
      owner: owner ?? this.owner,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      coverUrl: coverUrl ?? this.coverUrl,
      videoPreviewUrl: videoPreviewUrl ?? this.videoPreviewUrl,
      coverMediumUrl: coverMediumUrl ?? this.coverMediumUrl,
      videoDuration: videoDuration ?? this.videoDuration,
      isProcessed: isProcessed ?? this.isProcessed,
      isPromoted: isPromoted ?? this.isPromoted,
      promoEndAt: promoEndAt ?? this.promoEndAt,
      promoCampaignId: promoCampaignId ?? this.promoCampaignId,
      hlsMasterUrl: hlsMasterUrl ?? this.hlsMasterUrl,
      hlsReady: hlsReady ?? this.hlsReady,
      hlsRenditions: hlsRenditions ?? this.hlsRenditions,
      cardType: cardType ?? this.cardType,
      position: position ?? this.position,
      lowQuality: lowQuality ?? this.lowQuality,
      maxQualityHeight: maxQualityHeight ?? this.maxQualityHeight,
    );
  }

  @override
  List<Object?> get props => [
        id,
        slug,
        createdAt,
        description,
        views,
        videoUrl,
        owner,
        likes,
        isLiked,
        coverUrl,
        videoPreviewUrl,
        coverMediumUrl,
        videoDuration,
        isProcessed,
        isPromoted,
        promoEndAt,
        promoCampaignId,
        hlsMasterUrl,
        hlsReady,
        hlsRenditions,
        cardType,
        position,
        lowQuality,
        maxQualityHeight,
      ];
}

/// HLS rendition descriptor for adaptive bitrate. mpv picks the active
/// rendition automatically from the master playlist; this class exists so
/// the app can display available qualities or implement manual selection.
class HlsRendition extends Equatable {
  final String name;
  final int? height;
  final int? bandwidth;

  const HlsRendition({
    required this.name,
    this.height,
    this.bandwidth,
  });

  factory HlsRendition.fromJson(Map<String, dynamic> json) {
    return HlsRendition(
      name: (json['name'] ?? '').toString(),
      height: (json['height'] as num?)?.toInt(),
      bandwidth: (json['bandwidth'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'height': height,
        'bandwidth': bandwidth,
      };

  @override
  List<Object?> get props => [name, height, bandwidth];
}

class ReelOwner extends Equatable {
  final String id;
  final String username;
  final String? image;
  final bool accountVerified;
  final bool isVerified;
  final ReelUserStatus userStatus;
  final ReelCountry? country;
  final List<ReelSupplier> suppliers;
  final int? regionId;

  const ReelOwner({
    required this.id,
    required this.username,
    this.image,
    required this.accountVerified,
    this.isVerified = false,
    required this.userStatus,
    this.country,
    this.suppliers = const [],
    this.regionId,
  });

  factory ReelOwner.fromJson(Map<String, dynamic> json) {
    final suppliersList = (json['suppliers'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map(ReelSupplier.fromJson)
        .toList() ?? const [];

    return ReelOwner(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      image: json['image'] as String?,
      accountVerified: json['account_verified'] == true,
      isVerified: json['is_verified'] == true,
      userStatus: ReelUserStatus.fromJson(json['user_status'] ?? {}),
      country: json['country'] != null
          ? ReelCountry.fromJson(json['country'] as Map<String, dynamic>)
          : null,
      suppliers: suppliersList,
      regionId: json['region'] is int
          ? json['region'] as int
          : int.tryParse(json['region']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'image': image,
      'account_verified': accountVerified,
      'is_verified': isVerified,
      'user_status': userStatus.toJson(),
      'country': country?.toJson(),
      'suppliers': suppliers.map((s) => s.toJson()).toList(),
      if (regionId != null) 'region': regionId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        username,
        image,
        accountVerified,
        isVerified,
        userStatus,
        country,
        suppliers,
        regionId,
      ];
}

class ReelUserStatus extends Equatable {
  final bool isPremium;

  const ReelUserStatus({required this.isPremium});

  factory ReelUserStatus.fromJson(Map<String, dynamic> json) {
    return ReelUserStatus(
      isPremium: json['is_premium'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_premium': isPremium,
    };
  }

  @override
  List<Object?> get props => [isPremium];
}

class ReelCountry extends Equatable {
  final int id;
  final String title;
  final String iso2;
  final String? flag;
  final String? circleFlag;
  final String? squareFlag;

  const ReelCountry({
    required this.id,
    required this.title,
    required this.iso2,
    this.flag,
    this.circleFlag,
    this.squareFlag,
  });

  factory ReelCountry.fromJson(Map<String, dynamic> json) {
    return ReelCountry(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      iso2: (json['iso2'] ?? '').toString(),
      flag: json['flag'] as String?,
      circleFlag: json['circle_flag'] as String?,
      squareFlag: json['square_flag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'iso2': iso2,
      'flag': flag,
      'circle_flag': circleFlag,
      'square_flag': squareFlag,
    };
  }

  @override
  List<Object?> get props => [id, title, iso2, flag, circleFlag, squareFlag];
}

class ReelSupplier extends Equatable {
  final int id;
  final ReelMarket market;
  final bool isActive;
  final DateTime createdAt;

  const ReelSupplier({
    required this.id,
    required this.market,
    required this.isActive,
    required this.createdAt,
  });

  factory ReelSupplier.fromJson(Map<String, dynamic> json) {
    return ReelSupplier(
      id: _asInt(json['id']),
      market: ReelMarket.fromJson(json['market'] ?? {}),
      isActive: json['is_active'] == true,
      createdAt: _parseDateFlexible(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'market': market.toJson(),
      'is_active': isActive,
      'created_at': DateFormat('dd-MM-yyyy HH:mm:ss').format(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, market, isActive, createdAt];
}

class ReelMarket extends Equatable {
  final int id;
  final String name;

  const ReelMarket({
    required this.id,
    required this.name,
  });

  factory ReelMarket.fromJson(Map<String, dynamic> json) {
    return ReelMarket(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, name];
}
