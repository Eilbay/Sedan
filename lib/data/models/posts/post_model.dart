import 'package:optombai/core/import_links.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _asDouble(dynamic v, {double fallback = 0}) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
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

class PostModel extends Equatable {
  final int count;
  final String? next;
  final String? previous;
  final List<Product> results;

  const PostModel({
    this.count = 0,
    this.next,
    this.previous,
    this.results = const [],
  });

  PostModel copyWith({
    int? count,
    String? next,
    String? previous,
    List<Product>? results,
  }) {
    return PostModel(
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final list = (rawResults is List)
        ? rawResults
            .whereType<Map<String, dynamic>>()
            .map(Product.fromJson)
            .toList()
        : const <Product>[];

    return PostModel(
      count: _asInt(json['count'], fallback: 0),
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: list,
    );
  }

  @override
  List<Object?> get props => [count, next, previous, results];
}

// ignore: must_be_immutable
class Product with EquatableMixin {
  String id;
  List<PostImage> image_post;
  User? owner;
  String name;
  Category? categories;
  String? category;
  String description;
  double? price;
  int reviewCount;
  double rating;
  String? postType;
  int? providerRrManufacturer;
  int? mainPostType;
  int? productNumber;
  String aroundReview;
  DateTime createdAt;
  int views;
  bool isPromoted;
  DateTime? promoEndAt;
  String? promoCampaignId;
  // Server-computed cover for the whole post; set even when the first
  // media is still being processed. Used as a last-resort fallback.
  String? coverImage;
  // Absolute filesystem path to a locally-generated thumbnail. Populated
  // only for optimistically-inserted products during upload, so the feed
  // can render a card before the server has computed a cover. Not
  // serialized to/from JSON.
  final String? localPreviewPath;
  int? regionId;
  String currency;

  Product.clone(Product products)
      : this(
          rating: products.rating,
          owner: products.owner,
          id: products.id,
          name: products.name,
          description: products.description,
          postType: products.postType,
          productNumber: products.productNumber,
          category: products.category,
          price: products.price,
          categories: products.categories,
          mainPostType: products.mainPostType,
          image_post: products.image_post,
          createdAt: products.createdAt,
          views: products.views,
          aroundReview: products.aroundReview,
          reviewCount: products.reviewCount,
          providerRrManufacturer: products.providerRrManufacturer,
          isPromoted: products.isPromoted,
          promoEndAt: products.promoEndAt,
          promoCampaignId: products.promoCampaignId,
          coverImage: products.coverImage,
          localPreviewPath: products.localPreviewPath,
          regionId: products.regionId,
          currency: products.currency,
        );

  Product({
    this.owner,
    this.name = "",
    this.description = "",
    this.productNumber = 0,
    this.id = '',
    this.price = 0,
    this.category = "",
    this.postType = "",
    this.mainPostType = 1,
    this.rating = 0,
    this.providerRrManufacturer = 1,
    this.image_post = const [],
    this.reviewCount = 0,
    this.aroundReview = "",
    this.views = 0,
    DateTime? createdAt,
    this.categories,
    this.isPromoted = false,
    this.promoEndAt,
    this.promoCampaignId,
    this.coverImage,
    this.localPreviewPath,
    this.regionId,
    this.currency = 'KGS',
  }) : createdAt = createdAt ?? DateTime.now();

  Product.fromJson(Map<String, dynamic> json)
      : id = (json["id"] ?? '').toString(),
        owner = User.fromJson(json["owner"] ?? {}),
        name = (json["name"] ?? '').toString(),
        description = (json["description"] ?? '').toString(),
        reviewCount = _asInt(json["review_count"]),
        price = json['price'] != null
            ? double.tryParse(json['price'].toString())
            : null,
        rating = _asDouble(json["rating"]),
        postType = (json["product_type"] is String)
            ? json["product_type"]
            : (json["product_type"] is Map
                ? (json["product_type"]["id"]?.toString() ?? "0")
                : "0"),
        productNumber = _asInt(json["product_number"]),
        category = json["category"] is String
            ? json["category"]
            : (json["category"] is Map<String, dynamic>
                ? Category.fromJson(json["category"]).id
                : null),
        categories = json['category'] is Map<String, dynamic>
            ? Category.fromJson(json['category'])
            : null,
        mainPostType = _asInt(json["main_post_type"], fallback: 0),
        views = _asInt(json["views"]),
        providerRrManufacturer =
            _asInt(json["provider_or_manufacturer"], fallback: 0),
        image_post = ((json["images_post"] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => PostImage.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        createdAt = _parseDateFlexible(json['created_at']),
        aroundReview = (json["around_review"] ?? '').toString(),
        isPromoted = json["is_promoted"] ?? false,
        promoEndAt = json["promo_end_at"] != null
            ? _parseDateFlexible(json["promo_end_at"])
            : null,
        // Backend sends promo_campaign_id as an int; `as String?` would throw.
        promoCampaignId = json["promo_campaign_id"]?.toString(),
        coverImage = json["cover_image"] as String?,
        localPreviewPath = null,
        regionId = json["region"] is Map
            ? _asInt(json["region"]["id"])
            : _asInt(json["region"]),
        currency = (json["currency"] as String?) ?? 'KGS';

  Product copyWith({
    String? id,
    List<PostImage>? image_post,
    User? owner,
    String? name,
    Category? categories,
    String? category,
    String? description,
    double? price,
    int? reviewCount,
    double? rating,
    String? postType,
    int? providerRrManufacturer,
    int? mainPostType,
    int? productNumber,
    String? aroundReview,
    DateTime? createdAt,
    int? views,
    bool? isPromoted,
    DateTime? promoEndAt,
    String? promoCampaignId,
    String? coverImage,
    String? localPreviewPath,
    int? regionId,
    String? currency,
  }) {
    return Product(
      id: id ?? this.id,
      image_post: image_post ?? this.image_post,
      owner: owner ?? this.owner,
      name: name ?? this.name,
      categories: categories ?? this.categories,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      reviewCount: reviewCount ?? this.reviewCount,
      rating: rating ?? this.rating,
      postType: postType ?? this.postType,
      providerRrManufacturer: providerRrManufacturer ?? this.providerRrManufacturer,
      mainPostType: mainPostType ?? this.mainPostType,
      productNumber: productNumber ?? this.productNumber,
      aroundReview: aroundReview ?? this.aroundReview,
      createdAt: createdAt ?? this.createdAt,
      views: views ?? this.views,
      isPromoted: isPromoted ?? this.isPromoted,
      promoEndAt: promoEndAt ?? this.promoEndAt,
      promoCampaignId: promoCampaignId ?? this.promoCampaignId,
      coverImage: coverImage ?? this.coverImage,
      localPreviewPath: localPreviewPath ?? this.localPreviewPath,
      regionId: regionId ?? this.regionId,
      currency: currency ?? this.currency,
    );
  }

  /// Number of reviews to display in feed/profile cards.
  ///
  /// Workaround for a backend bug: the LIST serializer
  /// (`GET /api/v1/posts/?...`) returns `review_count=0` for posts that
  /// actually have reviews — only the DETAIL serializer
  /// (`GET /api/v1/posts/{id}/`) computes the count correctly. So when
  /// `rating > 0` (which can't happen without at least one review) we
  /// clamp the displayed count to at least 1 instead of showing the
  /// nonsensical "5 ★ · 0 отзывов". Single source of truth — every
  /// product card should use this getter, not `reviewCount` directly.
  int get displayReviewCount {
    if (reviewCount > 0) return reviewCount;
    if (rating > 0) return 1;
    return 0;
  }

  /// Best image URL to show in a feed/list card, regardless of media layout.
  /// Priority:
  ///   1) first image's still-image URL (photo, or ready video cover)
  ///   2) any sibling image/cover in image_post (e.g. a photo that sits after a video)
  ///   3) server-computed cover_image for the whole post
  /// Returns null if no still image is available anywhere.
  String? get previewUrl {
    if (image_post.isNotEmpty) {
      final first = image_post.first.displayUrlOrNull;
      if (first != null) return first;
      for (final img in image_post) {
        final url = img.displayUrlOrNull;
        if (url != null) return url;
      }
    }
    return coverImage;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (owner != null) map['owner'] = owner!.id;
    map['product_type'] = postType;
    map['name'] = name;
    map['price'] = price;
    map['currency'] = currency;
    map['category'] = category;
    map['categories'] = categories;
    map['description'] = description;
    map['created_at'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt);
    if (regionId != null) map['region'] = regionId;
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        image_post,
        owner,
        name,
        categories,
        category,
        description,
        price,
        reviewCount,
        rating,
        postType,
        providerRrManufacturer,
        mainPostType,
        productNumber,
        aroundReview,
        createdAt,
        views,
        isPromoted,
        promoEndAt,
        promoCampaignId,
        coverImage,
        localPreviewPath,
        regionId,
        currency,
      ];
}

class PostImage extends Equatable {
  final int id;
  final String post;
  final String image;
  final String? cover;
  final String? videoPreviewUrl;
  final String? coverMediumUrl;
  final bool isProcessed;
  // Server-provided flag. When null, fall back to extension heuristics.
  final bool? serverIsVideo;
  // Video length in seconds, provided by the server for video media only.
  final double? duration;

  const PostImage({
    this.id = 0,
    this.post = '',
    required this.image,
    this.cover,
    this.videoPreviewUrl,
    this.coverMediumUrl,
    this.isProcessed = true,
    this.serverIsVideo,
    this.duration,
  });

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: _asInt(json['id'], fallback: 0),
      post: (json['post'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      cover: json['cover'] as String?,
      videoPreviewUrl: json['video_preview'] as String?,
      coverMediumUrl: json['cover_medium'] as String?,
      isProcessed: json['is_processed'] ?? true,
      serverIsVideo: json['is_video'] as bool?,
      duration: (json['duration'] as num?)?.toDouble(),
    );
  }

  PostImage copyWith({
    int? id,
    String? post,
    String? image,
    String? cover,
    String? videoPreviewUrl,
    String? coverMediumUrl,
    bool? isProcessed,
    bool? serverIsVideo,
    double? duration,
  }) {
    return PostImage(
      id: id ?? this.id,
      post: post ?? this.post,
      image: image ?? this.image,
      cover: cover ?? this.cover,
      videoPreviewUrl: videoPreviewUrl ?? this.videoPreviewUrl,
      coverMediumUrl: coverMediumUrl ?? this.coverMediumUrl,
      isProcessed: isProcessed ?? this.isProcessed,
      serverIsVideo: serverIsVideo ?? this.serverIsVideo,
      duration: duration ?? this.duration,
    );
  }

  // Extensions that are known to be images (CachedNetworkImage can display them).
  static const _imageExts = {
    'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic', 'heif',
  };

  bool get isVideo {
    if (serverIsVideo != null) return serverIsVideo!;
    final ext = image.split('.').last.toLowerCase();
    if (_imageExts.contains(ext)) return false;
    return ['mp4', 'mov', 'webm', 'avi', 'mkv', '3gp', 'm4v'].contains(ext);
  }

  /// Best available cover image for this post media.
  /// Prefers cover_medium (webp), then cover, then null.
  String? get bestCoverUrl => coverMediumUrl ?? cover;

  /// Nullable still-image URL. `null` means the server has no cover yet
  /// (e.g. video that just finished uploading). UI should show a
  /// placeholder instead of passing this to CachedNetworkImage.
  String? get displayUrlOrNull {
    if (isVideo) return bestCoverUrl;
    return image.isEmpty ? null : image;
  }

  /// Legacy non-null URL. For videos without a ready cover, returns the
  /// raw media URL (which CachedNetworkImage will fail to decode — callers
  /// should prefer `displayUrlOrNull`).
  String get displayUrl =>
      (isVideo && bestCoverUrl != null) ? bestCoverUrl! : image;

  /// Video length as "m:ss", e.g. "0:14". Empty when [duration] is unknown.
  String get formattedDuration {
    if (duration == null) return '';
    final totalSeconds = duration!.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        post,
        image,
        cover,
        videoPreviewUrl,
        coverMediumUrl,
        isProcessed,
        serverIsVideo,
        duration,
      ];
}
