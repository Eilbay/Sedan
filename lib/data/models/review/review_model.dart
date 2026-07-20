import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final int count;
  final String? next;
  final String? previous;
  final List<ReviewResult> results;

  const ReviewModel({
    this.count = 0,
    this.next,
    this.previous,
    this.results = const [],
  });

  ReviewModel copyWith(
      {int? count,
      String? next,
      String? previous,
      List<ReviewResult>? results}) {
    return ReviewModel(
        count: count ?? this.count,
        next: next ?? this.next,
        previous: previous ?? this.previous,
        results: results ?? this.results);
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      count: json["count"] ?? 0,
      next: json["next"],
      previous: json["previous"],
      results: (json["results"] as List?)
              ?.map((item) => ReviewResult.fromJson(item))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [count, next, previous, results];
}

class ReviewResult extends Equatable {
  final int id;
  final ReviewUser? user;
  final String review;
  final int? stars;
  final String post;
  final int parent_review;
  final List<ReviewResult> children;
  final String created_at;

  const ReviewResult({
    this.id = 0,
    this.user,
    this.review = '',
    this.post = '',
    this.stars = 0,
    this.parent_review = 0,
    this.children = const [],
    this.created_at = '',
  });

  ReviewResult copyWith({
    int? id,
    ReviewUser? user,
    String? review,
    int? stars,
    String? post,
    int? parent_review,
    List<ReviewResult>? children,
    String? created_at,
  }) {
    return ReviewResult(
      id: id ?? this.id,
      user: user ?? this.user,
      review: review ?? this.review,
      post: post ?? this.post,
      stars: stars ?? this.stars,
      parent_review: parent_review ?? this.parent_review,
      children: children ?? this.children,
      created_at: created_at ?? this.created_at,
    );
  }

  factory ReviewResult.fromJson(Map<String, dynamic> json) {
    return ReviewResult(
      id: json['id'] ?? 0,
      user: json['user'] != null ? ReviewUser.fromJson(json['user']) : null,
      review: json['review'] ?? '',
      stars: json['stars'],
      post: json['post'] ?? '',
      parent_review: json['parent_review'] ?? 0,
      children: (json["children"] as List?)
              ?.map((item) => ReviewResult.fromJson(item))
              .toList() ??
          const [],
      created_at: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "review": review,
        "stars": stars,
        "post": post,
      };

  @override
  List<Object?> get props =>
      [id, user, review, stars, post, parent_review, children, created_at];
}

class ReviewUser extends Equatable {
  final String? id;
  final String username;
  final double? rating;
  final String? image;
  final String? user_type;

  const ReviewUser({
    this.id,
    this.username = '',
    this.rating,
    this.image,
    this.user_type,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['id']?.toString(),
      username: json['username'] ?? '',
      rating: json['rating'] != null
          ? (json['rating'] is num ? json['rating'].toDouble() : null)
          : null,
      image: json['image'] != null ? "${json['image']}" : null,
      user_type: json['user_type'],
    );
  }

  ReviewUser copyWith({
    String? id,
    String? username,
    double? rating,
    String? image,
    String? user_type,
  }) {
    return ReviewUser(
      id: id ?? this.id,
      username: username ?? this.username,
      rating: rating ?? this.rating,
      image: image ?? this.image,
      user_type: user_type ?? this.user_type,
    );
  }

  @override
  List<Object?> get props => [id, username, rating, image, user_type];
}
